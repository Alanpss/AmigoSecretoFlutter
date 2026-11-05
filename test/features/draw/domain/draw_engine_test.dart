import 'dart:math';

import 'package:amigo_secreto/features/draw/domain/draw_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = DrawEngine();

  DrawRequest request(
    List<String> ids, [
    List<DrawGroupConstraint> groups = const [],
  ]) {
    return DrawRequest(participantIds: ids, groups: groups);
  }

  test('bloqueia zero ou um participante ativo', () {
    final empty = engine.draw(request(const []));
    final one = engine.draw(request(const ['ana']));

    expect(empty.isPossible, isFalse);
    expect(empty.diagnostics!.message, contains('pelo menos 2'));
    expect(one.isPossible, isFalse);
    expect(one.diagnostics!.message, contains('pelo menos 2'));
  });

  test('diagnostica grupo restrito grande e sugere relaxá-lo', () {
    final result = engine.draw(
      request(
        const ['ana', 'bia', 'caio', 'duda'],
        const [
          DrawGroupConstraint(
            id: 'family',
            name: 'Família',
            participantIds: {'ana', 'bia', 'caio'},
            isEnabled: true,
          ),
        ],
      ),
    );

    expect(result.isPossible, isFalse);
    expect(result.diagnostics!.groupsLargerThanHalf, ['Família']);
    expect(result.diagnostics!.groupsThatWouldRestorePossibility, ['Família']);
  });

  test('identifica participante sem nenhuma opção válida', () {
    final result = engine.draw(
      request(
        const ['ana', 'bia', 'caio', 'duda'],
        const [
          DrawGroupConstraint(
            id: 'ana-bia',
            name: 'Grupo A',
            participantIds: {'ana', 'bia'},
            isEnabled: true,
          ),
          DrawGroupConstraint(
            id: 'ana-caio',
            name: 'Grupo B',
            participantIds: {'ana', 'caio'},
            isEnabled: true,
          ),
          DrawGroupConstraint(
            id: 'ana-duda',
            name: 'Grupo C',
            participantIds: {'ana', 'duda'},
            isEnabled: true,
          ),
        ],
      ),
    );

    expect(result.isPossible, isFalse);
    expect(result.diagnostics!.participantsWithoutOptions, ['ana']);
    expect(result.diagnostics!.message, contains('sem nenhuma opção válida'));
  });

  test('não relaxa silenciosamente restrições de vários grupos', () {
    final result = engine.draw(
      request(
        const ['ana', 'bia', 'caio'],
        const [
          DrawGroupConstraint(
            id: 'family',
            name: 'Família',
            participantIds: {'ana', 'bia', 'caio'},
            isEnabled: true,
          ),
        ],
      ),
    );

    expect(result.isPossible, isFalse);
    expect(result.assignments, isEmpty);
    expect(result.diagnostics!.message, contains('grupos com restrição'));
    expect(result.diagnostics!.groupsThatWouldRestorePossibility, ['Família']);
  });

  test(
    'matching válido respeita grupos sobrepostos e aceita vários ciclos',
    () {
      const ids = ['ana', 'bia', 'caio', 'duda'];
      final result = engine.draw(
        request(ids, const [
          DrawGroupConstraint(
            id: 'couple',
            name: 'Casal',
            participantIds: {'ana', 'bia'},
            isEnabled: true,
          ),
          DrawGroupConstraint(
            id: 'family',
            name: 'Família',
            participantIds: {'bia', 'caio'},
            isEnabled: true,
          ),
          DrawGroupConstraint(
            id: 'open',
            name: 'Grupo sem restrição',
            participantIds: {'caio', 'duda'},
            isEnabled: false,
          ),
        ]),
        random: Random(42),
      );

      expect(result.isPossible, isTrue);
      expect(result.assignments.keys, unorderedEquals(ids));
      expect(result.assignments.values.toSet(), unorderedEquals(ids));
      for (final giver in ids) {
        final receiver = result.assignments[giver]!;
        expect(receiver, isNot(giver));
        expect(
          const [
            {'ana', 'bia'},
            {'bia', 'caio'},
          ].any((group) => group.contains(giver) && group.contains(receiver)),
          isFalse,
        );
      }
    },
  );

  test('amostra uniformemente as duas derangements de três participantes', () {
    const ids = ['ana', 'bia', 'caio'];
    final random = Random(9876);
    final counts = <String, int>{};

    for (var i = 0; i < 10000; i++) {
      final result = engine.draw(request(ids), random: random);
      expect(result.isPossible, isTrue);
      final signature = ids.map((id) => result.assignments[id]).join(',');
      counts.update(signature, (count) => count + 1, ifAbsent: () => 1);
    }

    expect(counts, hasLength(2));
    final frequencies = counts.values.toList();
    expect((frequencies[0] - frequencies[1]).abs(), lessThan(400));
  });

  test('aceita sorteios que formam mais de um ciclo', () {
    const ids = ['ana', 'bia', 'caio', 'duda'];
    var foundMultipleCycles = false;

    for (var seed = 0; seed < 32 && !foundMultipleCycles; seed++) {
      final result = engine.draw(request(ids), random: Random(seed));
      foundMultipleCycles = _cycleCount(result.assignments) > 1;
    }

    expect(foundMultipleCycles, isTrue);
  });

  test('sorteia 200 participantes ativos', () {
    final ids = List<String>.generate(200, (index) => 'person-$index');

    final result = engine.draw(request(ids), random: Random(7));

    expect(result.isPossible, isTrue);
    expect(result.assignments, hasLength(200));
    expect(result.assignments.values.toSet(), hasLength(200));
    for (final entry in result.assignments.entries) {
      expect(entry.key, isNot(entry.value));
    }
  });
}

int _cycleCount(Map<String, String> assignment) {
  final visited = <String>{};
  var cycles = 0;

  for (final giver in assignment.keys) {
    if (visited.contains(giver)) continue;
    cycles++;
    var current = giver;
    while (visited.add(current)) {
      current = assignment[current]!;
    }
  }

  return cycles;
}
