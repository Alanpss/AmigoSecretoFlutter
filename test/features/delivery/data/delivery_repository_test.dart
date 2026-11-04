import 'dart:math';

import 'package:amigo_secreto/core/database/app_database.dart';
import 'package:amigo_secreto/core/errors/domain_exceptions.dart';
import 'package:amigo_secreto/features/delivery/data/delivery_repository.dart';
import 'package:amigo_secreto/features/delivery/domain/delivery_status.dart';
import 'package:amigo_secreto/features/delivery/domain/message_template.dart';
import 'package:amigo_secreto/features/draw/data/draw_repository.dart';
import 'package:amigo_secreto/features/draw/domain/draw_engine.dart';
import 'package:amigo_secreto/features/events/data/event_repository.dart';
import 'package:amigo_secreto/features/participants/data/participant_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database.dart';

void main() {
  final now = DateTime.utc(2026, 11, 3, 12);
  late AppDatabase database;
  late EventRepository events;
  late DrawRepository draws;
  late DeliveryRepository deliveries;
  late String eventId;
  late String drawId;

  setUp(() async {
    database = await createTestDatabase();
    var id = 0;
    String nextId() => 'id-${++id}';
    events = EventRepository(database.database, now: () => now, newId: nextId);
    final participants = ParticipantRepository(
      database.database,
      now: () => now,
      newId: nextId,
    );
    draws = DrawRepository(database.database, now: () => now, newId: nextId);
    deliveries = DeliveryRepository(database.database, now: () => now);

    final event = await events.create(name: 'Encontro de teste');
    eventId = event.id;
    for (final name in ['Ana Exemplo', 'Beto Exemplo', 'Cris Exemplo']) {
      await participants.createWithNewPerson(eventId: event.id, name: name);
    }

    final preparation = await draws.prepare(event.id);
    final result = const DrawEngine().draw(
      preparation.request,
      random: Random(42),
    );
    drawId = 'draw-delivery-test';
    await draws.saveDraw(
      eventId: event.id,
      drawId: drawId,
      pairingRevision: preparation.pairingRevision,
      pairing: result.assignments,
    );
  });

  tearDown(() => database.close());

  test('lista apenas entregas do sorteio ativo', () async {
    expect(await deliveries.getForActiveEvent(eventId), hasLength(3));

    await draws.invalidateDraw(eventId);

    expect(await deliveries.getForActiveEvent(eventId), isEmpty);
    expect(await draws.getDraw(drawId), isNotNull);
  });

  test('abrir altera pendente para aberta, sem confirmar envio', () async {
    final delivery = (await deliveries.getForActiveEvent(eventId)).first;

    final opened = await deliveries.markOpened(
      eventId: eventId,
      deliveryId: delivery.id,
    );

    expect(opened.status, DeliveryStatus.opened.name);
    expect(opened.openedAt, now);
    expect(opened.confirmedAt, isNull);
    expect(opened.confirmationMethod, isNull);
  });

  test('confirma método manual e reabrir não remove a confirmação', () async {
    final delivery = (await deliveries.getForActiveEvent(eventId)).first;
    final confirmed = await deliveries.confirmSent(
      eventId: eventId,
      deliveryId: delivery.id,
      method: DeliveryConfirmationMethod.manual,
    );

    expect(confirmed.status, DeliveryStatus.confirmed.name);
    expect(confirmed.confirmationMethod, 'manual');
    expect(confirmed.confirmedAt, now);

    final reopened = await deliveries.markOpened(
      eventId: eventId,
      deliveryId: delivery.id,
    );
    expect(reopened.status, DeliveryStatus.confirmed.name);
    expect(reopened.confirmedAt, now);
    expect(reopened.confirmationMethod, 'manual');
  });

  test(
    'atualiza somente mensagens pendentes quando há confirmação explícita',
    () async {
      final original = await deliveries.getForActiveEvent(eventId);
      final opened = original[0];
      final confirmed = original[1];
      final pending = original[2];
      await deliveries.markOpened(eventId: eventId, deliveryId: opened.id);
      await deliveries.confirmSent(
        eventId: eventId,
        deliveryId: confirmed.id,
        method: DeliveryConfirmationMethod.whatsapp,
      );

      final summary = await deliveries.saveMessageTemplate(
        eventId: eventId,
        template: '{participante} → {sorteado}',
        updatePending: true,
      );
      final updated = await deliveries.getForActiveEvent(eventId);
      final event = await events.getById(eventId);

      expect(summary.updatedPendingMessages, 1);
      expect(event!.messageTemplate, '{participante} → {sorteado}');
      expect(
        updated.singleWhere((item) => item.id == opened.id).messageSnapshot,
        opened.messageSnapshot,
      );
      expect(
        updated.singleWhere((item) => item.id == confirmed.id).messageSnapshot,
        confirmed.messageSnapshot,
      );
      final updatedPending = updated.singleWhere(
        (item) => item.id == pending.id,
      );
      expect(updatedPending.status, DeliveryStatus.pending.name);
      expect(
        updatedPending.messageSnapshot,
        '${pending.ownerNameSnapshot} → ${pending.drawnNameSnapshot}',
      );
    },
  );

  test(
    'salva o modelo sem alterar pendentes quando a opção é recusada',
    () async {
      final original = (await deliveries.getForActiveEvent(eventId)).first;

      final summary = await deliveries.saveMessageTemplate(
        eventId: eventId,
        template: 'Nova mensagem: {participante}',
        updatePending: false,
      );

      expect(summary.updatedPendingMessages, 0);
      expect(
        (await events.getById(eventId))!.messageTemplate,
        'Nova mensagem: {participante}',
      );
      expect(
        (await deliveries.getForActiveEvent(eventId))
            .singleWhere((item) => item.id == original.id)
            .messageSnapshot,
        original.messageSnapshot,
      );
    },
  );

  test('modelo inválido não salva alteração parcial', () async {
    final originalEvent = await events.getById(eventId);

    await expectLater(
      deliveries.saveMessageTemplate(
        eventId: eventId,
        template: 'Olá, {desconhecida}',
        updatePending: true,
      ),
      throwsA(isA<MessageTemplateException>()),
    );

    expect(
      (await events.getById(eventId))!.messageTemplate,
      originalEvent!.messageTemplate,
    );
    expect(await deliveries.getForActiveEvent(eventId), hasLength(3));
  });

  test(
    'não permite alterar o modelo pelo formulário geral com sorteio ativo',
    () async {
      final event = (await events.getById(eventId))!;

      await expectLater(
        events.update(
          id: eventId,
          name: event.name,
          eventDate: event.eventDate,
          messageTemplate: 'Modelo alterado: {participante}',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        (await events.getById(eventId))!.messageTemplate,
        event.messageTemplate,
      );
    },
  );
}
