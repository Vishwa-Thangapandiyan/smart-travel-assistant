import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_travel_assistant/dev/app_config.dart';
import 'package:smart_travel_assistant/dev/fake_data.dart';
import 'package:smart_travel_assistant/features/accounts/accounts_provider.dart';
import 'package:smart_travel_assistant/features/budget/budget_provider.dart';
import 'package:smart_travel_assistant/features/budget/budget_screen.dart';
import 'package:smart_travel_assistant/features/budget/budget_store.dart';
import 'package:smart_travel_assistant/models/budget.dart';
import 'package:smart_travel_assistant/models/expense.dart';
import 'package:smart_travel_assistant/theme/meridian_theme.dart';

class DelayedStore extends MemoryBudgetStore {
  final first = Completer<List<Budget>>();
  @override
  Future<List<Budget>> budgets(String tripId) =>
      tripId == 'old' ? first.future : super.budgets(tripId);
}

class FailingStore extends MemoryBudgetStore {
  bool failRead = false;
  bool failWrite = false;
  @override
  Future<List<Expense>> expenses(String tripId) async {
    if (failRead) throw StateError('offline');
    return super.expenses(tripId);
  }

  @override
  Future<void> saveExpense(Expense expense) async {
    if (failWrite) throw StateError('offline');
    await super.saveExpense(expense);
  }
}

void main() {
  test(
      'amount validation rejects invalid, negative, infinite and overprecision input',
      () {
    for (final value in [
      '',
      '-1',
      'NaN',
      'Infinity',
      '1.234',
      '1e3',
      '1000000001',
      '0'
    ]) {
      expect(validateAmount(value), isNotNull, reason: value);
    }
    expect(validateAmount('0', allowZero: true), isNull);
    expect(validateAmount(' 12.34 '), isNull);
  });

  test(
      'save, edit and delete recalculate balances and warnings without rounding drift',
      () async {
    final provider = BudgetProvider(store: MemoryBudgetStore());
    addTearDown(provider.dispose);
    await provider.load('a');
    await provider.saveAllocations({'Food': 1, 'Transport': 0});
    await provider.saveExpense(
        category: 'Food', amount: .1, date: DateTime(2026, 11, 20));
    await provider.saveExpense(
        category: 'Food', amount: .2, date: DateTime(2026, 11, 20));
    expect(provider.spent('Food'), .3);
    expect(provider.remaining('Food'), .7);
    expect(provider.warning('Food'), isFalse);
    await provider.saveExpense(
        id: provider.expenses.first.id,
        category: 'Food',
        amount: .7,
        date: DateTime(2026, 11, 21));
    expect(provider.spent('Food'), .9);
    expect(provider.warning('Food'), isTrue);
    await provider.deleteExpense(provider.expenses.first.id);
    expect(provider.spent('Food'), .2);
    expect(provider.warning('Food'), isFalse);
    await provider.saveExpense(
        category: 'Transport', amount: 2, date: DateTime(2026, 11, 20));
    expect(provider.fraction('Transport'), 0);
    expect(provider.warning('Transport'), isTrue);
    expect(provider.remaining('Transport'), -2);
    expect(provider.totalRemaining, -1.2);
    await provider.load('b');
    expect(provider.totalSpent, 0);
    await provider.load('a');
    expect(provider.totalSpent, 2.2);
  });

  test('warning begins at exactly 90 percent and empty budgets do not warn',
      () async {
    final provider = BudgetProvider(store: MemoryBudgetStore());
    addTearDown(provider.dispose);
    await provider.load('a');
    expect(provider.warning('Food'), isFalse);
    expect(provider.fraction('Food'), 0);
    await provider.saveAllocations({'Food': 100});
    await provider.saveExpense(
        category: 'Food', amount: 89.99, date: DateTime(2026));
    expect(provider.warning('Food'), isFalse);
    await provider.saveExpense(
        category: 'Food', amount: .01, date: DateTime(2026));
    expect(provider.warning('Food'), isTrue);
    await provider.saveExpense(
        category: 'Food', amount: 11, date: DateTime(2026));
    expect(provider.remaining('Food'), -1);
  });

  test('a slow old trip cannot overwrite a newer selection', () async {
    final store = DelayedStore();
    final provider = BudgetProvider(store: store);
    addTearDown(provider.dispose);
    final old = provider.load('old');
    await provider.load('new');
    store.first.complete([
      const Budget(
          id: 'old', tripId: 'old', category: 'Food', allocatedAmount: 99)
    ]);
    await old;
    expect(provider.tripId, 'new');
    expect(provider.totalAllocated, 0);
    expect(provider.loading, isFalse);
  });

  test('read and write failures preserve retry and release saving state',
      () async {
    final store = FailingStore();
    final provider = BudgetProvider(store: store);
    addTearDown(provider.dispose);
    await provider.load('a');
    store.failWrite = true;
    await expectLater(
        provider.saveExpense(category: 'Food', amount: 1, date: DateTime(2026)),
        throwsStateError);
    expect(provider.saving, isFalse);
    expect(provider.totalSpent, 0);
    store.failWrite = false;
    await provider.load('a');
    store.failRead = true;
    await expectLater(
        provider.saveExpense(category: 'Food', amount: 1, date: DateTime(2026)),
        throwsStateError);
    expect(provider.error, isNotNull);
    expect(provider.saving, isFalse);
    store.failRead = false;
    await provider.load('a');
    expect(provider.totalSpent, 1);
    expect(provider.expenses, hasLength(1));
    expect(provider.error, isNull);
  });

  testWidgets('expense form validates, saves and updates the displayed balance',
      (tester) async {
    debugUseFakeData = true;
    resetFakeTrips();
    addTearDown(() => debugUseFakeData = null);
    final budget = BudgetProvider(store: MemoryBudgetStore());
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AccountsProvider()),
          ChangeNotifierProvider.value(value: budget),
        ],
        child: MaterialApp(
            theme: meridianTheme(Brightness.dark),
            home: const Scaffold(body: BudgetScreen()))));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Set category budgets'));
    await tester.tap(find.text('Set category budgets'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Food allocation'), '100');
    await tester.tap(find.text('Save budgets'));
    await tester.pumpAndSettle();
    expect(budget.allocated('Food'), 100);
    await tester.ensureVisible(find.text('Log an expense'));
    await tester.tap(find.text('Log an expense'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a positive amount, with up to two decimal places.'),
        findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '90');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Description (optional)'), 'Lunch');
    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();
    expect(budget.totalRemaining, 10);
    expect(budget.expenses.single.description, 'Lunch');
    await tester.scrollUntilVisible(find.text('Food'), -250);
    await tester.pumpAndSettle();
    expect(find.text('90% spent · nearing your limit'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    budget.dispose();
  });
}
