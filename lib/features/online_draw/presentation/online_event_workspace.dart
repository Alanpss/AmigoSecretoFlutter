import 'package:flutter/material.dart';

/// A compact, keyboard-navigable workspace for the online event setup flow.
class OnlineEventWorkspace extends StatelessWidget {
  const OnlineEventWorkspace({
    super.key,
    required this.eventTab,
    required this.participantsTab,
    required this.groupsTab,
    required this.reviewTab,
  });

  final Widget eventTab;
  final Widget participantsTab;
  final Widget groupsTab;
  final Widget reviewTab;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 680;

    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: TabBar(
            isScrollable: compact,
            labelPadding: const EdgeInsets.symmetric(horizontal: 18),
            tabs: const [
              Tab(icon: Icon(Icons.event_outlined), text: 'Evento'),
              Tab(icon: Icon(Icons.people_outline), text: 'Participantes'),
              Tab(icon: Icon(Icons.groups_outlined), text: 'Grupos'),
              Tab(
                icon: Icon(Icons.fact_check_outlined),
                text: 'Revisão e links',
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: TabBarView(
            children: [eventTab, participantsTab, groupsTab, reviewTab],
          ),
        ),
      ],
    );
  }
}
