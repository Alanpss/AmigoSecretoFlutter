import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../core/errors/domain_exceptions.dart';
import '../features/events/data/event_repository.dart';
import '../features/events/data/event_summary.dart';
import '../features/events/domain/event.dart';
import '../features/events/domain/event_overview_data.dart';
import '../features/events/domain/review_summary.dart';
import '../features/draw/data/draw_repository.dart';
import '../features/draw/data/draw_records.dart';
import '../features/draw/domain/draw_engine.dart';
import '../features/groups/data/group_repository.dart';
import '../features/groups/domain/group.dart';
import '../features/participants/data/participant_repository.dart';
import '../features/participants/data/participant_view.dart';
import '../features/participants/data/person_repository.dart';
import '../features/participants/domain/person.dart';

/// Fornece o banco já aberto para o restante do aplicativo.
///
/// O valor é injetado no `ProviderScope` pelo bootstrap. Testes substituem
/// este provider por um banco em memória.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw StateError(
    'appDatabaseProvider deve ser sobrescrito no ProviderScope.',
  );
});

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(ref.watch(appDatabaseProvider).database);
});

final personRepositoryProvider = Provider<PersonRepository>((ref) {
  return PersonRepository(ref.watch(appDatabaseProvider).database);
});

final participantRepositoryProvider = Provider<ParticipantRepository>((ref) {
  return ParticipantRepository(ref.watch(appDatabaseProvider).database);
});

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository(ref.watch(appDatabaseProvider).database);
});

final drawRepositoryProvider = Provider<DrawRepository>((ref) {
  return DrawRepository(ref.watch(appDatabaseProvider).database);
});

final drawEngineProvider = Provider<DrawEngine>((ref) => const DrawEngine());

final drawPreparationProvider = FutureProvider.family<DrawPreparation, String>((
  ref,
  eventId,
) {
  return ref.watch(drawRepositoryProvider).prepare(eventId);
});

final activeDrawProvider = FutureProvider.family<PersistedDraw?, String>((
  ref,
  eventId,
) {
  return ref.watch(drawRepositoryProvider).getActiveDraw(eventId);
});

/// Eventos com contagem de participantes para a lista inicial.
final eventsProvider = FutureProvider<List<EventSummary>>((ref) async {
  return ref.watch(eventRepositoryProvider).listSummaries();
});

/// Evento por ID; falha com mensagem amigável quando não existe.
final eventProvider = FutureProvider.family<Event, String>((ref, id) async {
  final event = await ref.watch(eventRepositoryProvider).getById(id);
  if (event == null) {
    throw const EntityNotFoundException('Evento não encontrado.');
  }
  return event;
});

/// Todas as pessoas reutilizáveis, em ordem alfabética.
final peopleProvider = FutureProvider<List<Person>>((ref) async {
  return ref.watch(personRepositoryProvider).getAll();
});

/// Participantes do evento com pessoa, responsável e grupos resolvidos.
final participantsProvider =
    FutureProvider.family<List<ParticipantWithPerson>, String>((
      ref,
      eventId,
    ) async {
      final participantRepository = ref.watch(participantRepositoryProvider);
      final personRepository = ref.watch(personRepositoryProvider);
      final groupRepository = ref.watch(groupRepositoryProvider);

      final participants = await participantRepository.getByEvent(eventId);
      final people = {
        for (final person in await personRepository.getAll()) person.id: person,
      };
      final groups = await groupRepository.getByEvent(eventId);

      final groupsByParticipant = <String, List<Group>>{};
      for (final group in groups) {
        for (final participantId in group.memberParticipantIds) {
          groupsByParticipant
              .putIfAbsent(participantId, () => <Group>[])
              .add(group);
        }
      }

      final views = <ParticipantWithPerson>[];
      for (final participant in participants) {
        final person = people[participant.personId];
        if (person == null) {
          continue;
        }
        final guardian = participant.guardianPersonId == null
            ? null
            : people[participant.guardianPersonId];
        views.add(
          ParticipantWithPerson(
            participant: participant,
            person: person,
            guardian: guardian,
            groups: groupsByParticipant[participant.id] ?? const [],
          ),
        );
      }

      views.sort(
        (a, b) =>
            a.person.name.toLowerCase().compareTo(b.person.name.toLowerCase()),
      );
      return views;
    });

/// Grupos do evento, em ordem alfabética.
final groupsProvider = FutureProvider.family<List<Group>, String>((
  ref,
  eventId,
) async {
  return ref.watch(groupRepositoryProvider).getByEvent(eventId);
});

/// Grupo por ID; falha com mensagem amigável quando não existe.
final groupProvider = FutureProvider.family<Group, String>((ref, id) async {
  final group = await ref.watch(groupRepositoryProvider).getById(id);
  if (group == null) {
    throw const EntityNotFoundException('Grupo não encontrado.');
  }
  return group;
});

/// Dados combinados da visão geral do evento.
final eventOverviewProvider = FutureProvider.family<EventOverviewData, String>((
  ref,
  eventId,
) async {
  final event = await ref.watch(eventProvider(eventId).future);
  final participants = await ref.watch(participantsProvider(eventId).future);
  final groups = await ref.watch(groupsProvider(eventId).future);
  return EventOverviewData(
    event: event,
    participants: participants,
    groups: groups,
  );
});

/// Pendências da revisão do evento, sem executar sorteio.
final reviewProvider = FutureProvider.family<ReviewSummary, String>((
  ref,
  eventId,
) async {
  final participants = await ref.watch(participantsProvider(eventId).future);
  final groups = await ref.watch(groupsProvider(eventId).future);

  final active = participants
      .where((view) => view.participant.isActive)
      .toList(growable: false);

  return ReviewSummary(
    totalParticipants: participants.length,
    activeParticipants: active.length,
    inactiveParticipants: participants.length - active.length,
    groups: groups,
    activeWithoutContact: active
        .where((view) => !view.hasContact)
        .toList(growable: false),
    groupsWithFewMembers: groups
        .where((group) => group.memberParticipantIds.length < 2)
        .toList(growable: false),
  );
});

/// Invalida os dados de um evento depois de uma alteração.
void refreshEvent(WidgetRef ref, String eventId) {
  ref.invalidate(eventsProvider);
  ref.invalidate(eventProvider(eventId));
  ref.invalidate(eventOverviewProvider(eventId));
  ref.invalidate(peopleProvider);
  ref.invalidate(participantsProvider(eventId));
  ref.invalidate(groupsProvider(eventId));
  ref.invalidate(groupProvider);
  ref.invalidate(reviewProvider(eventId));
  ref.invalidate(drawPreparationProvider(eventId));
  ref.invalidate(activeDrawProvider(eventId));
}

/// Invalida a lista de eventos (por exemplo, após criar ou excluir).
void refreshEvents(WidgetRef ref) {
  ref.invalidate(eventsProvider);
  ref.invalidate(peopleProvider);
}
