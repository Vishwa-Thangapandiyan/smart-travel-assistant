// Owner: Vishwa. Sign in, or create an account, with email and password
// (REQ-1.1). Field problems show under the field before anything is sent;
// Supabase's answers show as plain sentences (REQ-1.4).
// Continue with Google opens the browser and comes back to the app.
// Design: design/screens/night-01-sign-in.png. "Forgot password?" needs a
// reset link into the app first (issue #34).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/meridian_colors.dart';
import '../../theme/meridian_theme.dart';
import 'accounts_provider.dart';
import 'auth_errors.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _creating = false; // false: Sign in; true: Create an account
  bool _showPassword = false;
  bool _busy = false;
  String? _emailError;
  String? _passwordError;
  String? _serverError;
  String? _errorDetails; // the raw error, shown only in debug builds
  String? _notice;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _creating = !_creating;
      _emailError = null;
      _passwordError = null;
      _serverError = null;
      _notice = null;
    });
  }

  Future<void> _google() async {
    setState(() {
      _serverError = null;
      _errorDetails = null;
    });
    try {
      await context.read<AccountsProvider>().signInWithGoogle();
      // The browser opens; AuthGate swaps this screen for the app when it comes back.
    } on Exception catch (error) {
      debugPrint('Google sign-in failed: $error');
      if (mounted) {
        setState(() {
          _serverError = authErrorMessage(error);
          _errorDetails = kDebugMode ? '$error' : null;
        });
      }
    }
  }

  Future<void> _submit() async {
    final emailError = checkEmail(_email.text);
    final passwordError = checkPassword(_password.text);
    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
      _serverError = null;
      _notice = null;
    });
    if (emailError != null || passwordError != null) return;

    final accounts = context.read<AccountsProvider>();
    setState(() => _busy = true);
    try {
      if (_creating) {
        final signedIn = await accounts.signUp(email: _email.text, password: _password.text, fullName: _name.text);
        if (!signedIn && mounted) {
          setState(() => _notice = 'Account made. Check your email for the confirmation link, then sign in.');
        }
      } else {
        await accounts.signIn(email: _email.text, password: _password.text);
      }
      // On success AuthGate swaps this screen for the app.
    } on Exception catch (error) {
      // The raw error goes to the flutter run terminal (debug builds only) for whoever is fixing it.
      debugPrint('Sign-in failed: $error');
      if (mounted) {
        setState(() {
          _serverError = authErrorMessage(error);
          _errorDetails = kDebugMode ? '$error' : null;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset('assets/brand/meridian-mark.png', width: 28, height: 28, semanticLabel: 'Meridian logo'),
                ),
                const SizedBox(width: 10),
                Text('Meridian', style: text.titleLarge),
              ],
            ),
            const SizedBox(height: 48),
            Text(_creating ? 'Create an account' : 'Sign in', style: text.headlineMedium),
            const SizedBox(height: 6),
            Text('Your trips, budget and saved maps follow you.',
                style: text.bodyMedium?.copyWith(color: colors.inkSoft)),
            const SizedBox(height: 28),
            if (_creating) ...[
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(labelText: 'Your name (optional)'),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(labelText: 'Email', errorText: _emailError),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _password,
              obscureText: !_showPassword,
              autofillHints: [_creating ? AutofillHints.newPassword : AutofillHints.password],
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Password',
                errorText: _passwordError,
                suffixIcon: IconButton(
                  tooltip: _showPassword ? 'Hide password' : 'Show password',
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                  icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_serverError != null) ...[
              Text(_serverError!, style: text.bodyMedium?.copyWith(color: colors.coral)),
              if (_errorDetails != null)
                SelectableText('Debug details: $_errorDetails',
                    style: MeridianText.monoData.copyWith(fontSize: 10, color: colors.inkSoft)),
              const SizedBox(height: 12),
            ],
            if (_notice != null) ...[
              Text(_notice!, style: text.bodyMedium?.copyWith(color: colors.green)),
              const SizedBox(height: 12),
            ],
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: Text(_busy ? 'One moment…' : (_creating ? 'Create account' : 'Sign in')),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Divider(color: colors.line)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('OR', style: MeridianText.monoData.copyWith(color: colors.inkSoft)),
                ),
                Expanded(child: Divider(color: colors.line)),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _busy ? null : _google,
              icon: const Icon(Icons.account_circle_outlined),
              label: const Text('Continue with Google'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_creating ? 'Have an account?' : 'New to Meridian?',
                    style: text.bodyMedium?.copyWith(color: colors.inkSoft)),
                TextButton(
                  onPressed: _busy ? null : _switchMode,
                  child: Text(_creating ? 'Sign in' : 'Create an account',
                      style: MeridianText.monoData.copyWith(fontSize: 14, color: colors.amberText)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
