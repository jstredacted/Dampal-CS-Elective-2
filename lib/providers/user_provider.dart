import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import 'supabase_provider.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseProvider).auth);
});

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(ref.watch(supabaseProvider));
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

// The signed-in user's profile row, including their role.
// select() means it only reloads when a different user signs in, not on
// every token refresh.
final profileProvider = FutureProvider<Profile?>((ref) async {
  final userId = ref.watch(currentUserProvider.select((user) => user?.id));
  if (userId == null) return null;
  return ref.watch(profileServiceProvider).fetchProfile(userId);
});

// Decides which controls the screens show. The database enforces the same
// rule with RLS, so hiding a button is only for a cleaner screen.
final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(profileProvider).value?.isAdmin ?? false;
});
