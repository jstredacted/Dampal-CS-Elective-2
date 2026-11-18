import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/user_provider.dart';

// The avatar menu in the app bar: shows who is signed in and their role,
// and lets them sign out.
class AccountButton extends ConsumerWidget {
  const AccountButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(profileProvider).value;
    if (user == null) return const SizedBox.shrink();

    final name = profile?.fullName ?? user.email ?? 'Account';
    final role = profile?.isAdmin == true ? 'Admin' : 'Customer';
    final provider = user.appMetadata['provider'] as String? ?? 'email';

    return PopupMenuButton<String>(
      tooltip: 'Account',
      icon: CircleAvatar(
        radius: 16,
        child: Text(name.isEmpty ? '?' : name[0].toUpperCase()),
      ),
      onSelected: (value) async {
        if (value != 'signOut') return;
        final messenger = ScaffoldMessenger.of(context);
        // Close any open screens so the sign-in page is shown cleanly.
        Navigator.of(context).popUntil((route) => route.isFirst);
        await ref.read(authServiceProvider).signOut();
        messenger.showSnackBar(const SnackBar(content: Text('Signed out')));
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Text('$name · $role\n${user.email ?? ''} ($provider)'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'signOut',
          child: ListTile(
            leading: Icon(Icons.logout),
            title: Text('Sign out'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
