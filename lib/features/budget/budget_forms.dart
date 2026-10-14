import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/expense.dart';
import 'budget_provider.dart';
import 'budget_store.dart';

Future<void> showBudgetSetup(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
        value: context.read<BudgetProvider>(), child: const BudgetSetupForm()));

Future<void> showExpenseForm(BuildContext context, {Expense? expense}) =>
    showDialog<void>(
        context: context,
        builder: (_) => ChangeNotifierProvider.value(
            value: context.read<BudgetProvider>(),
            child: ExpenseForm(expense: expense)));

class BudgetSetupForm extends StatefulWidget {
  const BudgetSetupForm({super.key});
  @override
  State<BudgetSetupForm> createState() => _BudgetSetupFormState();
}

class _BudgetSetupFormState extends State<BudgetSetupForm> {
  final _form = GlobalKey<FormState>();
  final _amounts = <String, TextEditingController>{};
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final budget = context.read<BudgetProvider>();
    for (final category in budget.categories) {
      _amounts[category] = TextEditingController(
          text: budget.allocated(category).toStringAsFixed(2));
    }
  }

  @override
  void dispose() {
    for (final controller in _amounts.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<BudgetProvider>().saveAllocations({
        for (final entry in _amounts.entries)
          entry.key: double.parse(entry.value.text.trim()),
      });
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Couldn’t finish saving. Close this form and retry loading the budget before trying again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_busy,
        child: AlertDialog(
          title: const Text('Set category budgets'),
          content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                  child: Form(
                key: _form,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text(
                      'Allocate money for this trip. Zero means no money allocated.'),
                  for (final entry in _amounts.entries)
                    Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: TextFormField(
                          controller: entry.value,
                          enabled: !_busy,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                              labelText: '${entry.key} allocation',
                              prefixText: '₹ '),
                          validator: (value) =>
                              validateAmount(value ?? '', allowZero: true),
                        )),
                  if (_error != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(_error!)),
                ]),
              ))),
          actions: [
            TextButton(
                onPressed: _busy ? null : () => Navigator.pop(context),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: _busy || _error != null ? null : _save,
                child: Text(_busy ? 'Saving…' : 'Save budgets')),
          ],
        ),
      );
}

class ExpenseForm extends StatefulWidget {
  final Expense? expense;
  const ExpenseForm({super.key, this.expense});
  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  late String _category;
  late DateTime _date;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _category =
        expense?.category ?? context.read<BudgetProvider>().categories.first;
    _date = expense?.spentOn ?? DateTime.now();
    _amount.text = expense?.amount.toStringAsFixed(2) ?? '';
    _description.text = expense?.description ?? '';
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<BudgetProvider>().saveExpense(
          id: widget.expense?.id ?? '',
          category: _category,
          amount: double.parse(_amount.text.trim()),
          date: _date,
          description: _description.text);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Couldn’t finish saving. Close this form and retry loading the budget before trying again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_busy,
        child: AlertDialog(
          title:
              Text(widget.expense == null ? 'Log an expense' : 'Edit expense'),
          content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                  child: Form(
                key: _form,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: [
                      for (final category
                          in context.read<BudgetProvider>().categories)
                        DropdownMenuItem(value: category, child: Text(category))
                    ],
                    onChanged: _busy
                        ? null
                        : (value) => setState(() => _category = value!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amount,
                    enabled: !_busy,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Amount', prefixText: '₹ '),
                    validator: (value) => validateAmount(value ?? ''),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                          'Date: ${DateFormat('d MMM yyyy').format(_date)}'),
                      onPressed: _busy
                          ? null
                          : () async {
                              final date = await showDatePicker(
                                  context: context,
                                  initialDate: _date,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100));
                              if (date != null && mounted) {
                                setState(() => _date = date);
                              }
                            }),
                  const SizedBox(height: 16),
                  TextFormField(
                      controller: _description,
                      enabled: !_busy,
                      maxLength: 500,
                      decoration: const InputDecoration(
                          labelText: 'Description (optional)'),
                      minLines: 2,
                      maxLines: 3),
                  if (_error != null) Text(_error!),
                ]),
              ))),
          actions: [
            TextButton(
                onPressed: _busy ? null : () => Navigator.pop(context),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: _busy || _error != null ? null : _save,
                child: Text(_busy ? 'Saving…' : 'Save expense')),
          ],
        ),
      );
}
