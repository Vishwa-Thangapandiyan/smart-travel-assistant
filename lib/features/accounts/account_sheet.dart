// Owner: Vishwa. The account sheet opened from the Trips header: who is
// signed in, and Sign out. The profile screen (issue #7) grows from here.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dev/app_config.dart';
import '../../theme/meridian_colors.dart';
import '../itinerary/itinerary_provider.dart';
import 'accounts_provider.dart';

Future<void> showAccountSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final colors = Theme.of(context).extension<MeridianColors>()!;
      final text = Theme.of(context).textTheme;
      final accounts = context.read<AccountsProvider>();

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
