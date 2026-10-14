// Owner: Santhosh. Flutter implementation of design/artboards/*-05-budget.html.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../dev/app_config.dart';
import '../../models/expense.dart';
import '../../models/trip.dart';
import '../../services/trip_service.dart';
import '../../theme/meridian_colors.dart';
import '../accounts/accounts_provider.dart';
import 'budget_forms.dart';
import 'budget_provider.dart';
import 'budget_store.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  List<Trip> _trips = [];
  String? _userId;
  String? _tripId;
  String? _tripError;
  bool _loadingTrips = true;
  bool _today = false;
  bool _initialized = false;
  int _request = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = context.watch<AccountsProvider>().userId;
    if (!_initialized || _userId != userId) {
      _initialized = true;
      _userId = userId;
      _request++;
      _trips = [];
      _tripId = null;
      _loadingTrips = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<BudgetProvider>().clear();
        _loadTrips();
      });
    }
  }

  Future<void> _loadTrips() async {
    final request = ++_request;
    final user = _userId;
    if (user == null) {
      setState(() => _loadingTrips = false);
      return;
    }
    setState(() {
      _loadingTrips = true;
      _tripError = null;
    });
    try {
      final trips = await getTrips(user);
      if (!mounted || request != _request) return;
      final id =
          trips.any((t) => t.id == _tripId) ? _tripId : trips.firstOrNull?.id;
      setState(() {
        _trips = trips;
        _tripId = id;
      });
      if (id != null) await context.read<BudgetProvider>().load(id);
    } catch (_) {
      if (mounted && request == _request) {
        setState(() => _tripError =
            'Couldn’t load your trips. Check your connection and retry.');
      }
    } finally {
      if (mounted && request == _request) setState(() => _loadingTrips = false);
    }
  }

  Future<void> _delete(Expense expense) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Delete expense?'),
              content: Text('${expense.category}: ${money(expense.amount)}'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete'))
              ],
            ));
    if (confirmed != true || !mounted) return;
    try {
      await context.read<BudgetProvider>().deleteExpense(expense.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Couldn’t finish deleting. Reload the budget before retrying.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final budget = context.watch<BudgetProvider>();
    final colors = Theme.of(context).extension<MeridianColors>()!;
    final text = Theme.of(context).textTheme;
    final ready = !_loadingTrips &&
        !budget.loading &&
        !budget.saving &&
        budget.error == null &&
        _tripError == null &&
        _tripId != null;
    final categories = budget.categories
      ..sort((a, b) {
        if (budget.warning(a) != budget.warning(b)) {
          return budget.warning(a) ? -1 : 1;
        }
        return budget.categories
            .indexOf(a)
            .compareTo(budget.categories.indexOf(b));
      });
    final now = DateTime.now();
    final expenses = budget.expenses
        .where((e) =>
            !_today ||
            (e.spentOn.year == now.year &&
                e.spentOn.month == now.month &&
                e.spentOn.day == now.day))
        .toList();
    final displayedSpent =
        expenses.fold<int>(0, (sum, e) => sum + moneyUnits(e.amount)) / 100;

    return SafeArea(
        child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: RefreshIndicator(
                  onRefresh: _loadTrips,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 130),
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text('Budget', style: text.headlineLarge)),
                        IconButton(
                            tooltip: 'Refresh budget',
                            onPressed: budget.saving ? null : _loadTrips,
                            icon: const Icon(Icons.refresh))
                      ]),
                      if (useFakeData)
                        Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                                'Demo data · changes last until the app restarts',
                                style: text.bodySmall)),
                      if (_loadingTrips || budget.loading)
                        const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator())),
                      if (_tripError != null || budget.error != null) ...[
                        Text(_tripError ?? budget.error!),
                        TextButton(
                            onPressed: _loadTrips, child: const Text('Retry')),
                      ],
                      if (!_loadingTrips &&
                          _tripError == null &&
                          _trips.isEmpty)
                        const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                                'Create a trip in the Trips tab to start your budget.')),
                      if (_trips.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                            key: ValueKey(_tripId),
                            initialValue: _tripId,
                            isExpanded: true,
                            decoration:
                                const InputDecoration(labelText: 'Trip'),
                            items: [
                              for (final trip in _trips)
                                DropdownMenuItem(
                                    value: trip.id,
                                    child: Text(
                                        '${trip.destination} · ${DateFormat('d MMM').format(trip.startDate)}',
                                        overflow: TextOverflow.ellipsis))
                            ],
                            onChanged: budget.saving || _loadingTrips
                                ? null
                                : (id) {
                                    if (id == null) return;
                                    setState(() => _tripId = id);
                                    context.read<BudgetProvider>().load(id);
                                  }),
                        const SizedBox(height: 28),
                        Text('TRIP BALANCE', style: text.labelMedium),
                        FittedBox(
                            alignment: Alignment.centerLeft,
                            fit: BoxFit.scaleDown,
                            child: Text(money(budget.totalRemaining),
                                style: text.displayLarge?.copyWith(
                                    fontSize: 88,
                                    height: 1.1,
                                    color: budget.totalRemaining < 0
                                        ? colors.coral
                                        : colors.ink))),
                        Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            spacing: 20,
                            children: [
                              Text('left of ${money(budget.totalAllocated)}',
                                  style: text.bodySmall),
                              Text('${money(budget.totalSpent)} spent',
                                  style: text.bodySmall),
                            ]),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                            value: budget.totalAllocated <= 0
                                ? 0
                                : (budget.totalSpent / budget.totalAllocated)
                                    .clamp(0.0, 1.0),
                            backgroundColor: colors.line,
                            color: budget.totalRemaining < 0
                                ? colors.coral
                                : colors.amber,
                            semanticsLabel: 'Trip budget spent'),
                        const SizedBox(height: 12),
                        Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                                onPressed: ready
                                    ? () => showBudgetSetup(context)
                                    : null,
                                icon: const Icon(Icons.tune),
                                label: const Text('Set category budgets'))),
                        for (final category in categories) ...[
                          Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                  color: budget.warning(category)
                                      ? colors.coral.withValues(alpha: .12)
                                      : colors.surface,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                      color: budget.warning(category)
                                          ? colors.coral.withValues(alpha: .4)
                                          : colors.line)),
                              child: Row(children: [
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(category, style: text.titleMedium),
                                      const SizedBox(height: 4),
                                      Text(
                                          '${money(budget.spent(category))} of ${money(budget.allocated(category))}',
                                          style: text.bodySmall),
                                      if (budget.warning(category))
                                        Text(
                                            budget.allocated(category) == 0
                                                ? 'Spending with no allocation'
                                                : budget.spent(category) >
                                                        budget
                                                            .allocated(category)
                                                    ? 'Over budget'
                                                    : '${(budget.fraction(category) * 100).floor()}% spent · nearing your limit',
                                            style: text.bodySmall?.copyWith(
                                                color: colors.coral)),
                                    ])),
                                const SizedBox(width: 12),
                                Text(money(budget.remaining(category)),
                                    style: text.titleLarge?.copyWith(
                                        color: budget.warning(category)
                                            ? colors.coral
                                            : colors.ink))
                              ])),
                        ],
                        const SizedBox(height: 8),
                        Text(
                            "Stops in your plan don't carry prices — only what you log counts here.",
                            style: text.bodySmall),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                            onPressed:
                                ready ? () => showExpenseForm(context) : null,
                            icon: const Icon(Icons.add),
                            label: const Text('Log an expense')),
                        const SizedBox(height: 24),
                        Row(children: [
                          Expanded(
                              child: Text('Expenses', style: text.titleLarge)),
                          SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(
                                    value: false, label: Text('Trip')),
                                ButtonSegment(value: true, label: Text('Today'))
                              ],
                              selected: {
                                _today
                              },
                              onSelectionChanged: (value) =>
                                  setState(() => _today = value.single))
                        ]),
                        const SizedBox(height: 8),
                        Text(
                            '${money(displayedSpent)} · ${_today ? 'today' : 'this trip'}',
                            style: text.bodySmall),
                        if (expenses.isEmpty)
                          const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text('No expenses to show.')),
                        for (final expense in expenses)
                          ListTile(
                              contentPadding: EdgeInsets.zero,
                              title:
                                  Text(expense.description ?? expense.category),
                              subtitle: Text(
                                  '${expense.category} · ${DateFormat('d MMM yyyy').format(expense.spentOn)}'),
                              trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(money(expense.amount)),
                                    PopupMenuButton<String>(
                                        enabled: ready,
                                        tooltip: 'Expense actions',
                                        onSelected: (action) {
                                          if (action == 'edit') {
                                            showExpenseForm(context,
                                                expense: expense);
                                          } else {
                                            _delete(expense);
                                          }
                                        },
                                        itemBuilder: (_) => const [
                                              PopupMenuItem(
                                                  value: 'edit',
                                                  child: Text('Edit')),
                                              PopupMenuItem(
                                                  value: 'delete',
                                                  child: Text('Delete'))
                                            ])
                                  ])),
                      ],
                    ],
                  )),
            )));
  }
}
