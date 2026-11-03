import 'participant.dart';
import 'person.dart';

enum RecipientKind { self, guardian }

/// Destinatário resolvido de uma mensagem.
class RecipientResolution {
  const RecipientResolution({
    required this.kind,
    required this.recipient,
    required this.phoneE164,
  });

  final RecipientKind kind;
  final Person recipient;
  final String? phoneE164;

  bool get hasContact => phoneE164 != null && phoneE164!.isNotEmpty;
}

/// Resolve quem recebe a mensagem de um participante.
///
/// Regra direta, sem cadeia: se há responsável, usa o telefone **dele**; nunca
/// procura o responsável do responsável. Sem responsável, usa o próprio
/// participante.
RecipientResolution resolveRecipient({
  required Person owner,
  required Participant participant,
  Person? guardian,
}) {
  final guardianId = participant.guardianPersonId;
  if (guardianId == null) {
    return RecipientResolution(
      kind: RecipientKind.self,
      recipient: owner,
      phoneE164: owner.phoneE164,
    );
  }

  if (guardian == null) {
    // Registro inconsistente: não use o telefone do dono como fallback.
    return RecipientResolution(
      kind: RecipientKind.guardian,
      recipient: owner,
      phoneE164: null,
    );
  }

  return RecipientResolution(
    kind: RecipientKind.guardian,
    recipient: guardian,
    phoneE164: guardian.phoneE164,
  );
}
