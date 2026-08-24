import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/page_title.dart';

class SafetyPage extends StatefulWidget {
  const SafetyPage({super.key});

  @override
  State<SafetyPage> createState() => _SafetyPageState();
}

class _SafetyPageState extends State<SafetyPage> {
  Timer? _refreshTimer;
  String? _nearestPolice;
  String? _nearestPoliceNumber;
  bool _loadingPolice = false;

  @override
  void initState() {
    super.initState();
    _findNearestPolice();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _findNearestPolice(),
    );
  }

  Future<void> _findNearestPolice() async {
    if (_loadingPolice) return;
    setState(() => _loadingPolice = true);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _nearestPolice = null);
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
      final query =
          '[out:json];nwr["amenity"="police"](around:10000,${position.latitude},${position.longitude});out center tags;';
      final response = await http
          .get(
            Uri.parse(
              'https://overpass-api.de/api/interpreter',
            ).replace(queryParameters: {'data': query}),
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return;
      final elements = jsonDecode(response.body)['elements'] as List<dynamic>;
      Map<String, dynamic>? nearest;
      var nearestDistance = double.infinity;
      for (final raw in elements) {
        final element = raw as Map<String, dynamic>;
        final latitude = (element['lat'] ?? element['center']?['lat']) as num?;
        final longitude = (element['lon'] ?? element['center']?['lon']) as num?;
        if (latitude == null || longitude == null) continue;
        final distance = _distance(
          position.latitude,
          position.longitude,
          latitude.toDouble(),
          longitude.toDouble(),
        );
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearest = element;
        }
      }
      if (!mounted || nearest == null) return;
      final tags = nearest['tags'] as Map<String, dynamic>? ?? {};
      setState(() {
        _nearestPolice = tags['name'] as String? ?? 'Nearest police station';
        _nearestPoliceNumber =
            tags['phone'] as String? ?? tags['contact:phone'] as String?;
      });
    } catch (_) {
      // Keep emergency contacts available when the public map service is unavailable.
    } finally {
      if (mounted) setState(() => _loadingPolice = false);
    }
  }

  double _distance(
    double firstLatitude,
    double firstLongitude,
    double secondLatitude,
    double secondLongitude,
  ) {
    const earthRadius = 6371.0;
    final latitudeDelta = (secondLatitude - firstLatitude) * pi / 180;
    final longitudeDelta = (secondLongitude - firstLongitude) * pi / 180;
    final value =
        sin(latitudeDelta / 2) * sin(latitudeDelta / 2) +
        cos(firstLatitude * pi / 180) *
            cos(secondLatitude * pi / 180) *
            sin(longitudeDelta / 2) *
            sin(longitudeDelta / 2);
    return earthRadius * 2 * atan2(sqrt(value), sqrt(1 - value));
  }

  Future<void> _call(String number) async {
    final digits = number.replaceAll(RegExp(r'[^0-9+]'), '');
    final launched = await launchUrl(Uri(scheme: 'tel', path: digits));
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the phone dialer')),
      );
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageTitle(
          title: 'Safety hub',
          subtitle: 'Quick access across Nigeria',
        ),
        const SizedBox(height: 24),
        const Text(
          'NEAREST POLICE STATION',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        ContactRow(
          name: _nearestPolice ?? 'Allow location to find the nearest station',
          number: _loadingPolice
              ? 'Updating...'
              : (_nearestPoliceNumber ?? '112'),
          icon: Icons.local_police_outlined,
          onTap: () => _call(_nearestPoliceNumber ?? '112'),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 76,
          child: FilledButton.icon(
            onPressed: () => _call('112'),
            icon: const Icon(Icons.phone_in_talk_rounded),
            label: const Text(
              'NATIONAL EMERGENCY SERVICES  112',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: .8),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}

class ContactRow extends StatelessWidget {
  const ContactRow({
    super.key,
    required this.name,
    required this.number,
    required this.icon,
    required this.onTap,
  });

  final String name;
  final String number;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(11),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.amber),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              number,
              style: const TextStyle(
                color: AppTheme.amber,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.call, size: 17),
          ],
        ),
      ),
    ),
  );
}
