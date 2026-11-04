import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../widgets/async_states.dart';

/// Layout do evento, com navegação entre visão geral, cadastros e entregas.
class EventShell extends ConsumerWidget {
  const EventShell({
    super.key,
    required this.eventId,
    required this.location,
    required this.child,
  });

  final String eventId;
  final String location;
  final Widget child;

  static const List<_EventDestination> _destinations = [
    _EventDestination(
      label: 'Visão geral',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      segment: '',
    ),
    _EventDestination(
      label: 'Participantes',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      segment: '/participants',
    ),
    _EventDestination(
      label: 'Grupos',
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups,
      segment: '/groups',
    ),
    _EventDestination(
      label: 'Revisão',
      icon: Icons.checklist_outlined,
      selectedIcon: Icons.checklist,
      segment: '/review',
    ),
    _EventDestination(
      label: 'Entregas',
      icon: Icons.mark_email_unread_outlined,
      selectedIcon: Icons.mark_email_read_outlined,
      segment: '/deliveries',
    ),
  ];

  int get _selectedIndex {
    final index = _destinations.indexWhere(
      (destination) =>
          destination.segment.isNotEmpty &&
          location.endsWith(destination.segment),
    );
    return index < 0 ? 0 : index;
  }

  void _select(BuildContext context, int index) {
    final segment = _destinations[index].segment;
    context.go('/events/$eventId$segment');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventProvider(eventId));

    return eventAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Evento')),
        body: const LoadingView(),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Voltar para eventos',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
          title: const Text('Evento'),
        ),
        body: AsyncErrorView(
          title: 'Evento não encontrado',
          message:
              'O evento pode ter sido excluído. Volte para a lista de '
              'eventos para continuar.',
          onRetry: () => ref.invalidate(eventProvider(eventId)),
        ),
      ),
      data: (event) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 600;
            final content = SafeArea(top: false, child: child);

            return Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  tooltip: 'Voltar para eventos',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/'),
                ),
                title: Text(
                  event.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              body: isCompact
                  ? content
                  : Row(
                      children: [
                        NavigationRail(
                          selectedIndex: _selectedIndex,
                          onDestinationSelected: (index) =>
                              _select(context, index),
                          labelType: NavigationRailLabelType.all,
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
      },
    );
  }
}

class _EventDestination {
  const _EventDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.segment,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String segment;
}
