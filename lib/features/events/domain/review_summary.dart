import '../../participants/data/participant_view.dart';
import '../../groups/domain/group.dart';

/// Pendências exibidas na revisão antes do sorteio.
class ReviewSummary {
  const ReviewSummary({
    required this.totalParticipants,
    required this.activeParticipants,
    required this.inactiveParticipants,
    required this.groups,
    required this.activeWithoutContact,
    required this.groupsWithFewMembers,
  });

  final int totalParticipants;
  final int activeParticipants;
  final int inactiveParticipants;
  final List<Group> groups;
  final List<ParticipantWithPerson> activeWithoutContact;
  final List<Group> groupsWithFewMembers;

  int get restrictedGroups =>
      groups.where((group) => group.restrictionEnabled).length;

  bool get hasEnoughActiveParticipants => activeParticipants >= 2;

  bool get hasPendingIssues =>
      !hasEnoughActiveParticipants || activeWithoutContact.isNotEmpty;
}
