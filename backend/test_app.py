import tempfile
import unittest
from pathlib import Path

from app import create_app


class IncidentApiTest(unittest.TestCase):
    def setUp(self):
        self.temp_directory = tempfile.TemporaryDirectory()
        database_path = Path(self.temp_directory.name) / "test.db"
        app = create_app(database_path, admin_token="test-token")
        app.config["ADMIN_USERNAME"] = None
        app.config["ADMIN_PASSWORD"] = None
        self.client = app.test_client()

    def tearDown(self):
        self.temp_directory.cleanup()

    def test_health_check(self):
        response = self.client.get("/health")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json, {"status": "ok"})

    def test_create_and_list_incident(self):
        response = self.client.post(
            "/api/incidents",
            json={
                "type": "Theft",
                "description": "A phone was stolen.",
                "location": "Ikeja, Lagos",
                "latitude": 6.6194,
                "longitude": 3.3488,
                "evidencePath": "/tmp/evidence.jpg",
            },
        )
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.json["status"], "pending")
        self.assertEqual(response.json["latitude"], 6.6194)

        response = self.client.get("/api/incidents")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.json), 1)
        self.assertEqual(response.json[0]["location"], "Ikeja, Lagos")

    def test_notifications_are_scoped_to_device(self):
        response = self.client.post(
            "/api/incidents",
            json={
                "type": "Theft",
                "description": "A device-scoped report.",
                "location": "Ikeja, Lagos",
                "deviceId": "device-a",
            },
        )
        self.assertEqual(response.status_code, 201)

        response = self.client.get("/api/notifications?deviceId=device-a")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.json), 1)
        self.assertEqual(response.json[0]["title"], "Report submitted")
        self.assertEqual(
            self.client.get("/api/notifications?deviceId=device-b").json, []
        )

        incident_id = self.client.get("/api/incidents?deviceId=device-a").json[0]["id"]
        response = self.client.patch(
            f"/api/admin/incidents/{incident_id}",
            headers={"Authorization": "Bearer test-token"},
            json={"status": "verified"},
        )
        self.assertEqual(response.status_code, 200)
        notifications = self.client.get("/api/notifications?deviceId=device-a").json
        self.assertEqual(len(notifications), 2)
        self.assertEqual(notifications[0]["title"], "Report status updated")

    def test_rejects_invalid_coordinates(self):
        response = self.client.post(
            "/api/incidents",
            json={
                "type": "Robbery",
                "description": "An invalid location.",
                "location": "Lagos",
                "latitude": 120,
            },
        )
        self.assertEqual(response.status_code, 400)
        self.assertIn("Latitude", response.json["error"])

    def test_rejects_missing_required_fields(self):
        response = self.client.post("/api/incidents", json={"type": "Theft"})
        self.assertEqual(response.status_code, 400)
        self.assertIn("description", response.json["error"])

    def test_admin_login_requires_configuration(self):
        response = self.client.post(
            "/api/admin/login", json={"username": "admin", "password": "secret"}
        )
        self.assertEqual(response.status_code, 503)

    def test_admin_login_returns_configured_token(self):
        app = create_app(
            Path(self.temp_directory.name) / "login.db", admin_token="test-token"
        )
        app.config["ADMIN_USERNAME"] = "admin"
        app.config["ADMIN_PASSWORD"] = "secret"
        response = app.test_client().post(
            "/api/admin/login", json={"username": "admin", "password": "secret"}
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json, {"token": "test-token"})

    def test_admin_moderates_incident(self):
        response = self.client.post(
            "/api/incidents",
            json={
                "type": "Theft",
                "description": "Needs review.",
                "location": "Ikeja, Lagos",
            },
        )
        incident_id = response.json["id"]

        response = self.client.patch(
            f"/api/admin/incidents/{incident_id}",
            json={"status": "verified", "risk": "high"},
        )
        self.assertEqual(response.status_code, 401)

        response = self.client.patch(
            f"/api/admin/incidents/{incident_id}",
            headers={"Authorization": "Bearer test-token"},
            json={"status": "verified", "risk": "high"},
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json["status"], "verified")
        self.assertEqual(response.json["risk"], "high")

    def test_web_admin_requires_login(self):
        response = self.client.get("/admin")
        self.assertEqual(response.status_code, 302)
        self.assertIn("/admin/login", response.location)

    def test_admin_analytics_requires_login_and_uses_incidents(self):
        response = self.client.get("/admin/analytics")
        self.assertEqual(response.status_code, 302)
        self.assertIn("/admin/login", response.location)

        app = create_app(
            Path(self.temp_directory.name) / "analytics.db", admin_token="test-token"
        )
        app.config["ADMIN_USERNAME"] = "admin"
        app.config["ADMIN_PASSWORD"] = "secret"
        client = app.test_client()
        client.post(
            "/api/incidents",
            json={
                "type": "Robbery",
                "description": "Analytics report.",
                "location": "Abuja",
            },
        )
        client.post("/admin/login", data={"username": "admin", "password": "secret"})
        response = client.get("/admin/analytics")
        self.assertEqual(response.status_code, 200)
        self.assertIn(b"Report analytics", response.data)
        self.assertIn(b"Robbery", response.data)

    def test_web_admin_login_and_moderation(self):
        app = create_app(
            Path(self.temp_directory.name) / "web.db", admin_token="test-token"
        )
        app.config["ADMIN_USERNAME"] = "admin"
        app.config["ADMIN_PASSWORD"] = "secret"
        client = app.test_client()
        client.post(
            "/api/incidents",
            json={
                "type": "Theft",
                "description": "Web review report.",
                "location": "Ikeja, Lagos",
            },
        )

        response = client.post(
            "/admin/login",
            data={"username": "admin", "password": "secret"},
            follow_redirects=True,
        )
        self.assertEqual(response.status_code, 200)
        self.assertIn(b"Incident overview", response.data)
        self.assertIn(b"Web review report.", response.data)

        response = client.post(
            "/admin/incidents/1/moderate",
            data={"status": "verified", "risk": "high"},
        )
        self.assertEqual(response.status_code, 302)
        incident = client.get("/api/incidents").json[0]
        self.assertEqual(incident["status"], "verified")
        self.assertEqual(incident["risk"], "high")


if __name__ == "__main__":
    unittest.main()
