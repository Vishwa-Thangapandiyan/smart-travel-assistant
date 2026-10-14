// Owner: Sanjay. "Download for offline" for one trip (REQ-4.3). Once
// saved it reads "Downloaded ✓"; tapping it again takes a fresh copy.
// Other screens place it with DownloadTripButton(tripId: ...) — they
// don't need to edit it.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/meridian_colors.dart';
import 'offline_provider.dart';

class DownloadTripButton extends StatefulWidget {
  final String tripId;

  const DownloadTripButton({super.key, required this.tripId});

  @override
  State<DownloadTripButton> createState() => _DownloadTripButtonState();
}

class _DownloadTripButtonState extends State<DownloadTripButton> {
  @override
  void initState() {
    super.initState();
    context.read<OfflineProvider>().check(widget.tripId);
  }

  Future<void> _download() async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await context.read<OfflineProvider>().download(widget.tripId);
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't download the trip. Check your connection and try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MeridianColors>()!;
    final offline = context.watch<OfflineProvider>();

    if (offline.isDownloading(widget.tripId)) {
      return const OutlinedButton(
        onPressed: null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 10),
            Text('Downloading…'),
          ],
        ),
      );
    }

    if (offline.isDownloaded(widget.tripId)) {
      return Tooltip(
        message: 'Saved on this phone. Tap to download a fresh copy.',
        child: OutlinedButton(
          onPressed: _download,
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.green,
            side: BorderSide(color: colors.green),
          ),
          child: const Text('Downloaded ✓'),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: _download,
      icon: const Icon(Icons.download_outlined),
      label: const Text('Download for offline'),
    );
  }
}
