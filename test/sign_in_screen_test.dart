import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_travel_assistant/dev/app_config.dart';
import 'package:smart_travel_assistant/features/accounts/accounts_provider.dart';
import 'package:smart_travel_assistant/features/accounts/sign_in_screen.dart';
import 'package:smart_travel_assistant/theme/meridian_theme.dart';

// Only the checks that run before anything is sent: no Supabase in tests.
Widget _app() {
  return ChangeNotifierProvider(
    create: (_) => AccountsProvider(),
    child: MaterialApp(theme: meridianTheme(Brightness.dark), home: const SignInScreen()),
  );
}

void main() {
  setUp(() => debugUseFakeData = true);
  tearDown(() => debugUseFakeData = null);

  testWidgets('Sign in with empty fields shows both problems under their fields', (tester) async {
    await tester.pumpWidget(_app());

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    expect(find.text('Enter your email.'), findsOneWidget);
    expect(find.text('Use a password of at least 6 characters.'), findsOneWidget);
  });

  testWidgets('the eye button shows and hides the password', (tester) async {
    await tester.pumpWidget(_app());
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'secret123');

    TextField password() => tester.widget<TextField>(find.widgetWithText(TextField, 'Password'));
    expect(password().obscureText, isTrue);

    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(password().obscureText, isFalse);
  });

  testWidgets('Create an account switches the form and adds a name field', (tester) async {
    await tester.pumpWidget(_app());

    await tester.tap(find.text('Create an account'));
    await tester.pump();

    expect(find.widgetWithText(TextField, 'Your name (optional)'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Create account'), findsOneWidget);

    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(find.widgetWithText(TextField, 'Your name (optional)'), findsNothing);
  });

  testWidgets('Continue with Google is offered below the form', (tester) async {
    await tester.pumpWidget(_app());

    expect(find.widgetWithText(OutlinedButton, 'Continue with Google'), findsOneWidget);
    expect(find.text('OR'), findsOneWidget);
  });
}
