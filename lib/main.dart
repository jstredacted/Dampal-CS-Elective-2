import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() {
  runApp(const InstagramUiApp());
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return InstagramNavigationShell(
          location: state.matchedLocation,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const InstagramHomeScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) =>
              const InstagramTabScreen(icon: Icons.search, title: 'Search'),
        ),
        GoRoute(
          path: '/create',
          builder: (context, state) => const InstagramTabScreen(
            icon: Icons.add_box_outlined,
            title: 'Create',
          ),
        ),
        GoRoute(
          path: '/reels',
          builder: (context, state) => const InstagramTabScreen(
            icon: Icons.video_collection_outlined,
            title: 'Reels',
          ),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const InstagramTabScreen(
            icon: Icons.account_circle_outlined,
            title: 'Profile',
          ),
        ),
      ],
    ),
  ],
);

class InstagramUiApp extends StatelessWidget {
  const InstagramUiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}

class InstagramHomeScreen extends StatelessWidget {
  const InstagramHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _TopBar(),
        Divider(height: 1, color: Color(0xFFE6E6E6)),
        _UserHeader(),
        Expanded(child: _PostImage()),
        _PostDetails(),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Instagram',
              style: TextStyle(
                color: Color(0xFF111111),
                fontSize: 28,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                letterSpacing: -1,
              ),
            ),
          ),
          const Icon(Icons.favorite_border, size: 28),
          const SizedBox(width: 18),
          Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.chat_bubble_outline, size: 27),
              Positioned(
                top: -5,
                right: -6,
                child: Container(
                  width: 17,
                  height: 17,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF3040),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [
                  Color(0xFFFEDA75),
                  Color(0xFFFA7E1E),
                  Color(0xFFD62976),
                  Color(0xFF962FBF),
                ],
              ),
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(2),
              child: const CircleAvatar(
                backgroundColor: Color(0xFFF1F1F1),
                child: Icon(Icons.person, color: Color(0xFF777777), size: 23),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'username',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          const Icon(Icons.more_vert, size: 26),
        ],
      ),
    );
  }
}

class _PostImage extends StatelessWidget {
  const _PostImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 230),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          stops: [0, 0.26, 0.58, 1],
          colors: [
            Color(0xFFFFD363),
            Color(0xFFFF5B68),
            Color(0xFFD72D87),
            Color(0xFF4F4DA5),
          ],
        ),
      ),
    );
  }
}

class _PostDetails extends StatelessWidget {
  const _PostDetails();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.favorite, color: Color(0xFFFF3040), size: 28),
              SizedBox(width: 15),
              Icon(Icons.chat_bubble_outline, size: 27),
              SizedBox(width: 15),
              Icon(Icons.send_outlined, size: 27),
              Spacer(),
              Icon(Icons.bookmark_border, size: 28),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '10,547 likes',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          const Text.rich(
            TextSpan(
              style: TextStyle(
                color: Color(0xFF202020),
                fontSize: 14,
                height: 1.3,
              ),
              children: [
                TextSpan(
                  text: '@username  ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: 'Lorem ipsum dolor sit amet, consectetur adipiscing.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '#lorem   #ipsum   #dolor   #sit   #amet   #consectetur',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 12,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class InstagramNavigationShell extends StatelessWidget {
  const InstagramNavigationShell({
    required this.location,
    required this.child,
    super.key,
  });

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: child),
            const Divider(height: 1, color: Color(0xFFE6E6E6)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NavigationItem(
                    icon: Icons.home,
                    route: '/',
                    selected: location == '/',
                  ),
                  _NavigationItem(
                    icon: Icons.search,
                    route: '/search',
                    selected: location == '/search',
                  ),
                  _NavigationItem(
                    icon: Icons.add_box_outlined,
                    route: '/create',
                    selected: location == '/create',
                  ),
                  _NavigationItem(
                    icon: Icons.video_collection_outlined,
                    route: '/reels',
                    selected: location == '/reels',
                  ),
                  _NavigationItem(
                    icon: Icons.account_circle_outlined,
                    route: '/profile',
                    selected: location == '/profile',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.route,
    required this.selected,
  });

  final IconData icon;
  final String route;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: ValueKey('navigation-$route'),
      onPressed: () => context.go(route),
      icon: Icon(
        icon,
        size: 29,
        color: selected ? const Color(0xFF111111) : const Color(0xFF777777),
      ),
    );
  }
}

class InstagramTabScreen extends StatelessWidget {
  const InstagramTabScreen({
    required this.icon,
    required this.title,
    super.key,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 72, color: const Color(0xFF777777)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
