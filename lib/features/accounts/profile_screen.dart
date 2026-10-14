// Owner: Vishwa. View and edit the profile: name, default currency and
// interests (REQ-1.2, REQ-1.3), read from and saved to `profiles`
// through UserProfile. Opened from the Account sheet.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/meridian_colors.dart';
import '../../theme/meridian_theme.dart';
import '../recommendations/place_categories.dart';
import 'accounts_provider.dart';

// A short list on purpose: the currencies an Indian traveller is most
// likely to need. The column takes any code, so this can grow.
const currencies = {
  'INR': 'Indian rupee',
  'USD': 'US dollar',
  'EUR': 'Euro',
  'GBP': 'British pound',
  'CHF': 'Swiss franc',
  'AED': 'UAE dirham',
  'SGD': 'Singapore dollar',
  'THB': 'Thai baht',
  'JPY': 'Japanese yen',
  'AUD': 'Australian dollar',
};

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  String _currency = 'INR';
  final Set<String> _interests = {};
  bool _loaded = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // After the first frame: the provider notifies listeners when it loads,
    // and that isn't allowed while this screen is still being built.
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final accounts = context.read<AccountsProvider>();
    try {
      await accounts.loadProfile();
    } on Exception {
      if (mounted) setState(() => _error = 'Couldn\'t load your profile. Check your connection.');
      return;
    }
    final profile = accounts.profile;
    if (!mounted || profile == null) return;
    setState(() {
      _name.text = profile.fullName ?? '';
      // An unknown code saved elsewhere still shows, rather than breaking the dropdown.
      _currency = profile.defaultCurrency;
      _interests.addAll(accounts.interests);
      _loaded = true;
    });
  }

  Future<void> _save() async {
    final accounts = context.read<AccountsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await accounts.saveProfile(fullName: _name.text, defaultCurrency: _currency, interests: _interests.toList());
      messenger.showSnackBar(const SnackBar(content: Text('Profile saved')));
    } on Exception {
      setState(() => _error = 'Couldn\'t save your profile. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;
    final text = Theme.of(context).textTheme;
    final email = context.watch<AccountsProvider>().email;
    final currencyCodes = {...currencies.keys, _currency};

    return Scaffold(
      appBar: AppBar(title: const Text('Your profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('SIGNED IN AS', style: MeridianText.monoData.copyWith(color: colors.inkSoft)),
            Text(email ?? '', style: text.bodyLarge),
            const SizedBox(height: 24),
            if (!_loaded && _error == null) const Center(child: CircularProgressIndicator()),
            if (_error != null) ...[
              Text(_error!, style: text.bodyMedium?.copyWith(color: colors.coral)),
              const SizedBox(height: 12),
            ],
            if (_loaded) ...[
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Your name'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _currency,
                isExpanded: true, // long names shorten with "…" instead of overflowing
                decoration: const InputDecoration(labelText: 'Default currency'),
                items: [
                  for (final code in currencyCodes)
                    DropdownMenuItem(
                      value: code,
                      child: Text('$code · ${currencies[code] ?? code}', overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (code) => setState(() => _currency = code ?? _currency),
              ),
              const SizedBox(height: 6),
              Text('Budgets for new trips start in this currency.', style: text.bodySmall),
              const SizedBox(height: 24),
              Text('Interests', style: text.titleLarge),
              const SizedBox(height: 4),
              Text('Kept on your profile. They don\'t plan or change your trips.', style: text.bodySmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in placeCategories.entries)
                    FilterChip(
                      label: Text(entry.value),
                      selected: _interests.contains(entry.key),
                      onSelected: (on) => setState(() => on ? _interests.add(entry.key) : _interests.remove(entry.key)),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save profile'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
