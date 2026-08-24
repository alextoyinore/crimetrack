import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_theme.dart';
import '../../features/incidents/models/incident.dart';

class MapPreview extends StatelessWidget {
  const MapPreview({super.key, this.incidents = const []});

  final List<Incident> incidents;

  @override
  Widget build(BuildContext context) => Container(
    height: 210,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFF30383D)),
    ),
    child: Stack(
      children: [
        FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(6.6018, 3.3515),
            initialZoom: 11.5,
            interactionOptions: InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.crimetrack.app',
            ),
            MarkerLayer(
              markers: [
                for (final incident in incidents)
                  if (incident.latitude != null && incident.longitude != null)
                    Marker(
                      point: LatLng(incident.latitude!, incident.longitude!),
                      width: 30,
                      height: 30,
                      child: Icon(
                        Icons.location_on,
                        color: incident.riskColor,
                        size: 30,
                      ),
                    ),
              ],
            ),
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        Positioned(
          top: 13,
          left: 13,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xE61A2025),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Row(
              children: [
                Icon(Icons.my_location, size: 13, color: AppTheme.amber),
                SizedBox(width: 6),
                Text(
                  'Ikeja, Lagos',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        const Positioned(
          bottom: 13,
          right: 13,
          child: Column(
            children: [
              MapLegend(color: AppTheme.danger, label: 'High'),
              SizedBox(height: 5),
              MapLegend(color: AppTheme.amber, label: 'Medium'),
            ],
          ),
        ),
      ],
    ),
  );
}

class MapLegend extends StatelessWidget {
  const MapLegend({super.key, required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(fontSize: 10, color: Color(0xFFD0D6D8)),
      ),
    ],
  );
}
