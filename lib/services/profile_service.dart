import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

class ProfileService {
  ProfileService(this._client);

  final SupabaseClient _client;

  // RLS only lets a customer read their own row, so this is the only
  // profile a customer can load.
  Future<Profile?> fetchProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select('id, email, firstname, lastname, roles(role)')
        .eq('id', userId)
        .maybeSingle();
    return data == null ? null : Profile.fromMap(data);
  }
}
