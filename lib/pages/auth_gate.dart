import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/user_provider.dart';
import '../utils/errors.dart';
import '../widgets/message_view.dart';
import 'login_page.dart';
import 'products_page.dart';

// The first screen. Signed-out users only ever see the login page.
// Signed-in users see the shop once their profile (and role) has loaded.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const LoginPage();

    final profileAsync = ref.watch(profileProvider);
    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return _AccountProblem(
            title: 'Your account has no profile yet.',
            detail: 'Try again in a moment, or sign out and back in.',
          );
        }
        // ProductsPage shows admin or customer controls based on the role.
        return const ProductsPage();
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => _AccountProblem(
        title: 'Could not load your account.',
        detail: friendlyError(error),
      ),
    );
  }
}

class _AccountProblem extends ConsumerWidget {
  const _AccountProblem({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MessageView(
            icon: Icons.person_off_outlined,
            title: title,
            detail: detail,
            buttonLabel: 'Try again',
            onPressed: () => ref.invalidate(profileProvider),
          ),
          TextButton(
            onPressed: () => ref.read(authServiceProvider).signOut(),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
