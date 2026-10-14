// Owner: Vishwa. The app's first screen: the app itself when someone is
// signed in (always, in fake data mode), the sign-in form otherwise.
// Rebuilds by itself when AccountsProvider reports a sign-in or sign-out.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../screens/home_shell.dart';
import 'accounts_provider.dart';
import 'sign_in_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final signedIn = context.watch<AccountsProvider>().isSignedIn;
    return signedIn ? const HomeShell() : const SignInScreen();
  }
}
