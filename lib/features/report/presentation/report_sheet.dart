import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class ReportSheet extends StatefulWidget {
  const ReportSheet({super.key});
  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  String _type = 'Theft';

  InputDecoration _input(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFF242C31),
    hintStyle: const TextStyle(color: Color(0xFF7E898F)),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide.none,
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
          const Text(
            'Your report helps keep the community informed.',
            style: TextStyle(color: AppTheme.muted),
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
          TextField(maxLines: 3, decoration: _input('Describe what happened')),
          const SizedBox(height: 14),
          TextField(
            decoration: _input('Location').copyWith(
              prefixIcon: const Icon(
                Icons.location_on_outlined,
                color: AppTheme.amber,
              ),
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Attach evidence'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFD5DBDD),
              side: const BorderSide(color: Color(0xFF475158)),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
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
  );
}
