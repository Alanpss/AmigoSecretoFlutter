import 'package:sembast/sembast.dart';

import '../../../core/database/stores.dart';
import '../../../core/errors/domain_exceptions.dart';
import '../domain/event.dart';

/// Rejeita alterações no pareamento enquanto o sorteio estiver ativo.
Future<void> ensureEventEditable(DatabaseClient txn, String eventId) async {
  final record = await eventsStore.record(eventId).get(txn);
  if (record == null) {
    throw const EntityNotFoundException('Evento não encontrado.');
  }
  if (Event.fromMap(record).activeDrawId != null) {
    throw const ActiveDrawException();
  }
}

/// Incrementa a revisão de pareamento do evento dentro de uma transação.
///
/// A revisão serve para detectar mudanças entre a revisão dos dados e a
/// confirmação do sorteio (Fase 3). Qualquer alteração em participantes,
/// pessoas vinculadas ou grupos deve chamar esta função.
Future<void> bumpEventRevision(
  DatabaseClient txn,
  String eventId,
  DateTime now,
) async {
  final record = await eventsStore.record(eventId).get(txn);
  if (record == null) {
    return;
  }
  final event = Event.fromMap(record);
  await eventsStore
      .record(eventId)
      .put(
        txn,
        event
            .copyWith(
              pairingRevision: event.pairingRevision + 1,
              updatedAt: now,
            )
            .toMap(),
      );
}
