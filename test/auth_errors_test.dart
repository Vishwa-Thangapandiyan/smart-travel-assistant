import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_travel_assistant/features/accounts/auth_errors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('a wrong password says so in plain words', () {
    final message = authErrorMessage(
      const AuthApiException('Invalid login credentials', statusCode: '400', code: 'invalid_credentials'),
    );

    expect(message, 'That email and password don\'t match.');
  });

  test('an older server with no code is still recognised by its message', () {
    expect(authErrorMessage(const AuthException('Invalid login credentials')),
        'That email and password don\'t match.');
  });

  test('signing up twice points to sign in', () {
    expect(authErrorMessage(const AuthException('User already registered', code: 'user_already_exists')),
        contains('Sign in instead'));
    expect(authErrorMessage(const AuthException('exists', code: 'email_exists')), contains('Sign in instead'));
  });

  test('a short password asks for a longer one', () {
    expect(authErrorMessage(const AuthException('Password should be at least 6 characters', code: 'weak_password')),
        contains('at least 6 characters'));
  });

  test('too many tries asks to wait', () {
    expect(authErrorMessage(const AuthException('rate limit', code: 'over_request_rate_limit')), contains('Wait'));
  });

  test('no internet says so', () {
    expect(authErrorMessage(AuthRetryableFetchException(message: 'fetch failed')), contains('No connection'));
    expect(authErrorMessage(const SocketException('Failed host lookup')), contains('No connection'));
  });

  test('anything else gets a calm general message, never the raw error', () {
    final message = authErrorMessage(const AuthException('AuthUnknownError: 500 {"weird":"json"}', code: 'unexpected'));

    expect(message, isNot(contains('json')));
    expect(message, contains('Try again'));
  });

  group('the form checks before anything is sent', () {
    test('an empty or malformed email is caught', () {
      expect(checkEmail(''), isNotNull);
      expect(checkEmail('vishwa'), isNotNull);
      expect(checkEmail('vishwa@example.com'), isNull);
    });

    test('a password under 6 characters is caught', () {
      expect(checkPassword('12345'), isNotNull);
      expect(checkPassword('123456'), isNull);
    });
  });
}
