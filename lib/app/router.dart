import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/events/presentation/event_form_page.dart';
import '../features/events/presentation/event_list_page.dart';
import '../features/events/presentation/event_overview_page.dart';
import '../features/events/presentation/review_page.dart';
import '../features/draw/presentation/draw_page.dart';
import '../features/groups/presentation/group_form_page.dart';
import '../features/groups/presentation/group_list_page.dart';
import '../features/participants/presentation/participant_form_page.dart';
import '../features/participants/presentation/participant_list_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../shared/layout/app_shell.dart';
import '../shared/layout/event_shell.dart';
import '../shared/widgets/not_found_page.dart';

/// Rotas do aplicativo.
final routerProvider = Provider<GoRouter>((ref) {
  Widget eventShell(GoRouterState state, Widget child) {
    final eventId = state.pathParameters['eventId']!;
    return EventShell(eventId: eventId, location: state.uri.path, child: child);
  }

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(location: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const EventListPage(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/events/new',
        builder: (context, state) => const EventFormPage(),
      ),
      GoRoute(
        path: '/events/:eventId',
        builder: (context, state) => eventShell(
          state,
          EventOverviewPage(eventId: state.pathParameters['eventId']!),
        ),
      ),
      GoRoute(
        path: '/events/:eventId/edit',
        builder: (context, state) =>
            EventFormPage(eventId: state.pathParameters['eventId']),
      ),
      GoRoute(
        path: '/events/:eventId/participants',
        builder: (context, state) => eventShell(
          state,
          ParticipantListPage(eventId: state.pathParameters['eventId']!),
        ),
      ),
      GoRoute(
        path: '/events/:eventId/participants/new',
        builder: (context, state) =>
            ParticipantFormPage(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(
        path: '/events/:eventId/participants/:participantId/edit',
        builder: (context, state) => ParticipantFormPage(
          eventId: state.pathParameters['eventId']!,
          participantId: state.pathParameters['participantId'],
        ),
      ),
      GoRoute(
        path: '/events/:eventId/groups',
        builder: (context, state) => eventShell(
          state,
          GroupListPage(eventId: state.pathParameters['eventId']!),
        ),
      ),
      GoRoute(
        path: '/events/:eventId/groups/new',
        builder: (context, state) =>
            GroupFormPage(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(
        path: '/events/:eventId/groups/:groupId/edit',
        builder: (context, state) => GroupFormPage(
          eventId: state.pathParameters['eventId']!,
          groupId: state.pathParameters['groupId'],
        ),
      ),
      GoRoute(
        path: '/events/:eventId/review',
        builder: (context, state) => eventShell(
          state,
          ReviewPage(eventId: state.pathParameters['eventId']!),
        ),
      ),
      GoRoute(
        path: '/events/:eventId/draw',
        builder: (context, state) => eventShell(
          state,
          DrawPage(eventId: state.pathParameters['eventId']!),
        ),
      ),
    ],
    errorBuilder: (context, state) => const NotFoundPage(),
  );

  ref.onDispose(router.dispose);
  return router;
});
