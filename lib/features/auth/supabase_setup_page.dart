import 'package:flutter/material.dart';

class SupabaseSetupPage extends StatelessWidget {
  const SupabaseSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LowVolt Pilot')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 54,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 18),
          Text(
            'Account service not configured',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          const Text(
            'LowVolt Pilot now requires a technician account. '
            'Add the Supabase project URL and publishable key using '
            'Flutter dart-defines, then restart the app.',
          ),
          const SizedBox(height: 18),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: SelectableText(
                'flutter run --dart-define-from-file=config/supabase.json',
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Use config/supabase.example.json as the template. '
            'The real config/supabase.json file is ignored by Git.',
          ),
        ],
      ),
    );
  }
}
