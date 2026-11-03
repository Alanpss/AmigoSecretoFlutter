import 'package:sembast/sembast.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/stores.dart';
import '../../../core/errors/domain_exceptions.dart';
import '../../events/data/event_revision.dart';
import '../domain/person.dart';
import '../domain/phone_number.dart';
import '../domain/validation.dart';

DateTime _systemNow() => DateTime.now().toUtc();
String _systemId() => const Uuid().v4();

/// Pessoas com nome ou telefone parecidos com um valor informado.
class DuplicatePersonMatches {
  const DuplicatePersonMatches({
    required this.nameMatches,
    required this.phoneMatches,
  });

  final List<Person> nameMatches;
  final List<Person> phoneMatches;

  bool get hasMatches => nameMatches.isNotEmpty || phoneMatches.isNotEmpty;
}

/// Persistência de pessoas reutilizáveis.
class PersonRepository {
  PersonRepository(
    this._database, {
    DateTime Function()? now,
    String Function()? newId,
  }) : _now = now ?? _systemNow,
       _newId = newId ?? _systemId;

  final Database _database;
  final DateTime Function() _now;
  final String Function() _newId;

  Future<List<Person>> getAll() async {
    final records = await peopleStore.find(_database);
    final people = records
        .map((record) => Person.fromMap(record.value))
        .toList(growable: false);
    people.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return people;
  }

  Future<Person?> getById(String id) async {
    final record = await peopleStore.record(id).get(_database);
    return record == null ? null : Person.fromMap(record);
  }

  Future<Person> create({
    required String name,
    String? nickname,
    String? phoneE164,
  }) async {
    final normalizedName = normalizePersonText(name);
    final nameError = validatePersonName(normalizedName);
    if (nameError != null) {
      throw ValidationException(nameError);
    }
    final normalizedNickname = _nullableText(nickname);
    final nicknameError = validateNickname(normalizedNickname);
    if (nicknameError != null) {
      throw ValidationException(nicknameError);
    }
    if (!isValidE164(phoneE164)) {
      throw const ValidationException('Telefone inválido.');
    }

    final now = _now();
    final person = Person(
      id: _newId(),
      name: normalizedName,
      nickname: normalizedNickname,
      phoneE164: phoneE164,
      createdAt: now,
      updatedAt: now,
    );

    await peopleStore.record(person.id).put(_database, person.toMap());
    return person;
  }

  Future<Person> update({
    required String id,
    required String name,
    String? nickname,
    String? phoneE164,
  }) async {
    final normalizedName = normalizePersonText(name);
    final nameError = validatePersonName(normalizedName);
    if (nameError != null) {
      throw ValidationException(nameError);
    }
    final normalizedNickname = _nullableText(nickname);
    final nicknameError = validateNickname(normalizedNickname);
    if (nicknameError != null) {
      throw ValidationException(nicknameError);
    }
    if (!isValidE164(phoneE164)) {
      throw const ValidationException('Telefone inválido.');
    }

    final now = _now();
    late Person updated;

    await _database.transaction((txn) async {
      final record = await peopleStore.record(id).get(txn);
      if (record == null) {
        throw const EntityNotFoundException('Pessoa não encontrada.');
      }

      final current = Person.fromMap(record);
      final participants = await participantsStore.find(txn);
      final affectedEventIds = <String>{};
      for (final participantRecord in participants) {
        final map = participantRecord.value;
        if (map['personId'] == id || map['guardianPersonId'] == id) {
          final eventId = map['eventId'] as String?;
          if (eventId != null) affectedEventIds.add(eventId);
        }
      }
      for (final eventId in affectedEventIds) {
        await ensureEventEditable(txn, eventId);
      }
      updated = current.copyWith(
        name: normalizedName,
        nickname: normalizedNickname,
        clearNickname: normalizedNickname == null,
        phoneE164: phoneE164,
        clearPhone: phoneE164 == null,
        updatedAt: now,
      );
      await peopleStore.record(id).put(txn, updated.toMap());

      // Nome, apelido e telefone alteram o que será exibido/enviado. A revisão
      // de todos os eventos que referenciam a pessoa é incrementada.
      for (final eventId in affectedEventIds) {
        await bumpEventRevision(txn, eventId, now);
      }
    });

    return updated;
  }

  /// Exclui uma pessoa que não tenha vínculo como participante ou responsável.
  Future<void> delete(String id) async {
    await _database.transaction((txn) async {
      final record = await peopleStore.record(id).get(txn);
      if (record == null) {
        throw const EntityNotFoundException('Pessoa não encontrada.');
      }

      final participants = await participantsStore.find(txn);
      final inUse = participants.any((record) {
        final map = record.value;
        return map['personId'] == id || map['guardianPersonId'] == id;
      });
      if (inUse) {
        throw const PersonInUseException();
      }

      await peopleStore.record(id).delete(txn);
    });
  }

  /// Procura nomes e telefones iguais, sem bloquear o cadastro.
  Future<DuplicatePersonMatches> findMatches({
    String? name,
    String? phoneE164,
    String? excludePersonId,
  }) async {
    final people = await getAll();
    final normalizedName = normalizePersonText(name ?? '').toLowerCase();
    final candidates = people
        .where((person) => person.id != excludePersonId)
        .toList(growable: false);

    final nameMatches = normalizedName.isEmpty
        ? const <Person>[]
        : candidates
              .where((person) => person.name.toLowerCase() == normalizedName)
              .toList(growable: false);

    final phoneMatches = phoneE164 == null || phoneE164.isEmpty
        ? const <Person>[]
        : candidates
              .where((person) => person.phoneE164 == phoneE164)
              .toList(growable: false);

    return DuplicatePersonMatches(
      nameMatches: nameMatches,
      phoneMatches: phoneMatches,
    );
  }

  static String? _nullableText(String? value) {
    final normalized = normalizePersonText(value ?? '');
    return normalized.isEmpty ? null : normalized;
  }
}
