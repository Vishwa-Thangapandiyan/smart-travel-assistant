// Budget-owned persistence. Shared models and database tables stay unchanged.
import 'package:intl/intl.dart';

import '../../dev/app_config.dart';
import '../../dev/fake_data.dart';
import '../../models/budget.dart';
import '../../models/expense.dart';
import '../../services/supabase_service.dart';

const budgetCategories = ['Food', 'Transport', 'Stay', 'Activities', 'Other'];

// Calculate money in whole paise to avoid floating-point rounding in balances.
int moneyUnits(double amount) => (amount * 100).round();

String? validateAmount(String text, {bool allowZero = false}) {
  final value = double.tryParse(text.trim());
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text.trim()) ||
      value == null ||
      !value.isFinite ||
      value > 1000000000 ||
      (allowZero ? value < 0 : value <= 0)) {
    return allowZero
        ? 'Enter zero or a positive amount, with up to two decimal places.'
        : 'Enter a positive amount, with up to two decimal places.';
  }
  return null;
}

abstract class BudgetStore {
  Future<List<Budget>> budgets(String tripId);
  Future<List<Expense>> expenses(String tripId);
  Future<void> saveBudgets(String tripId, Map<String, double> allocations);
  Future<void> saveExpense(Expense expense);
  Future<void> deleteExpense(String tripId, String id);
}

class SupabaseBudgetStore implements BudgetStore {
  @override
  Future<List<Budget>> budgets(String tripId) async {
    final rows =
        await supabaseClient.from('budgets').select().eq('trip_id', tripId);
    return rows.map(Budget.fromJson).toList();
  }

  @override
  Future<List<Expense>> expenses(String tripId) async {
    final rows = await supabaseClient
        .from('expenses')
        .select()
        .eq('trip_id', tripId)
        .order('spent_on', ascending: false);
    return rows.map(Expense.fromJson).toList();
  }

  @override
  Future<void> saveBudgets(
      String tripId, Map<String, double> allocations) async {
    await supabaseClient.from('budgets').upsert([
      for (final entry in allocations.entries)
        {
          'trip_id': tripId,
          'category': entry.key,
          'allocated_amount': entry.value
        },
    ], onConflict: 'trip_id,category');
  }

  @override
  Future<void> saveExpense(Expense expense) async {
    final row = expense.toJson()..remove('id');
    if (expense.id.isEmpty) {
      await supabaseClient.from('expenses').insert(row);
    } else {
      await supabaseClient
          .from('expenses')
          .update(row)
          .eq('trip_id', expense.tripId)
          .eq('id', expense.id);
    }
  }

  @override
  Future<void> deleteExpense(String tripId, String id) async {
    await supabaseClient
        .from('expenses')
        .delete()
        .eq('trip_id', tripId)
        .eq('id', id);
  }
}

class MemoryBudgetStore implements BudgetStore {
  final List<Budget> budgetRows;
  final List<Expense> expenseRows;
  int _nextId = 0;

  MemoryBudgetStore(
      {List<Budget> budgets = const [], List<Expense> expenses = const []})
      : budgetRows = [...budgets],
        expenseRows = [...expenses];

  @override
  Future<List<Budget>> budgets(String tripId) async =>
      budgetRows.where((b) => b.tripId == tripId).toList();

  @override
  Future<List<Expense>> expenses(String tripId) async =>
      expenseRows.where((e) => e.tripId == tripId).toList();

  @override
  Future<void> saveBudgets(
      String tripId, Map<String, double> allocations) async {
    for (final entry in allocations.entries) {
      budgetRows
          .removeWhere((b) => b.tripId == tripId && b.category == entry.key);
      budgetRows.add(Budget(
          id: 'budget-${_nextId++}',
          tripId: tripId,
          category: entry.key,
          allocatedAmount: entry.value));
    }
  }

  @override
  Future<void> saveExpense(Expense expense) async {
    expenseRows
        .removeWhere((e) => e.tripId == expense.tripId && e.id == expense.id);
    expenseRows.add(Expense(
        id: expense.id.isEmpty ? 'expense-${_nextId++}' : expense.id,
        tripId: expense.tripId,
        category: expense.category,
        amount: expense.amount,
        spentOn: expense.spentOn,
        description: expense.description));
  }

  @override
  Future<void> deleteExpense(String tripId, String id) async {
    expenseRows.removeWhere((e) => e.tripId == tripId && e.id == id);
  }
}

final _demoStore = MemoryBudgetStore(
  budgets: [
    for (final entry in {
      'Food': 4000.0,
      'Transport': 3000.0,
      'Stay': 6000.0,
      'Activities': 2000.0
    }.entries)
      Budget(
          id: 'demo-${entry.key}',
          tripId: demoTrip.id,
          category: entry.key,
          allocatedAmount: entry.value),
  ],
  expenses: [
    for (final entry in {
      'Food': 3120.0,
      'Transport': 2790.0,
      'Stay': 4500.0,
      'Activities': 650.0
    }.entries)
      Expense(
          id: 'demo-${entry.key}',
          tripId: demoTrip.id,
          category: entry.key,
          amount: entry.value,
          spentOn: demoTrip.startDate,
          description: 'Demo ${entry.key.toLowerCase()} expense'),
  ],
);

BudgetStore defaultBudgetStore() =>
    useFakeData ? _demoStore : SupabaseBudgetStore();

String money(double amount) => NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: moneyUnits(amount) % 100 == 0 ? 0 : 2)
    .format(amount);
