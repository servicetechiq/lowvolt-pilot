import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/login_page.dart';
import '../../features/home/home_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Session? _session;
  StreamSubscription<AuthState>? _subscription;

  @override
  void initState() {
    super.initState();
    final auth = Supabase.instance.client.auth;
    _session = auth.currentSession;
    _subscription = auth.onAuthStateChange.listen((state) {
      if (!mounted) return;
      setState(() => _session = state.session);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _session == null ? const LoginPage() : const HomePage();
  }
}
