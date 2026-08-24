import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../features/incidents/models/incident.dart';
import '../theme/app_theme.dart';

class MapPreview extends StatefulWidget {
  const MapPreview({super.key, this.incidents = const []});

  final List<Incident> incidents;

  @override
  State<MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<MapPreview> {
  final _mapController = MapController();
  LatLng? _currentLocation;
  bool _locating = false;

  Future<void> _loadCurrentLocation({required bool requestPermission}) async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (requestPermission) {
          _showMessage('Turn on location services to locate yourself');
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (requestPermission) {
          _showMessage('Location permission is required to locate yourself');
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      final location = LatLng(position.latitude, position.longitude);
      setState(() => _currentLocation = location);
      _mapController.move(location, 14);
    } catch (_) {
      if (requestPermission) {
        _showMessage('Could not get your current location');
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

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
          mapController: _mapController,
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
                for (final incident in widget.incidents)
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
                if (_currentLocation != null)
                  Marker(
                    point: _currentLocation!,
                    width: 38,
                    height: 38,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.amber, width: 3),
                      ),
                      child: const Icon(
                        Icons.my_location,
                        color: AppTheme.navigation,
                        size: 20,
                      ),
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
            child: Row(
              children: [
                const Icon(Icons.my_location, size: 13, color: AppTheme.amber),
                const SizedBox(width: 6),
                Text(
                  _currentLocation == null ? 'Lagos Metro' : 'Current location',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: const Color(0xE61A2025),
            borderRadius: BorderRadius.circular(7),
            child: IconButton(
              tooltip: 'Locate me',
              onPressed: _locating
                  ? null
                  : () => _loadCurrentLocation(requestPermission: true),
              icon: _locating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, size: 18),
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
