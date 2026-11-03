import 'package:amigo_secreto/features/participants/domain/guardian_resolver.dart';
import 'package:amigo_secreto/features/participants/domain/participant.dart';
import 'package:amigo_secreto/features/participants/domain/person.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime now() => DateTime.utc(2026, 1, 1);

  Person person(String id, String name, {String? phone}) {
    return Person(
      id: id,
      name: name,
      nickname: null,
      phoneE164: phone,
      createdAt: now(),
      updatedAt: now(),
    );
  }

  Participant participant({String? guardianPersonId}) {
    return Participant(
      id: 'participant-1',
      eventId: 'event-1',
      personId: 'owner',
      isActive: true,
      guardianPersonId: guardianPersonId,
      createdAt: now(),
      updatedAt: now(),
    );
  }

  test('sem responsável, usa o telefone do próprio participante', () {
    final owner = person('owner', 'Ana', phone: '+5511900000001');
    final resolution = resolveRecipient(
      owner: owner,
      participant: participant(),
    );

    expect(resolution.kind, RecipientKind.self);
    expect(resolution.recipient.id, 'owner');
    expect(resolution.phoneE164, '+5511900000001');
    expect(resolution.hasContact, isTrue);
  });

  test('com responsável, usa somente o telefone do responsável', () {
    final owner = person('owner', 'Ana', phone: '+5511900000001');
    final guardian = person('guardian', 'Mãe', phone: '+5511900000002');
    final resolution = resolveRecipient(
      owner: owner,
      participant: participant(guardianPersonId: 'guardian'),
      guardian: guardian,
    );

    expect(resolution.kind, RecipientKind.guardian);
    expect(resolution.recipient.id, 'guardian');
    expect(resolution.phoneE164, '+5511900000002');
  });

  test('responsável sem telefone não usa o telefone do participante', () {
    final owner = person('owner', 'Ana', phone: '+5511900000001');
    final guardian = person('guardian', 'Mãe');
    final resolution = resolveRecipient(
      owner: owner,
      participant: participant(guardianPersonId: 'guardian'),
      guardian: guardian,
    );

    expect(resolution.kind, RecipientKind.guardian);
    expect(resolution.phoneE164, isNull);
    expect(resolution.hasContact, isFalse);
  });

  test('registro de responsável ausente não cai para o telefone do dono', () {
    final owner = person('owner', 'Ana', phone: '+5511900000001');
    final resolution = resolveRecipient(
      owner: owner,
      participant: participant(guardianPersonId: 'desconhecido'),
    );

    expect(resolution.kind, RecipientKind.guardian);
    expect(resolution.phoneE164, isNull);
    expect(resolution.hasContact, isFalse);
  });
}
