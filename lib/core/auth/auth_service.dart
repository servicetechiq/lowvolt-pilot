import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService._();

  static const _mobileRedirectTo =
      'com.primalarray.lowvoltpilot://login-callback/';

  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser => client.auth.currentUser;

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String displayName,
  }) {
    return client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'display_name': displayName.trim()},
    );
  }

  static Future<void> signInWithGoogle() async {
    await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : _mobileRedirectTo,
    );
  }

  static Future<void> signInWithMicrosoft() async {
    await client.auth.signInWithOAuth(
      OAuthProvider.azure,
      redirectTo: kIsWeb ? null : _mobileRedirectTo,
      scopes: 'email',
    );
  }

  static Future<void> sendPasswordReset(String email) {
    return client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: kIsWeb ? null : _mobileRedirectTo,
    );
  }

  static Future<void> signOut() => client.auth.signOut();
}
