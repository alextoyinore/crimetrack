// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:crimetrack/app.dart';
import 'package:crimetrack/features/incidents/data/incident_repository.dart';
import 'package:crimetrack/features/incidents/models/incident.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'crimetrack.onboarding_complete': true,
    });
  });

  testWidgets('renders the CrimeTrack overview', (WidgetTester tester) async {
    await tester.pumpWidget(const CrimeTrackApp());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
    expect(find.text('CRIMETRACK'), findsOneWidget);
    expect(find.text('REPORT AN INCIDENT'), findsOneWidget);
  });

  testWidgets('submits a report into the report history', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CrimeTrackApp());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('REPORT AN INCIDENT'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'A stolen phone was reported.');
    await tester.enterText(fields.at(1), 'Ikeja, Lagos');
    await tester.tap(find.text('SUBMIT REPORT'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My reports'));
    await tester.pumpAndSettle();

    expect(find.text('Theft reported'), findsNWidgets(2));
    expect(find.text('Ikeja, Lagos'), findsOneWidget);
  });

  testWidgets('filters incidents by type', (WidgetTester tester) async {
    await tester.pumpWidget(const CrimeTrackApp());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Incidents'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('All types'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Robbery').last);
    await tester.pumpAndSettle();

    expect(find.text('Robbery'), findsNWidgets(2));
    expect(find.text('Theft'), findsNothing);
  });

  testWidgets('shows onboarding on first launch', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const CrimeTrackApp());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(find.text('Know what is happening nearby'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('REPORT AN INCIDENT'), findsOneWidget);
  });

  test('persists and restores incident details', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = IncidentRepository();
    final incident = Incident(
      type: 'Robbery',
      description: 'A report with stored details.',
      location: 'Ikeja, Lagos',
      reportedAt: DateTime(2026, 8, 24, 12),
      status: IncidentStatus.pending,
      risk: IncidentRisk.high,
      evidencePath: '/tmp/evidence.jpg',
      latitude: 6.6194,
      longitude: 3.3488,
    );

    await repository.saveUserIncidents([incident]);
    final restored = await repository.loadUserIncidents();

    expect(restored, hasLength(1));
    expect(restored.single.type, incident.type);
    expect(restored.single.reportedAt, incident.reportedAt);
    expect(restored.single.latitude, incident.latitude);
    expect(restored.single.longitude, incident.longitude);
    expect(restored.single.evidencePath, incident.evidencePath);
  });

  test('uses the Flask API for incident submission and loading', () async {
    SharedPreferences.setMockInitialValues({});
    final client = MockClient((request) async {
      if (request.method == 'POST') {
        expect(request.url.path, '/api/incidents');
        expect(request.body, contains('Ikeja, Lagos'));
        return http.Response('{"id": 1}', 201);
      }
      return http.Response(
        '[{"type":"Robbery","description":"API report",'
        '"location":"Yaba, Lagos","reported_at":"2026-08-24T12:00:00Z",'
        '"status":"pending","risk":"high","latitude":6.52,'
        '"longitude":3.38,"evidence_path":null}]',
        200,
      );
    });
    final repository = IncidentRepository(
      baseUrl: 'http://test-server',
      client: client,
    );
    final incident = Incident(
      type: 'Theft',
      description: 'API submission',
      location: 'Ikeja, Lagos',
      reportedAt: DateTime(2026, 8, 24),
      status: IncidentStatus.pending,
      risk: IncidentRisk.medium,
    );

    expect(await repository.submitIncident(incident), isTrue);
    final loaded = await repository.loadUserIncidents();

    expect(loaded.single.type, 'Robbery');
    expect(loaded.single.latitude, 6.52);
    expect(loaded.single.longitude, 3.38);
  });
}
