import '../../groups/domain/group.dart';
import '../domain/guardian_resolver.dart';
import '../domain/participant.dart';
import '../domain/person.dart';

/// Participante com os dados de pessoa, responsável e grupos já resolvidos.
class ParticipantWithPerson {
  const ParticipantWithPerson({
    required this.participant,
    required this.person,
    required this.guardian,
    required this.groups,
  });

  final Participant participant;
  final Person person;
  final Person? guardian;
  final List<Group> groups;

  RecipientResolution get recipient => resolveRecipient(
    owner: person,
    participant: participant,
    guardian: guardian,
  );

  List<String> get groupNames =>
      groups.map((group) => group.name).toList(growable: false);

  bool get hasContact => recipient.hasContact;
}
