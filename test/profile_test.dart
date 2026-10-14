import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_travel_assistant/dev/app_config.dart';
import 'package:smart_travel_assistant/dev/fake_data.dart';
import 'package:smart_travel_assistant/features/accounts/accounts_provider.dart';
import 'package:smart_travel_assistant/features/accounts/profile_screen.dart';
import 'package:smart_travel_assistant/theme/meridian_theme.dart';

void main() {
  setUp(() {
    debugUseFakeData = true;
    resetFakeProfile();
  });
  tearDown(() => debugUseFakeData = null);

  group('the profile in AccountsProvider', () {
    test('loads the signed-in user\'s profile', () async {
      final accounts = AccountsProvider();

      await accounts.loadProfile();

      expect(accounts.profile!.id, demoUserId);
      expect(accounts.profile!.defaultCurrency, 'INR');
    });

    test('saving changes name, currency and interests, and keeps them', () async {
      final accounts = AccountsProvider();
      await accounts.loadProfile();

      await accounts.saveProfile(fullName: '  Vishwa T ', defaultCurrency: 'CHF', interests: ['restaurant', 'nature']);
      final reloaded = AccountsProvider();
      await reloaded.loadProfile();

      expect(reloaded.profile!.fullName, 'Vishwa T');
      expect(reloaded.profile!.defaultCurrency, 'CHF');
      expect(reloaded.interests, ['restaurant', 'nature']);
    });

    test('a blank name is saved as no name, not as spaces', () async {
      final accounts = AccountsProvider();
      await accounts.loadProfile();

      await accounts.saveProfile(fullName: '   ', defaultCurrency: 'INR', interests: []);

      expect(accounts.profile!.fullName, isNull);
      expect(accounts.interests, isEmpty);
    });
  });

  testWidgets('the profile screen edits and saves all three', (tester) async {
    final accounts = AccountsProvider();
    await tester.binding.setSurfaceSize(const Size(420, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: accounts,
      child: MaterialApp(theme: meridianTheme(Brightness.dark), home: const ProfileScreen()),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Your name'), 'Vishwa');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CHF · Swiss franc').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food'));
    await tester.tap(find.text('Museums'));
    await tester.pump();
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    expect(accounts.profile!.fullName, 'Vishwa');
    expect(accounts.profile!.defaultCurrency, 'CHF');
    expect(accounts.interests, unorderedEquals(['restaurant', 'museum']));
    expect(find.text('Profile saved'), findsOneWidget);
  });
}
