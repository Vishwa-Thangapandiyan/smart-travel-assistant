// Owner: Vishwa. The signed-in user and their profile. Registered in
// lib/main.dart; sign-in and the profile arrive with issues #6–#7.

import 'package:flutter/foundation.dart';

import '../../dev/app_config.dart';
import '../../dev/fake_data.dart';
import '../../services/supabase_service.dart';

class AccountsProvider extends ChangeNotifier {
  /// Null when nobody is signed in. In fake data mode it is the demo user.
  String? get userId {
    if (useFakeData) return demoUserId;
    return supabaseClient.auth.currentUser?.id;
  }
}
