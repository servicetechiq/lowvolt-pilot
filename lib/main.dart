import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/theme/app_theme.dart';
import 'core/auth/auth_gate.dart';
import 'core/config/supabase_config.dart';
import 'features/auth/supabase_setup_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  }

  runApp(const LowVoltPilotApp());
}

class LowVoltPilotApp extends StatelessWidget {
  const LowVoltPilotApp({super.key, this.configuredOverride});

  final bool? configuredOverride;

  @override
  Widget build(BuildContext context) {
    final configured = configuredOverride ?? SupabaseConfig.isConfigured;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LowVolt Pilot',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: configured ? const AuthGate() : const SupabaseSetupPage(),
    );
  }
}
