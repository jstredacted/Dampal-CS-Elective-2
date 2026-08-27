import 'package:flutter/material.dart';

enum DeviceType { compact, medium, expanded, large }

DeviceType deviceTypeOf(double width) {
  if (width < 600) return DeviceType.compact;
  if (width < 840) return DeviceType.medium;
  if (width < 1200) return DeviceType.expanded;
  return DeviceType.large;
}

class DashboardApp extends StatelessWidget {
  const DashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Responsive Dashboard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3559C7),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F6FA),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _updatesEnabled = true;

  static const _titles = ['Dashboard', 'Settings', 'About', 'Logout'];

  void _selectDestination(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final type = deviceTypeOf(MediaQuery.sizeOf(context).width);
    final showsDrawer = type == DeviceType.compact || type == DeviceType.medium;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF171A21),
        foregroundColor: Colors.white,
        title: Text(_titles[_selectedIndex]),
      ),
      drawer: showsDrawer
          ? DashboardDrawer(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _selectDestination,
            )
          : null,
      body: SafeArea(
        child: Row(
          children: [
            if (!showsDrawer)
              DashboardNavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _selectDestination,
              ),
            Expanded(
              child: DashboardBody(
                type: type,
                title: _titles[_selectedIndex],
                updatesEnabled: _updatesEnabled,
                onUpdatesChanged: (value) {
                  setState(() => _updatesEnabled = value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardDrawer extends StatelessWidget {
  const DashboardDrawer({
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      key: const ValueKey('dashboard-drawer'),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 28),
            Icon(
              Icons.favorite,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 28),
            ...List.generate(
              _navigationLabels.length,
              (index) => ListTile(
                key: ValueKey('drawer-destination-$index'),
                leading: Icon(_navigationIcons[index]),
                title: Text(_navigationLabels[index]),
                selected: selectedIndex == index,
                onTap: () {
                  onDestinationSelected(index);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardNavigationRail extends StatelessWidget {
  const DashboardNavigationRail({
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      key: const ValueKey('dashboard-navigation-rail'),
      extended: true,
      minExtendedWidth: 220,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      leading: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Icon(
          Icons.favorite,
          size: 44,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      destinations: List.generate(
        _navigationLabels.length,
        (index) => NavigationRailDestination(
          icon: Icon(_navigationIcons[index]),
          label: Text(_navigationLabels[index]),
        ),
      ),
    );
  }
}

const _navigationLabels = ['Dashboard', 'Settings', 'About', 'Logout'];
const _navigationIcons = [Icons.home, Icons.settings, Icons.info, Icons.logout];

class DashboardBody extends StatelessWidget {
  const DashboardBody({
    required this.type,
    required this.title,
    required this.updatesEnabled,
    required this.onUpdatesChanged,
    super.key,
  });

  final DeviceType type;
  final String title;
  final bool updatesEnabled;
  final ValueChanged<bool> onUpdatesChanged;

  @override
  Widget build(BuildContext context) {
    if (type == DeviceType.expanded || type == DeviceType.large) {
      return Row(
        key: const ValueKey('expanded-layout'),
        children: [
          Expanded(
            flex: 4,
            child: DashboardMainContent(
              type: type,
              title: title,
              updatesEnabled: updatesEnabled,
              onUpdatesChanged: onUpdatesChanged,
            ),
          ),
          const Expanded(flex: 1, child: DashboardSidePane()),
        ],
      );
    }

    return DashboardMainContent(
      key: ValueKey(
        type == DeviceType.compact ? 'compact-layout' : 'medium-layout',
      ),
      type: type,
      title: title,
      updatesEnabled: updatesEnabled,
      onUpdatesChanged: onUpdatesChanged,
    );
  }
}

class DashboardMainContent extends StatelessWidget {
  const DashboardMainContent({
    required this.type,
    required this.title,
    required this.updatesEnabled,
    required this.onUpdatesChanged,
    super.key,
  });

  final DeviceType type;
  final String title;
  final bool updatesEnabled;
  final ValueChanged<bool> onUpdatesChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        MetricGrid(type: type),
        const SizedBox(height: 16),
        AdaptiveControlsPanel(
          updatesEnabled: updatesEnabled,
          onUpdatesChanged: onUpdatesChanged,
        ),
        const SizedBox(height: 16),
        const DashboardPanel(
          icon: Icons.show_chart,
          title: 'Weekly activity',
          subtitle: 'Your dashboard activity is up 18% this week.',
        ),
        const SizedBox(height: 12),
        const DashboardPanel(
          icon: Icons.task_alt,
          title: 'Completed tasks',
          subtitle: '24 of 30 assigned tasks are complete.',
        ),
        const SizedBox(height: 12),
        const DashboardPanel(
          icon: Icons.schedule,
          title: 'Upcoming review',
          subtitle: 'The next project review is scheduled for Friday.',
        ),
        const SizedBox(height: 12),
        const DashboardPanel(
          icon: Icons.people,
          title: 'Team summary',
          subtitle: 'Eight members contributed updates today.',
        ),
      ],
    );
  }
}

class MetricGrid extends StatelessWidget {
  const MetricGrid({required this.type, super.key});

  final DeviceType type;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = type == DeviceType.compact ? 2 : 4;
        const spacing = 12.0;
        final cardWidth =
            (constraints.maxWidth - spacing * (columnCount - 1)) / columnCount;

        return Wrap(
          key: const ValueKey('metric-grid'),
          spacing: spacing,
          runSpacing: spacing,
          children: [
            MetricCard(
              key: const ValueKey('metric-card-0'),
              width: cardWidth,
              icon: Icons.people,
              value: '1,248',
              label: 'Visitors',
            ),
            MetricCard(
              key: const ValueKey('metric-card-1'),
              width: cardWidth,
              icon: Icons.shopping_bag,
              value: '320',
              label: 'Orders',
            ),
            MetricCard(
              key: const ValueKey('metric-card-2'),
              width: cardWidth,
              icon: Icons.payments,
              value: '₱48K',
              label: 'Revenue',
            ),
            MetricCard(
              key: const ValueKey('metric-card-3'),
              width: cardWidth,
              icon: Icons.trending_up,
              value: '18%',
              label: 'Growth',
            ),
          ],
        );
      },
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.width,
    required this.icon,
    required this.value,
    required this.label,
    super.key,
  });

  final double width;
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AspectRatio(
        aspectRatio: 1.15,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const Spacer(),
                FittedBox(
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdaptiveControlsPanel extends StatelessWidget {
  const AdaptiveControlsPanel({
    required this.updatesEnabled,
    required this.onUpdatesChanged,
    super.key,
  });

  final bool updatesEnabled;
  final ValueChanged<bool> onUpdatesChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey('adaptive-controls-panel'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircularProgressIndicator.adaptive(),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live dashboard updates',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('This control adapts to the current platform.'),
                ],
              ),
            ),
            Switch.adaptive(
              key: const ValueKey('dashboard-updates-switch'),
              value: updatesEnabled,
              onChanged: onUpdatesChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardPanel extends StatelessWidget {
  const DashboardPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardSidePane extends StatelessWidget {
  const DashboardSidePane({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('dashboard-side-pane'),
      padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
      children: [
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.insights, size: 40),
                SizedBox(height: 56),
                Text(
                  'Performance overview',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Desktop layouts use this second content pane.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const DashboardPanel(
          icon: Icons.notifications,
          title: 'Notifications',
          subtitle: 'Three new updates need your attention.',
        ),
      ],
    );
  }
}
