import 'dart:math';

import 'matching.dart';
import 'draw_models.dart';

/// Verifica viabilidade e amostra uniformemente entre os pareamentos válidos.
///
/// O algoritmo não lê nem altera persistência, widgets ou serviços externos.
class DrawEngine {
  const DrawEngine();

  DrawEngineResult draw(DrawRequest request, {Random? random}) {
    final participantIds = request.participantIds.toSet().toList()..sort();
    if (participantIds.length != request.participantIds.length) {
      throw ArgumentError('Os IDs dos participantes devem ser únicos.');
    }

    final allowedReceivers = _allowedReceivers(participantIds, request.groups);
    if (participantIds.length < 2) {
      return DrawEngineResult.impossible(
        _diagnose(request, participantIds, allowedReceivers),
      );
    }

    final initial = BipartiteMatching.solve(participantIds, allowedReceivers);

    if (initial.pairByGiver.length != participantIds.length) {
      return DrawEngineResult.impossible(
        _diagnose(request, participantIds, allowedReceivers),
      );
    }

    final rng = random ?? Random.secure();
    final giverToReceiver = Map<String, String>.from(initial.pairByGiver);
    final receiverToGiver = Map<String, String>.from(initial.pairByReceiver);

    for (final giver in participantIds) {
      final currentReceiver = giverToReceiver[giver]!;
      final candidates = <String>[];
      final pathByReceiver = <String, _AlternatingPath>{};

      for (final receiver in allowedReceivers[giver]!) {
        if (receiver == currentReceiver) {
          candidates.add(receiver);
          continue;
        }

        final displacedGiver = receiverToGiver[receiver];
        if (displacedGiver == null || displacedGiver == giver) {
          continue;
        }

        final path = _findAlternatingPath(
          startGiver: displacedGiver,
          targetReceiver: currentReceiver,
          givers: participantIds,
          receiversByGiver: allowedReceivers,
          giverToReceiver: giverToReceiver,
          receiverToGiver: receiverToGiver,
          excludedGiver: giver,
        );
        if (path != null) {
          candidates.add(receiver);
          pathByReceiver[receiver] = path;
        }
      }

      final selectedReceiver = candidates[rng.nextInt(candidates.length)];
      if (selectedReceiver != currentReceiver) {
        final path = pathByReceiver[selectedReceiver]!;
        giverToReceiver.remove(giver);
        receiverToGiver.remove(currentReceiver);

        for (final step in path.steps) {
          giverToReceiver[step.giverId] = step.receiverId;
          receiverToGiver[step.receiverId] = step.giverId;
        }

        giverToReceiver[giver] = selectedReceiver;
        receiverToGiver[selectedReceiver] = giver;
      }
    }

    return DrawEngineResult.success(Map.unmodifiable(giverToReceiver));
  }

  Map<String, List<String>> _allowedReceivers(
    List<String> participantIds,
    List<DrawGroupConstraint> groups,
  ) {
    final blocked = <String, Set<String>>{
      for (final id in participantIds) id: <String>{},
    };

    for (final group in groups.where((group) => group.isEnabled)) {
      final members = group.participantIds
          .where(blocked.containsKey)
          .toList(growable: false);
      for (final giver in members) {
        blocked[giver]!.addAll(members.where((receiver) => receiver != giver));
      }
    }

    return {
      for (final giver in participantIds)
        giver: participantIds
            .where(
              (receiver) =>
                  receiver != giver && !blocked[giver]!.contains(receiver),
            )
            .toList(growable: false),
    };
  }

  DrawDiagnostics _diagnose(
    DrawRequest request,
    List<String> participantIds,
    Map<String, List<String>> allowedReceivers,
  ) {
    final withoutOptions = participantIds
        .where((id) => allowedReceivers[id]!.isEmpty)
        .toList(growable: false);
    final enabledGroups = request.groups
        .where((group) => group.isEnabled)
        .toList(growable: false);
    final oversizedGroups = enabledGroups
        .where(
          (group) =>
              group.participantIds.intersection(participantIds.toSet()).length >
              participantIds.length / 2,
        )
        .map((group) => group.name)
        .toList(growable: false);
    final restorableGroups = <String>[];

    for (final group in enabledGroups) {
      final alternativeGroups = request.groups
          .map(
            (candidate) => DrawGroupConstraint(
              id: candidate.id,
              name: candidate.name,
              participantIds: candidate.participantIds,
              isEnabled: candidate.isEnabled && candidate.id != group.id,
            ),
          )
          .toList(growable: false);
      final alternativeAllowed = _allowedReceivers(
        participantIds,
        alternativeGroups,
      );
      final alternativeMatching = BipartiteMatching.solve(
        participantIds,
        alternativeAllowed,
      );
      if (alternativeMatching.pairByGiver.length == participantIds.length) {
        restorableGroups.add(group.name);
      }
    }

    final message = participantIds.length < 2
        ? 'O sorteio precisa de pelo menos 2 participantes ativos.'
        : withoutOptions.isNotEmpty
        ? 'Há participante sem nenhuma opção válida. Revise os grupos com restrição.'
        : oversizedGroups.isNotEmpty
        ? 'Um grupo restrito reúne mais da metade dos participantes ativos.'
        : 'As restrições atuais não permitem completar o sorteio.';

    return DrawDiagnostics(
      message: message,
      participantsWithoutOptions: withoutOptions,
      groupsLargerThanHalf: oversizedGroups,
      groupsThatWouldRestorePossibility: restorableGroups,
    );
  }

  _AlternatingPath? _findAlternatingPath({
    required String startGiver,
    required String targetReceiver,
    required List<String> givers,
    required Map<String, List<String>> receiversByGiver,
    required Map<String, String> giverToReceiver,
    required Map<String, String> receiverToGiver,
    required String excludedGiver,
  }) {
    final queue = <String>[startGiver];
    var head = 0;
    final visitedGivers = <String>{startGiver};
    final visitedReceivers = <String>{};
    final parentReceiver = <String, String>{};
    final parentGiver = <String, String>{};

    while (head < queue.length) {
      final giver = queue[head++];
      for (final receiver in receiversByGiver[giver] ?? const []) {
        if (giverToReceiver[giver] == receiver ||
            !visitedReceivers.add(receiver)) {
          continue;
        }
        parentReceiver[receiver] = giver;
        if (receiver == targetReceiver) {
          final reversedSteps = <_AlternatingStep>[];
          var currentReceiver = targetReceiver;
          while (true) {
            final currentGiver = parentReceiver[currentReceiver]!;
            reversedSteps.add(_AlternatingStep(currentGiver, currentReceiver));
            if (currentGiver == startGiver) {
              break;
            }
            currentReceiver = parentGiver[currentGiver]!;
          }
          return _AlternatingPath(reversedSteps.reversed.toList());
        }

        final matchedGiver = receiverToGiver[receiver];
        if (matchedGiver != null &&
            matchedGiver != excludedGiver &&
            visitedGivers.add(matchedGiver)) {
          parentGiver[matchedGiver] = receiver;
          queue.add(matchedGiver);
        }
      }
    }
    return null;
  }
}

class _AlternatingPath {
  const _AlternatingPath(this.steps);

  final List<_AlternatingStep> steps;
}

class _AlternatingStep {
  const _AlternatingStep(this.giverId, this.receiverId);

  final String giverId;
  final String receiverId;
}
