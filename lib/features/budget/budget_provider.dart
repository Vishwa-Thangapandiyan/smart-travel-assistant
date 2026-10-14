// Owner: Santhosh. Holds raw rows; every balance is calculated on read.
import 'package:flutter/foundation.dart';

import '../../models/budget.dart';
import '../../models/expense.dart';
import 'budget_store.dart';

class BudgetProvider extends ChangeNotifier {
  final BudgetStore? _providedStore;
  BudgetProvider({BudgetStore? store}) : _providedStore = store;
  BudgetStore get _store => _providedStore ?? defaultBudgetStore();

  String? _tripId;
  String? get tripId => _tripId;
  List<Budget> _budgets = [];
  List<Expense> _expenses = [];
  List<Expense> get expenses => List.unmodifiable(_expenses);
  bool loading = false;
  bool saving = false;
  String? error;
  int _request = 0;
  bool _disposed = false;

  List<String> get categories => {
        ...budgetCategories,
        ..._budgets.map((b) => b.category),
        ..._expenses.map((e) => e.category),
      }.toList();

  double allocated(String category) =>
      _budgets
          .where((b) => b.category == category)
          .fold<int>(0, (sum, b) => sum + moneyUnits(b.allocatedAmount)) /
      100;
  double spent(String category) =>
      _expenses
          .where((e) => e.category == category)
          .fold<int>(0, (sum, e) => sum + moneyUnits(e.amount)) /
      100;
  double remaining(String category) =>
      (moneyUnits(allocated(category)) - moneyUnits(spent(category))) / 100;
  double get totalAllocated =>
      _budgets.fold<int>(0, (sum, b) => sum + moneyUnits(b.allocatedAmount)) /
      100;
  double get totalSpent =>
      _expenses.fold<int>(0, (sum, e) => sum + moneyUnits(e.amount)) / 100;
  double get totalRemaining =>
      (moneyUnits(totalAllocated) - moneyUnits(totalSpent)) / 100;
  double fraction(String category) =>
      allocated(category) <= 0 ? 0 : spent(category) / allocated(category);
  bool warning(String category) {
    final limit = moneyUnits(allocated(category));
    final used = moneyUnits(spent(category));
    if (limit == 0) return used > 0;
    return used * 10 >= limit * 9;
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  void clear() {
    _request++;
    _tripId = null;
    _budgets = [];
    _expenses = [];
    loading = false;
    error = null;
    _changed();
  }

  Future<void> load(String id) async {
    final request = ++_request;
    if (_tripId != id) {
      _budgets = [];
      _expenses = [];
    }
    _tripId = id;
    loading = true;
    error = null;
    _changed();
    try {
      final rows = await Future.wait([_store.budgets(id), _store.expenses(id)]);
      if (_disposed || request != _request) return;
      _budgets = (rows[0] as List<Budget>);
      _expenses = (rows[1] as List<Expense>)
        ..sort((a, b) => b.spentOn.compareTo(a.spentOn));
    } catch (_) {
      if (_disposed || request != _request) return;
      error = 'Couldn’t load this budget. Check your connection and retry.';
    } finally {
      if (!_disposed && request == _request) {
        loading = false;
        _changed();
      }
    }
  }

  Future<void> _write(Future<void> Function(String) operation) async {
    final id = _tripId;
    if (id == null || loading || saving || error != null) {
      throw StateError('Load a trip budget before saving.');
    }
    saving = true;
    _changed();
    try {
      await operation(id);
      if (!_disposed && _tripId == id) await load(id);
      if (error != null) {
        throw StateError(
            'Saved, but the latest balance could not be loaded. Retry before making another change.');
      }
    } catch (_) {
      if (!_disposed && _tripId == id) {
        error ??=
            'Couldn’t confirm the change. Reload the budget before retrying.';
      }
      rethrow;
    } finally {
      saving = false;
      _changed();
    }
  }

  Future<void> saveAllocations(Map<String, double> allocations) {
    if (allocations.isEmpty ||
        allocations.entries.any((e) =>
            e.key.trim().isEmpty ||
            validateAmount(e.value.toStringAsFixed(2), allowZero: true) !=
                null ||
            !e.value.isFinite)) {
      throw ArgumentError('Budget amounts must be finite and non-negative.');
    }
    return _write((id) => _store.saveBudgets(id, allocations));
  }

  Future<void> saveExpense(
      {String id = '',
      required String category,
      required double amount,
      required DateTime date,
      String? description}) {
    if (!categories.contains(category) ||
        !amount.isFinite ||
        amount <= 0 ||
        amount > 1000000000) {
      throw ArgumentError('Choose a category and a positive amount.');
    }
    if (id.isNotEmpty && !_expenses.any((e) => e.id == id)) {
      throw ArgumentError('Expense not found.');
    }
    return _write((trip) => _store.saveExpense(Expense(
        id: id,
        tripId: trip,
        category: category,
        amount: moneyUnits(amount) / 100,
        spentOn: DateTime(date.year, date.month, date.day),
        description:
            description?.trim().isEmpty == true ? null : description?.trim())));
  }

  Future<void> deleteExpense(String id) {
    if (!_expenses.any((e) => e.id == id)) {
      throw ArgumentError('Expense not found.');
    }
    return _write((trip) => _store.deleteExpense(trip, id));
  }

  @override
  void dispose() {
    _disposed = true;
    _request++;
    super.dispose();
  }
}
