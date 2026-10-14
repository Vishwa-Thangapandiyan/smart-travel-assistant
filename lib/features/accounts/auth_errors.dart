// Owner: Vishwa. Turns Supabase Auth errors into plain sentences shown
// under the form (REQ-1.4) — the raw AuthException never reaches the
// screen. Also the two checks the form runs before sending anything.

import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

String authErrorMessage(Object error) {
  if (error is AuthRetryableFetchException || error is SocketException) {
    return 'No connection. Check your internet and try again.';
  }
  if (error is AuthException) {
    switch (error.code) {
      case 'invalid_credentials':
        return 'That email and password don\'t match.';
      case 'user_already_exists':
      case 'email_exists':
        return 'There\'s already an account with this email. Sign in instead.';
      case 'weak_password':
        return 'Use a password of at least 6 characters.';
      case 'email_address_invalid':
      case 'validation_failed':
        return 'That doesn\'t look like an email address.';
      case 'email_not_confirmed':
        return 'Confirm your email first. Check your inbox for the link.';
      case 'over_request_rate_limit':
      case 'over_email_send_rate_limit':
        return 'Too many tries. Wait a minute, then try again.';
      case 'signup_disabled':
        return 'New accounts are switched off right now.';
    }
    // Older Supabase servers send no code for a wrong password.
    if (error.message.contains('Invalid login credentials')) {
      return 'That email and password don\'t match.';
    }
  }
  return 'Something went wrong. Try again in a moment.';
}

/// Null when the email looks usable.
String? checkEmail(String email) {
  final trimmed = email.trim();
  if (trimmed.isEmpty) return 'Enter your email.';
  // Deliberately loose: Supabase does the real check.
  if (!trimmed.contains('@') || !trimmed.contains('.')) return 'That doesn\'t look like an email address.';
  return null;
}

/// Null when the password is long enough (Supabase's default minimum is 6).
String? checkPassword(String password) {
  if (password.length < 6) return 'Use a password of at least 6 characters.';
  return null;
}
