import '../../events/domain/event.dart';

/// Resumo exibido na lista de eventos.
class EventSummary {
  const EventSummary({
    required this.event,
    required this.totalParticipants,
    required this.activeParticipants,
  });

  final Event event;
  final int totalParticipants;
  final int activeParticipants;
}
