// Owner: Sanjay. The SOS screen (REQ-5.1–5.4, SRS 5.2): helplines first,
// the disclaimer, an email to the user's emergency contact, then the
// hospitals and police nearest to the user. Design:
// design/screens/night-07-sos.png. Opened from the SOS button on every
// tab (lib/screens/home_shell.dart).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/emergency_contact.dart';
import '../../theme/meridian_colors.dart';
import '../../theme/meridian_theme.dart';
import '../accounts/accounts_provider.dart';
import 'directions_screen.dart';
import 'emergency_email.dart';
import 'emergency_provider.dart';

/// Opens the phone's dialler on [number] (REQ-5.3). Calls go over the
/// voice network, so this works with no mobile data.
Future<void> callNumber(String number) async {
  await launchUrl(Uri(scheme: 'tel', path: number.replaceAll(' ', '')));
}

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  @override
  void initState() {
    super.initState();
    // After the first frame, so the helplines are on screen before anything loads.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accounts = context.read<AccountsProvider>();
      context.read<EmergencyProvider>().load(accounts.userId);
      if (accounts.profile == null) accounts.loadProfile().catchError((_) {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;
    final emergency = context.watch<EmergencyProvider>();

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 24),
        children: [
          _HelpHeader(helplines: emergency.helplines),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: _EmailContactButton(),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(child: Text('Nearest to you', style: Theme.of(context).textTheme.titleLarge)),
                Text('within 5 km', style: MeridianText.monoData.copyWith(color: colors.inkSoft)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (emergency.usingSavedPosition)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: _StaleLocationNote(recordedAt: emergency.savedPositionTime!),
            ),
          ..._nearbySection(context, emergency),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Nearby places come from OpenStreetMap and may be incomplete or out of date.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _nearbySection(BuildContext context, EmergencyProvider emergency) {
    final text = Theme.of(context).textTheme;

    Widget message(String line) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(line, style: text.bodyMedium),
        );

    switch (emergency.nearbyStatus) {
      case NearbyStatus.loading:
        return [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
        ];
      case NearbyStatus.noLocation:
        return [
          message("We can't find where you are, so we can't list nearby places. "
              'The numbers above still work — call one of them.'),
        ];
      case NearbyStatus.failed:
        return [
          message("Couldn't load nearby places — no signal, or the map service is busy. "
              'The numbers above still work.'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => emergency.load(context.read<AccountsProvider>().userId),
                child: const Text('Try again'),
              ),
            ),
          ),
        ];
      case NearbyStatus.loaded:
        if (emergency.nearby.isEmpty) {
          return [message('No hospitals or police stations are mapped within 5 km. Call one of the numbers above.')];
        }
        // The nearest dozen is plenty in an emergency.
        return [
          for (final nearby in emergency.nearby.take(12))
            _PlaceRow(
              nearby: nearby,
              onRoute: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => DirectionsScreen(
                  from: emergency.position!,
                  place: nearby.place,
                  fromSavedPosition: emergency.usingSavedPosition,
                ),
              )),
            ),
        ];
    }
  }
}

/// The coral top: close, title, the big 112 button and the other helplines.
class _HelpHeader extends StatelessWidget {
  final List<EmergencyContact> helplines;

  const _HelpHeader({required this.helplines});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;
    final text = Theme.of(context).textTheme;
    // 112 is the big button; if the list somehow lacks it, the first number is.
    final main = helplines.firstWhere((h) => h.phoneNumber == '112', orElse: () => helplines.first);
    final others = helplines.where((h) => h != main).toList();

    return Container(
      decoration: BoxDecoration(
        color: colors.coral.withValues(alpha: 0.16),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton.filledTonal(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close),
          ),
          const SizedBox(height: 16),
          Text('Get help', style: text.headlineMedium),
          const SizedBox(height: 16),
          Semantics(
            button: true,
            label: 'Call emergency ${main.phoneNumber}',
            excludeSemantics: true,
            child: Material(
              color: colors.coral,
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => callNumber(main.phoneNumber),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Call emergency', style: text.titleLarge?.copyWith(color: colors.onCoral)),
                      ),
                      Text(main.phoneNumber,
                          style: MeridianText.nowNumber.copyWith(fontSize: 40, color: colors.onCoral)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.6,
            padding: EdgeInsets.zero,
            children: [for (final h in others) _HelplineTile(helpline: h)],
          ),
          const SizedBox(height: 12),
          Text('These numbers work without data.', style: text.bodySmall?.copyWith(color: colors.ink)),
          const SizedBox(height: 16),
          // Required by SRS section 5.2 — kept up here so it is never off screen.
          Text(
            'Meridian is not an emergency dispatch service. In a life-threatening '
            'emergency, also call local services directly.',
            style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _HelplineTile extends StatelessWidget {
  final EmergencyContact helpline;

  const _HelplineTile({required this.helpline});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;

    return Semantics(
      button: true,
      label: 'Call ${helpline.serviceName} ${helpline.phoneNumber}',
      excludeSemantics: true,
      child: Material(
        color: colors.coral.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => callNumber(helpline.phoneNumber),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(helpline.phoneNumber, style: MeridianText.monoHeading.copyWith(color: colors.ink)),
              const SizedBox(height: 2),
              Text(
                helpline.serviceName,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// REQ-5.4: the list is based on a saved position, so say how old it is.
class _StaleLocationNote extends StatelessWidget {
  final DateTime recordedAt;

  const _StaleLocationNote({required this.recordedAt});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 18, color: colors.amberText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Location from ${formatAge(recordedAt, DateTime.now())} — may be out of date',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.amberText),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  final NearbyPlace nearby;
  final VoidCallback onRoute;

  const _PlaceRow({required this.nearby, required this.onRoute});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;
    final place = nearby.place;
    final kind = place.amenityType == 'police' ? 'Police' : 'Hospital';
    final title = placeTitle(place);
    final phone = place.phone;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.line))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
                const SizedBox(height: 2),
                Text(
                  '$kind · ${formatDistance(nearby.distanceMeters)}${phone == null ? ' · no phone listed' : ''}',
                  style: MeridianText.monoData.copyWith(color: colors.inkSoft),
                ),
              ],
            ),
          ),
          IconButton.outlined(
            tooltip: 'Directions to $title',
            onPressed: onRoute,
            icon: const Icon(Icons.near_me_outlined),
          ),
          if (phone != null) ...[
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Call $title',
              style: IconButton.styleFrom(backgroundColor: colors.coral, foregroundColor: colors.onCoral),
              onPressed: () => callNumber(phone),
              icon: const Icon(Icons.call),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Email my emergency contact" (issue #48). Opens the phone's mail app
/// with the message filled in; the user presses Send. With no contact
/// saved it asks for one first.
class _EmailContactButton extends StatelessWidget {
  const _EmailContactButton();

  Future<void> _send(BuildContext context) async {
    final accounts = context.read<AccountsProvider>();
    final emergency = context.read<EmergencyProvider>();
    final messenger = ScaffoldMessenger.of(context);

    var to = emergencyEmailOf(accounts.profile);
    if (to == null) {
      to = await _askForEmail(context, accounts);
      if (to == null) return; // cancelled
    }

    final body = emergencyEmailBody(
      position: emergency.position,
      savedPositionTime: emergency.savedPositionTime,
      now: DateTime.now(),
    );
    final opened = await launchUrl(emergencyEmailUri(to: to, body: body));
    if (!opened) {
      messenger.showSnackBar(const SnackBar(content: Text('No mail app found on this phone. Call one of the numbers above.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final email = emergencyEmailOf(context.watch<AccountsProvider>().profile);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () => _send(context),
          icon: const Icon(Icons.mail_outline),
          label: const Text('Email my emergency contact'),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                email == null ? 'No contact saved yet.' : 'To $email · opens your mail app, you press Send',
                style: text.bodySmall,
              ),
            ),
            TextButton(
              onPressed: () => _askForEmail(context, context.read<AccountsProvider>()),
              child: Text(email == null ? 'Add' : 'Change'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Asks for the contact's address and saves it in the profile. Returns
/// the saved address, or null if the user cancelled or saving failed.
Future<String?> _askForEmail(BuildContext context, AccountsProvider accounts) async {
  final messenger = ScaffoldMessenger.of(context);
  final email = await showDialog<String>(
    context: context,
    builder: (_) => _EmailDialog(initial: emergencyEmailOf(accounts.profile) ?? ''),
  );
  if (email == null) return null;

  final profile = accounts.profile;
  if (profile == null) {
    messenger.showSnackBar(const SnackBar(content: Text("Couldn't load your profile. Check your connection and try again.")));
    return null;
  }
  try {
    await saveEmergencyEmail(profile, email);
    await accounts.loadProfile();
    return email.trim();
  } catch (_) {
    messenger.showSnackBar(const SnackBar(content: Text("Couldn't save the contact. Check your connection and try again.")));
    return null;
  }
}

class _EmailDialog extends StatefulWidget {
  final String initial;

  const _EmailDialog({required this.initial});

  @override
  State<_EmailDialog> createState() => _EmailDialogState();
}

class _EmailDialogState extends State<_EmailDialog> {
  late final _controller = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (!looksLikeEmail(_controller.text)) {
      setState(() => _error = 'Enter an email address, like name@example.com');
      return;
    }
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Emergency contact'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(labelText: 'Their email address', errorText: _error),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
