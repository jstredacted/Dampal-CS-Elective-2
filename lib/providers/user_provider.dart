import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import 'supabase_provider.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseProvider).auth);
});

// Listens to Supabase for sign-in and sign-out events.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authChanges();
});

// The signed-in user, or null when nobody is signed in.
// Watching authStateProvider makes this update after every sign-in/out.
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(authServiceProvider).currentUser;
});
