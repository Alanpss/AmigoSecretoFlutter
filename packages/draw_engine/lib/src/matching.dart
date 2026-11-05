/// Matching bipartido máximo usando Hopcroft–Karp.
class BipartiteMatching {
  const BipartiteMatching._(this.pairByGiver, this.pairByReceiver);

  final Map<String, String> pairByGiver;
  final Map<String, String> pairByReceiver;

  static BipartiteMatching solve(
    List<String> givers,
    Map<String, List<String>> receiversByGiver,
  ) {
    final pairByGiver = <String, String>{};
    final pairByReceiver = <String, String>{};
    final distance = <String, int>{};
    const infinity = 1 << 30;

    bool breadthFirstSearch() {
      final queue = <String>[];
      var head = 0;
      var hasFreeReceiver = false;

      for (final giver in givers) {
        if (!pairByGiver.containsKey(giver)) {
          distance[giver] = 0;
          queue.add(giver);
        } else {
          distance[giver] = infinity;
        }
      }

      while (head < queue.length) {
        final giver = queue[head++];
        for (final receiver in receiversByGiver[giver] ?? const []) {
          final matchedGiver = pairByReceiver[receiver];
          if (matchedGiver == null) {
            hasFreeReceiver = true;
          } else if (distance[matchedGiver] == infinity) {
            distance[matchedGiver] = distance[giver]! + 1;
            queue.add(matchedGiver);
          }
        }
      }
      return hasFreeReceiver;
    }

    bool depthFirstSearch(String giver) {
      for (final receiver in receiversByGiver[giver] ?? const []) {
        final matchedGiver = pairByReceiver[receiver];
        if (matchedGiver == null ||
            (distance[matchedGiver] == distance[giver]! + 1 &&
                depthFirstSearch(matchedGiver))) {
          pairByGiver[giver] = receiver;
          pairByReceiver[receiver] = giver;
          return true;
        }
      }
      distance[giver] = infinity;
      return false;
    }

    while (breadthFirstSearch()) {
      for (final giver in givers) {
        if (!pairByGiver.containsKey(giver)) {
          depthFirstSearch(giver);
        }
      }
    }

    return BipartiteMatching._(pairByGiver, pairByReceiver);
  }
}
