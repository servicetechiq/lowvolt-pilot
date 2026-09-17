import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _createAccount = false;
  bool _busy = false;
  bool _obscurePassword = true;
  String? _message;
  bool _messageIsError = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      if (_createAccount) {
        final response = await AuthService.signUp(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _nameController.text,
        );

        if (!mounted) return;
        if (response.session == null) {
          setState(() {
            _messageIsError = false;
            _message =
                'Account created. Check your email to confirm the account, '
                'then sign in.';
            _createAccount = false;
          });
        }
      } else {
        await AuthService.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _messageIsError = true;
        _message = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messageIsError = true;
        _message = 'Unable to continue: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _socialSignIn(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      await action();
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _messageIsError = true;
        _message = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messageIsError = true;
        _message = 'Unable to continue: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _messageIsError = true;
        _message = 'Enter your email address first.';
      });
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      await AuthService.sendPasswordReset(email);
      if (!mounted) return;
      setState(() {
        _messageIsError = false;
        _message = 'Password reset email sent.';
      });
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _messageIsError = true;
        _message = error.message;
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.electrical_services_outlined,
                      size: 58,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'LowVolt Pilot',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _createAccount
                          ? 'Create your technician account'
                          : 'Sign in to your technician workspace',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _socialSignIn(AuthService.signInWithGoogle),
                      icon: const Icon(Icons.g_mobiledata, size: 28),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Continue with Google'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () =>
                                _socialSignIn(AuthService.signInWithMicrosoft),
                      icon: const Icon(Icons.window_outlined),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Continue with Microsoft'),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            _createAccount
                                ? 'or create with email'
                                : 'or sign in with email',
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (_createAccount) ...[
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (!_createAccount) return null;
                          if (value == null || value.trim().length < 2) {
                            return 'Enter your name.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty || !email.contains('@')) {
                          return 'Enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autofillHints: _createAccount
                          ? const [AutofillHints.newPassword]
                          : const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        final password = value ?? '';
                        if (password.length < 8) {
                          return 'Use at least 8 characters.';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _busy ? null : _submit(),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _message!,
                        style: TextStyle(
                          color: _messageIsError
                              ? colorScheme.error
                              : colorScheme.primary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: _busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _createAccount ? 'Create account' : 'Sign in',
                              ),
                      ),
                    ),
                    if (!_createAccount)
                      TextButton(
                        onPressed: _busy ? null : _resetPassword,
                        child: const Text('Forgot password?'),
                      ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _createAccount = !_createAccount;
                              _message = null;
                            }),
                      child: Text(
                        _createAccount
                            ? 'Already have an account? Sign in'
                            : 'New to LowVolt Pilot? Create account',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
