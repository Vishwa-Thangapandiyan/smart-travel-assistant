// Owner: Sanjay. Which trips are saved on this phone, and which are
// downloading right now, for DownloadTripButton (REQ-4.3). Registered in
// lib/main.dart.

import 'package:flutter/foundation.dart';

import '../../services/offline_service.dart' as offline;

class OfflineProvider extends ChangeNotifier {
  final _downloaded = <String>{};
  final _downloading = <String>{};

  bool isDownloaded(String tripId) => _downloaded.contains(tripId);
  bool isDownloading(String tripId) => _downloading.contains(tripId);

  /// Looks in Hive once, so the button shows "Downloaded ✓" straight away.
  Future<void> check(String tripId) async {
    if (await offline.isDownloaded(tripId)) {
      _downloaded.add(tripId);
      notifyListeners();
    }
  }

  /// False if the download failed (usually no connection).
  Future<bool> download(String tripId) async {
    _downloading.add(tripId);
    notifyListeners();
    try {
      await offline.downloadTrip(tripId);
      _downloaded.add(tripId);
      return true;
    } catch (_) {
      return false;
    } finally {
      _downloading.remove(tripId);
      notifyListeners();
    }
  }
}
