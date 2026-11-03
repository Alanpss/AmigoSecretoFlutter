import '../../groups/domain/group.dart';
import '../../participants/data/participant_view.dart';
import 'event.dart';

/// Dados combinados da visão geral do evento.
class EventOverviewData {
  const EventOverviewData({
    required this.event,
    required this.participants,
    required this.groups,
  });

  final Event event;
  final List<ParticipantWithPerson> participants;
  final List<Group> groups;

  int get activeParticipants =>
      participants.where((view) => view.participant.isActive).length;

  int get restrictedGroups =>
      groups.where((group) => group.restrictionEnabled).length;
}
