# CrimeTrack

CrimeTrack is a mobile-first Crime Location Reporting System for improving how
communities report, visualize, and respond to crime incidents. The initial
prototype is a Flutter application focused on Lagos Metro.

The project is guided by the supplied Term of Reference (TOR) for the Crime
Location Reporting System.

## Project Goals

- Enable timely crime and suspicious-activity reporting.
- Capture incident locations through GPS or map selection.
- Display verified incidents and crime-prone areas on a map.
- Give security teams structured data for monitoring and decision-making.
- Provide reports, alerts, and analytics as the platform matures.

## Current Prototype

The Flutter prototype currently includes:

- **Overview:** community status, incident metrics, and a map preview.
- **Report an incident:** incident type, description, location, and optional
  image or video evidence selected from the device gallery, plus current GPS
  coordinates when location permission is granted.
- **Incident map:** an interactive map with incident markers and filters by
  type, status, and risk for Lagos Metro. The map can detect and center on the
  device with the user-triggered "Locate me" action.
- **My reports:** submitted report history with review, verification, and
  resolution states.
- **Safety hub:** emergency services dialing through `112` and emergency
  contact entries.

The displayed data includes local prototype data, and newly submitted reports
are persisted locally on the device. Backend persistence, authentication,
remote media uploads, notifications, and
admin validation are planned integration work. Map rendering now uses
`flutter_map` with OpenStreetMap tiles and requires no API key for development.

## Planned Scope

### Public application

1. Submit reports for theft, robbery, kidnapping, suspicious activity, and
   other incidents.
2. Add a description, date and time, GPS/map location, and optional image or
   video evidence.
3. Submit anonymously or with an identified reporter profile.
4. View verified incidents, risk levels, hotspots, and report status.
5. Access emergency contacts and receive relevant alerts.

### Admin dashboard

1. Secure admin login and role-based access.
2. Review, approve, reject, or flag submitted reports.
3. Classify incidents and assign High, Medium, or Low risk levels.
4. Monitor incidents on a map and manage users.
5. View daily, weekly, and monthly analytics, export data, and track system
   logs.

## Technical Direction

The TOR describes a three-tier architecture:

```text
User/Admin interface -> Flask REST API -> Database -> Dashboard and map output
```

- **Presentation:** Flutter mobile client, with responsive web support as
  needed.
- **Application:** Python Flask API for authentication, validation, business
  logic, and report processing.
- **Data:** SQLite during prototyping and MySQL for production.
- **Integrations:** `flutter_map` with OpenStreetMap tiles, geolocation
  services, REST, and AJAX or equivalent real-time updates.

The current repository contains the Flutter presentation layer. The Flask API
and admin dashboard will be added as separate integration work rather than
being represented as completed features.

### Map usage

The prototype uses the public OpenStreetMap tile endpoint, which is suitable
for development and low-volume testing without an API key. Before production,
use a hosted OSM-compatible tile provider or self-host tiles and follow its
terms, attribution, caching, and rate-limit requirements.

## Project Structure

```text
lib/
  app.dart                         Application setup and theme
  main.dart                        Application entry point
  core/                            Shared theme and widgets
  features/home/                   Overview screen
  features/incidents/              Incident map and incident list
  features/report/                 Report submission sheet
  features/reports/                User report history
  features/safety/                 Emergency contacts and safety actions
  features/shell/                  Navigation shell
test/                              Flutter widget tests
```

## Getting Started

### Requirements

- Flutter SDK compatible with the Dart SDK constraint in `pubspec.yaml`
- Android Studio or Xcode for device and simulator builds
- A connected emulator, simulator, or physical device

### Run locally

```bash
flutter pub get
flutter run
```

### Validate the project

```bash
flutter analyze
flutter test
```

## Delivery Roadmap

1. **Requirements and design:** finalize report fields, user roles, risk
   levels, privacy rules, and map behavior.
2. **Core development:** connect the Flutter screens to the Flask REST API,
   add authentication, remote persistence, geolocation, and media handling.
3. **Admin operations:** build report validation, user management, map
   analytics, exports, and audit logs.
4. **Testing and deployment:** validate reporting workflows, permissions,
   location accuracy, security, accessibility, and responsive behavior before
   deployment.

## Stakeholders and Use Cases

CrimeTrack is intended for public users, community organizations, schools and
campuses, private estates, local government security systems, law-enforcement
support teams, and project management or supervision teams.

Example use cases include reporting robbery or theft, tracking kidnapping
locations, monitoring suspicious activity, identifying crime-prone zones, and
supporting rapid-response decisions.

## Safety and Privacy

CrimeTrack is a reporting and monitoring tool, not a replacement for emergency
services. Users should contact the appropriate emergency service when there is
an immediate threat. Production implementation must protect reporter identity,
secure evidence, validate reports, restrict admin access, and avoid exposing
sensitive location or personal data unnecessarily.
