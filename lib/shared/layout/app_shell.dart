import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Layout principal, com navegação inferior em telas estreitas e rail em telas
/// médias/expandidas.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const List<_ShellDestination> _destinations = [
    _ShellDestination(
      label: 'Eventos',
      icon: Icons.celebration_outlined,
      selectedIcon: Icons.celebration,
    ),
    _ShellDestination(
      label: 'Configurações',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  int get _selectedIndex =>
      location.startsWith('/settings') || location.startsWith('/backup')
      ? 1
      : 0;

  void _select(BuildContext context, int index) {
    context.go(index == 1 ? '/settings' : '/');
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        final content = SafeArea(top: false, child: child);

        return Scaffold(
          appBar: AppBar(title: const Text('Amigo Secreto')),
          body: isCompact
              ? content
              : Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (index) => _select(context, index),
                      labelType: NavigationRailLabelType.all,
                      leading: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Icon(Icons.card_giftcard),
                      ),
                      destinations: _destinations
                          .map(
                            (destination) => NavigationRailDestination(
                              icon: Icon(destination.icon),
                              selectedIcon: Icon(destination.selectedIcon),
                              label: Text(destination.label),
                            ),
                          )
                          .toList(),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: content),
                  ],
                ),
          bottomNavigationBar: isCompact
              ? NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) => _select(context, index),
                  destinations: _destinations
                      .map(
                        (destination) => NavigationDestination(
                          icon: Icon(destination.icon),
                          selectedIcon: Icon(destination.selectedIcon),
                          label: destination.label,
                        ),
                      )
                      .toList(),
                )
              : null,
        );
      },
    );
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
