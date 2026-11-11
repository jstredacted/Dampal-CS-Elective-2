import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pages/login_page.dart';
import '../providers/user_provider.dart';

// Shows "Sign in" when signed out, and the user's email + Sign out when in.
class AccountButton extends ConsumerWidget {
  const AccountButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return TextButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        ),
        icon: const Icon(Icons.login),
        label: const Text('Sign in'),
      );
    }

    // GitHub users have their name saved in userMetadata by Supabase.
    final name =
        user.userMetadata?['user_name'] as String? ?? user.email ?? 'Account';
    final provider = user.appMetadata['provider'] as String? ?? 'email';

    return PopupMenuButton<String>(
      tooltip: 'Account',
      icon: CircleAvatar(
        radius: 16,
        child: Text(name.isEmpty ? '?' : name[0].toUpperCase()),
      ),
      onSelected: (value) async {
        if (value != 'signOut') return;
        await ref.read(authServiceProvider).signOut();
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Signed out')));
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Text('$name\nSigned in with $provider'),
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
