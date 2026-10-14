// Owner: Vishwa. The one shared handle on Supabase, initialised in
// lib/main.dart. Every service imports this instead of calling
// Supabase.instance.client directly. Not available in fake data mode.

import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient get supabaseClient => Supabase.instance.client;
