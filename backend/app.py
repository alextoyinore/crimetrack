import os
import hmac
import sqlite3
from datetime import datetime, timezone
from pathlib import Path

from flask import Flask, jsonify, request


BASE_DIR = Path(__file__).resolve().parent
DATABASE_PATH = Path(os.environ.get("CRIMETRACK_DATABASE", BASE_DIR / "crimetrack.db"))
ALLOWED_TYPES = {"Theft", "Robbery", "Kidnapping", "Suspicious activity", "Other"}
ALLOWED_RISKS = {"high", "medium", "low"}
ALLOWED_STATUSES = {"pending", "verified", "resolved", "rejected", "flagged"}


def create_app(database_path=DATABASE_PATH, admin_token=None):
    app = Flask(__name__)
    app.config["DATABASE_PATH"] = str(database_path)
    app.config["ADMIN_TOKEN"] = (
        admin_token if admin_token is not None else os.environ.get("CRIMETRACK_ADMIN_TOKEN")
    )
    app.config["ADMIN_USERNAME"] = os.environ.get("CRIMETRACK_ADMIN_USERNAME")
    app.config["ADMIN_PASSWORD"] = os.environ.get("CRIMETRACK_ADMIN_PASSWORD")

    with app.app_context():
        _init_database(app.config["DATABASE_PATH"])

    @app.get("/health")
    def health():
        return jsonify({"status": "ok"})

    @app.get("/api/incidents")
    def list_incidents():
        connection = _connect(app.config["DATABASE_PATH"])
        rows = connection.execute(
            """
            SELECT id, type, description, location, reported_at, status, risk,
                   evidence_path, latitude, longitude
            FROM incidents
            ORDER BY reported_at DESC
            """
        ).fetchall()
        connection.close()
        return jsonify([dict(row) for row in rows])

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

    @app.post("/api/incidents")
    def create_incident():
        payload = request.get_json(silent=True)
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
                evidence_path, latitude, longitude
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                incident_type,
                payload["description"].strip(),
                payload["location"].strip(),
                reported_at,
                "pending",
                risk,
                payload.get("evidencePath"),
                latitude,
                longitude,
            ),
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
            longitude REAL
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


def _authorized_admin(request, admin_token):
    if not admin_token:
        return False
    authorization = request.headers.get("Authorization", "")
    supplied_token = authorization.removeprefix("Bearer ").strip()
    return hmac.compare_digest(supplied_token, admin_token)


app = create_app()

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=int(os.environ.get("PORT", "5000")), debug=True)
