// Owner: Vishwa. The account sheet opened from the Trips header: who is
// signed in, Edit profile, Day or Night, and Sign out.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dev/app_config.dart';
import '../../theme/meridian_colors.dart';
import '../../theme/theme_provider.dart';
import '../itinerary/itinerary_provider.dart';
import 'accounts_provider.dart';
import 'profile_screen.dart';

Future<void> showAccountSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final colors = Theme.of(context).extension<MeridianColors>()!;
      final text = Theme.of(context).textTheme;
      final accounts = context.read<AccountsProvider>();
      final theme = context.watch<ThemeProvider>();

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Signed in as', style: text.bodySmall),
              Text(accounts.email ?? '', style: text.titleLarge),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
                },
                icon: const Icon(Icons.person_outline),
                label: const Text('Edit profile'),
              ),
              const SizedBox(height: 20),
              Text('Look', style: text.bodySmall),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_outlined), label: Text('Phone')),
                    ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined), label: Text('Day')),
                    ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Night')),
                  ],
                  selected: {theme.mode},
                  showSelectedIcon: false,
                  onSelectionChanged: (picked) => theme.setMode(picked.single),
                ),
              ),
              const SizedBox(height: 20),
              if (useFakeData)
                Text('Demo mode: no account, nothing is saved after the app closes.',
                    style: text.bodyMedium?.copyWith(color: colors.inkSoft))
              else
                OutlinedButton.icon(
                  onPressed: () async {
                    final itinerary = context.read<ItineraryProvider>();
                    Navigator.pop(context);
                    // Forget this user's trips so the next person never sees them.
                    itinerary.clear();
                    await accounts.signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
            ],
          ),
        ),
      );
    },
  );
}
