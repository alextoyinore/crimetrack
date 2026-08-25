import os
import hmac
import sqlite3
import uuid
from datetime import datetime, timezone
from pathlib import Path

from dotenv import load_dotenv
from flask import Flask, jsonify, redirect, render_template, request, send_from_directory, session, url_for
from werkzeug.utils import secure_filename


BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / ".env")
DATABASE_PATH = Path(os.environ.get("CRIMETRACK_DATABASE", BASE_DIR / "crimetrack.db"))
ALLOWED_TYPES = {"Theft", "Robbery", "Kidnapping", "Suspicious activity", "Other"}
ALLOWED_RISKS = {"high", "medium", "low"}
ALLOWED_STATUSES = {"pending", "verified", "resolved", "rejected", "flagged"}


def create_app(database_path=DATABASE_PATH, admin_token=None):
    app = Flask(__name__)
    app.config["DATABASE_PATH"] = str(database_path)
    app.config["EVIDENCE_DIRECTORY"] = str(
        Path(database_path).parent / "evidence"
    )
    app.config["ADMIN_TOKEN"] = (
        admin_token if admin_token is not None else os.environ.get("CRIMETRACK_ADMIN_TOKEN")
    )
    app.config["ADMIN_USERNAME"] = os.environ.get("CRIMETRACK_ADMIN_USERNAME")
    app.config["ADMIN_PASSWORD"] = os.environ.get("CRIMETRACK_ADMIN_PASSWORD")
    app.config["SECRET_KEY"] = os.environ.get(
        "CRIMETRACK_SESSION_SECRET", "dev-only-change-this-secret"
    )
    app.config["SESSION_COOKIE_HTTPONLY"] = True
    app.config["SESSION_COOKIE_SAMESITE"] = "Lax"

    with app.app_context():
        _init_database(app.config["DATABASE_PATH"])

    @app.get("/health")
    def health():
        return jsonify({"status": "ok"})

    @app.get("/media/<path:filename>")
    def media(filename):
        return send_from_directory(app.config["EVIDENCE_DIRECTORY"], filename)

    @app.get("/api/incidents")
    def list_incidents():
        connection = _connect(app.config["DATABASE_PATH"])
        device_id = request.args.get("deviceId")
        if device_id:
            rows = connection.execute(
                "SELECT * FROM incidents WHERE reporter_device_id = ? ORDER BY reported_at DESC",
                (device_id,),
            ).fetchall()
        else:
            rows = connection.execute(
                "SELECT * FROM incidents ORDER BY reported_at DESC"
            ).fetchall()
        connection.close()
        return jsonify([dict(row) for row in rows])

    @app.get("/api/notifications")
    def list_notifications():
        device_id = request.args.get("deviceId")
        if not _text(device_id):
            return jsonify({"error": "deviceId is required"}), 400
        connection = _connect(app.config["DATABASE_PATH"])
        rows = connection.execute(
            """
            SELECT id, title, message, incident_id, created_at, read
            FROM notifications
            WHERE device_id = ?
            ORDER BY created_at DESC
            LIMIT 50
            """,
            (device_id,),
        ).fetchall()
        connection.close()
        return jsonify([dict(row) for row in rows])

    @app.post("/api/notifications/read")
    def mark_notifications_read():
        payload = request.get_json(silent=True)
        if not isinstance(payload, dict) or not _text(payload.get("deviceId")):
            return jsonify({"error": "deviceId is required"}), 400
        connection = _connect(app.config["DATABASE_PATH"])
        connection.execute(
            "UPDATE notifications SET read = 1 WHERE device_id = ?",
            (payload["deviceId"].strip(),),
        )
        connection.commit()
        connection.close()
        return jsonify({"status": "ok"})

    @app.post("/api/admin/login")
    def admin_login():
        payload = request.get_json(silent=True)
        if not isinstance(payload, dict):
            return jsonify({"error": "Request body must be a JSON object"}), 400
        if not all(
            (
                app.config["ADMIN_TOKEN"],
                app.config["ADMIN_USERNAME"],
                app.config["ADMIN_PASSWORD"],
            )
        ):
            return jsonify({"error": "Admin login is not configured"}), 503
        username = payload.get("username")
        password = payload.get("password")
        if not isinstance(username, str) or not isinstance(password, str):
            return jsonify({"error": "Username and password are required"}), 400
        if not hmac.compare_digest(username, app.config["ADMIN_USERNAME"]):
            return jsonify({"error": "Invalid admin credentials"}), 401
        if not hmac.compare_digest(password, app.config["ADMIN_PASSWORD"]):
            return jsonify({"error": "Invalid admin credentials"}), 401
        return jsonify({"token": app.config["ADMIN_TOKEN"]})

    @app.get("/admin/login")
    def admin_login_page():
        if session.get("admin_authenticated"):
            return redirect(url_for("admin_dashboard"))
        return render_template("admin_login.html", error=None)

    @app.post("/admin/login")
    def admin_login_submit():
        username = request.form.get("username", "")
        password = request.form.get("password", "")
        configured = all(
            (
                app.config["ADMIN_TOKEN"],
                app.config["ADMIN_USERNAME"],
                app.config["ADMIN_PASSWORD"],
            )
        )
        valid = configured and hmac.compare_digest(
            username, app.config["ADMIN_USERNAME"]
        ) and hmac.compare_digest(password, app.config["ADMIN_PASSWORD"])
        if not valid:
            error = "Admin access is not configured" if not configured else "Invalid credentials"
            return render_template("admin_login.html", error=error), 503 if not configured else 401
        session.clear()
        session["admin_authenticated"] = True
        return redirect(url_for("admin_dashboard"))

    @app.post("/admin/logout")
    def admin_logout():
        session.clear()
        return redirect(url_for("admin_login_page"))

    @app.get("/admin")
    def admin_dashboard():
        if not session.get("admin_authenticated"):
            return redirect(url_for("admin_login_page"))
        status_filter = request.args.get("status", "all")
        risk_filter = request.args.get("risk", "all")
        connection = _connect(app.config["DATABASE_PATH"])
        rows = connection.execute(
            "SELECT * FROM incidents ORDER BY reported_at DESC"
        ).fetchall()
        connection.close()
        incidents = [dict(row) for row in rows]
        filtered = [
            incident
            for incident in incidents
            if (status_filter == "all" or incident["status"] == status_filter)
            and (risk_filter == "all" or incident["risk"] == risk_filter)
        ]
        return render_template(
            "admin_dashboard.html",
            incidents=filtered,
            total=len(incidents),
            pending=sum(i["status"] == "pending" for i in incidents),
            verified=sum(i["status"] == "verified" for i in incidents),
            high_risk=sum(i["risk"] == "high" for i in incidents),
            status_filter=status_filter,
            risk_filter=risk_filter,
            statuses=sorted(ALLOWED_STATUSES),
            risks=sorted(ALLOWED_RISKS),
        )

    @app.get("/admin/analytics")
    def admin_analytics():
        if not session.get("admin_authenticated"):
            return redirect(url_for("admin_login_page"))
        connection = _connect(app.config["DATABASE_PATH"])
        status_rows = connection.execute(
            "SELECT status AS label, COUNT(*) AS total FROM incidents GROUP BY status ORDER BY total DESC"
        ).fetchall()
        risk_rows = connection.execute(
            "SELECT risk AS label, COUNT(*) AS total FROM incidents GROUP BY risk ORDER BY total DESC"
        ).fetchall()
        type_rows = connection.execute(
            "SELECT type AS label, COUNT(*) AS total FROM incidents GROUP BY type ORDER BY total DESC"
        ).fetchall()
        trend_rows = connection.execute(
            """
            SELECT substr(reported_at, 1, 10) AS label, COUNT(*) AS total
            FROM incidents
            WHERE reported_at >= date('now', '-13 days')
            GROUP BY label ORDER BY label
            """
        ).fetchall()
        connection.close()
        return render_template(
            "admin_analytics.html",
            status_breakdown=[dict(row) for row in status_rows],
            risk_breakdown=[dict(row) for row in risk_rows],
            type_breakdown=[dict(row) for row in type_rows],
            daily_trend=[dict(row) for row in trend_rows],
        )

    @app.get("/admin/incidents/<int:incident_id>")
    def admin_incident_detail(incident_id):
        if not session.get("admin_authenticated"):
            return redirect(url_for("admin_login_page"))
        connection = _connect(app.config["DATABASE_PATH"])
        incident = connection.execute(
            "SELECT * FROM incidents WHERE id = ?", (incident_id,)
        ).fetchone()
        connection.close()
        if incident is None:
            return "Incident not found", 404
        return render_template("admin_incident_detail.html", incident=dict(incident))

    @app.post("/admin/incidents/<int:incident_id>/moderate")
    def admin_moderate_form(incident_id):
        if not session.get("admin_authenticated"):
            return redirect(url_for("admin_login_page"))
        status = request.form.get("status", "pending")
        risk = request.form.get("risk", "medium")
        if status not in ALLOWED_STATUSES or risk not in ALLOWED_RISKS:
            return redirect(url_for("admin_dashboard"))
        connection = _connect(app.config["DATABASE_PATH"])
        previous = connection.execute(
            "SELECT status, reporter_device_id FROM incidents WHERE id = ?",
            (incident_id,),
        ).fetchone()
        connection.execute(
            "UPDATE incidents SET status = ?, risk = ? WHERE id = ?",
            (status, risk, incident_id),
        )
        if previous and previous["status"] != status:
            _create_notification(
                connection,
                previous["reporter_device_id"],
                "Report status updated",
                f"Your report is now {status}.",
                incident_id,
            )
        connection.commit()
        connection.close()
        return redirect(url_for("admin_dashboard"))

    @app.post("/api/incidents")
    def create_incident():
        multipart = bool(request.files)
        payload = request.form.to_dict() if multipart else request.get_json(silent=True)
        if not isinstance(payload, dict):
            return jsonify({"error": "Request body must be a JSON object"}), 400

        required = ("type", "description", "location")
        missing = [field for field in required if not _text(payload.get(field))]
        if missing:
            return jsonify({"error": f"Missing required fields: {', '.join(missing)}"}), 400

        incident_type = payload["type"].strip()
        if incident_type not in ALLOWED_TYPES:
            return jsonify({"error": "Unsupported incident type"}), 400

        latitude = _coordinate(payload.get("latitude"), -90, 90)
        longitude = _coordinate(payload.get("longitude"), -180, 180)
        if payload.get("latitude") is not None and latitude is None:
            return jsonify({"error": "Latitude must be a number between -90 and 90"}), 400
        if payload.get("longitude") is not None and longitude is None:
            return jsonify({"error": "Longitude must be a number between -180 and 180"}), 400

        reported_at = payload.get("reportedAt") or datetime.now(timezone.utc).isoformat()
        try:
            datetime.fromisoformat(reported_at.replace("Z", "+00:00"))
        except (AttributeError, ValueError):
            return jsonify({"error": "reportedAt must be an ISO-8601 timestamp"}), 400

        risk = payload.get("risk", "medium")
        if risk not in ALLOWED_RISKS:
            return jsonify({"error": "Unsupported risk level"}), 400

        connection = _connect(app.config["DATABASE_PATH"])
        cursor = connection.execute(
            """
            INSERT INTO incidents (
                type, description, location, reported_at, status, risk,
                evidence_path, latitude, longitude, reporter_device_id
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                incident_type,
                payload["description"].strip(),
                payload["location"].strip(),
                reported_at,
                "pending",
                risk,
                _save_evidence(request.files.get("evidence"), app.config["EVIDENCE_DIRECTORY"])
                if multipart
                else payload.get("evidencePath"),
                latitude,
                longitude,
                payload.get("deviceId"),
            ),
        )
        _create_notification(
            connection,
            payload.get("deviceId"),
            "Report submitted",
            "Your report was submitted and is awaiting review.",
            cursor.lastrowid,
        )
        connection.commit()
        incident = connection.execute(
            "SELECT * FROM incidents WHERE id = ?", (cursor.lastrowid,)
        ).fetchone()
        connection.close()
        return jsonify(dict(incident)), 201

    @app.patch("/api/admin/incidents/<int:incident_id>")
    def moderate_incident(incident_id):
        if not _authorized_admin(request, app.config["ADMIN_TOKEN"]):
            return jsonify({"error": "Admin authentication required"}), 401

        payload = request.get_json(silent=True)
        if not isinstance(payload, dict):
            return jsonify({"error": "Request body must be a JSON object"}), 400

        status = payload.get("status")
        risk = payload.get("risk")
        if status is None and risk is None:
            return jsonify({"error": "Provide status or risk"}), 400
        if status is not None and status not in ALLOWED_STATUSES:
            return jsonify({"error": "Unsupported incident status"}), 400
        if risk is not None and risk not in ALLOWED_RISKS:
            return jsonify({"error": "Unsupported risk level"}), 400

        updates = []
        values = []
        if status is not None:
            updates.append("status = ?")
            values.append(status)
        if risk is not None:
            updates.append("risk = ?")
            values.append(risk)
        values.append(incident_id)

        connection = _connect(app.config["DATABASE_PATH"])
        previous = connection.execute(
            "SELECT status FROM incidents WHERE id = ?", (incident_id,)
        ).fetchone()
        cursor = connection.execute(
            f"UPDATE incidents SET {', '.join(updates)} WHERE id = ?", values
        )
        if cursor.rowcount == 0:
            connection.close()
            return jsonify({"error": "Incident not found"}), 404
        connection.commit()
        incident = connection.execute(
            "SELECT * FROM incidents WHERE id = ?", (incident_id,)
        ).fetchone()
        if status is not None and previous and previous["status"] != status:
            _create_notification(
                connection,
                incident["reporter_device_id"],
                "Report status updated",
                f"Your report is now {status}.",
                incident_id,
            )
            connection.commit()
        connection.close()
        return jsonify(dict(incident))

    return app


def _connect(database_path):
    connection = sqlite3.connect(database_path)
    connection.row_factory = sqlite3.Row
    return connection


def _init_database(database_path):
    Path(database_path).parent.mkdir(parents=True, exist_ok=True)
    connection = _connect(database_path)
    connection.execute(
        """
        CREATE TABLE IF NOT EXISTS incidents (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            description TEXT NOT NULL,
            location TEXT NOT NULL,
            reported_at TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending',
            risk TEXT NOT NULL DEFAULT 'medium',
            evidence_path TEXT,
            latitude REAL,
            longitude REAL,
            reporter_device_id TEXT
        )
        """
    )
    columns = {
        row["name"] for row in connection.execute("PRAGMA table_info(incidents)")
    }
    if "reporter_device_id" not in columns:
        connection.execute("ALTER TABLE incidents ADD COLUMN reporter_device_id TEXT")
    connection.execute(
        """
        CREATE TABLE IF NOT EXISTS notifications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            device_id TEXT NOT NULL,
            title TEXT NOT NULL,
            message TEXT NOT NULL,
            incident_id INTEGER,
            created_at TEXT NOT NULL,
            read INTEGER NOT NULL DEFAULT 0
        )
        """
    )
    connection.commit()
    connection.close()


def _text(value):
    return isinstance(value, str) and value.strip()


def _coordinate(value, minimum, maximum):
    if value is None:
        return None
    try:
        number = float(value)
    except (TypeError, ValueError):
        return None
    return number if minimum <= number <= maximum else None


def _create_notification(connection, device_id, title, message, incident_id):
    if not _text(device_id):
        return
    connection.execute(
        """
        INSERT INTO notifications (device_id, title, message, incident_id, created_at)
        VALUES (?, ?, ?, ?, ?)
        """,
        (device_id.strip(), title, message, incident_id, datetime.now(timezone.utc).isoformat()),
    )


def _save_evidence(file, evidence_directory):
    if file is None or not file.filename:
        return None
    filename = secure_filename(file.filename)
    if not filename:
        return None
    stored_name = f"{uuid.uuid4().hex}_{filename}"
    directory = Path(evidence_directory)
    directory.mkdir(parents=True, exist_ok=True)
    file.save(directory / stored_name)
    return stored_name


def _authorized_admin(request, admin_token):
    if not admin_token:
        return False
    authorization = request.headers.get("Authorization", "")
    supplied_token = authorization.removeprefix("Bearer ").strip()
    return hmac.compare_digest(supplied_token, admin_token)


app = create_app()

if __name__ == "__main__":
    app.run(host=os.environ.get("HOST", "0.0.0.0"), port=int(os.environ.get("PORT", "5000")), debug=True)
