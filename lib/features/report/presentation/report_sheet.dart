import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../incidents/models/incident.dart';

class ReportSheet extends StatefulWidget {
  const ReportSheet({super.key, required this.onSubmit});

  final Future<void> Function(Incident) onSubmit;

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _picker = ImagePicker();
  String _type = 'Theft';
  String? _evidencePath;
  double? _latitude;
  double? _longitude;
  bool _locating = false;

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _showMessage('Turn on location services to use GPS');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage('Location permission is required for GPS');
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationController.text =
            '${position.latitude.toStringAsFixed(5)}, '
            '${position.longitude.toStringAsFixed(5)}';
      });
    } catch (_) {
      _showMessage('Could not get your current location');
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

  Future<void> _pickEvidence(ImageSource source, {bool video = false}) async {
    final file = video
        ? await _picker.pickVideo(source: source)
        : await _picker.pickImage(source: source);
    if (file == null || !mounted) return;
    setState(() => _evidencePath = file.path);
  }

  Future<void> _chooseEvidence() async {
    final selection = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: const Text('Choose an image'),
              onTap: () => Navigator.pop(context, false),
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Choose a video'),
              onTap: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
    );
    if (selection == null) return;
    await _pickEvidence(ImageSource.gallery, video: selection);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  InputDecoration _input(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
    labelStyle: TextStyle(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.outline.withAlpha(50),
        width: 0,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.outline.withAlpha(50),
        width: 0,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.primary.withAlpha(50),
        width: 0,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.error.withAlpha(50),
        width: 0,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.error.withAlpha(50),
        width: 0,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Report an incident',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Your report helps keep the community informed.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'INCIDENT TYPE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 9),
            DropdownButtonFormField<String>(
              initialValue: _type,
              items:
                  [
                        'Theft',
                        'Robbery',
                        'Kidnapping',
                        'Suspicious activity',
                        'Other',
                      ]
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
              onChanged: (value) => setState(() => _type = value!),
              decoration: _input('Select incident type'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: _input('Describe what happened'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Add a short description'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _locationController,
              decoration: _input('Location').copyWith(
                prefixIcon: const Icon(
                  Icons.location_on_outlined,
                  color: AppTheme.amber,
                ),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Add the incident location'
                  : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _locating ? null : _useCurrentLocation,
                icon: _locating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location, size: 17),
                label: Text(_locating ? 'Locating...' : 'Use current location'),
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _chooseEvidence,
              icon: Icon(
                Icons.add_photo_alternate_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              label: Text(
                _evidencePath == null ? 'Attach evidence' : 'Evidence added',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFD5DBDD),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withAlpha(50),
                ),
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  await widget.onSubmit(
                    Incident(
                      type: _type,
                      description: _descriptionController.text.trim(),
                      location: _locationController.text.trim(),
                      reportedAt: DateTime.now(),
                      status: IncidentStatus.pending,
                      risk: IncidentRisk.medium,
                      evidencePath: _evidencePath,
                      latitude: _latitude,
                      longitude: _longitude,
                    ),
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.amber,
                  foregroundColor: AppTheme.navigation,
                ),
                child: const Text(
                  'SUBMIT REPORT',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
