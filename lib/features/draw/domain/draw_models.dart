/// Restrição de grupo consumida pelo motor de sorteio puro.
class DrawGroupConstraint {
  const DrawGroupConstraint({
    required this.id,
    required this.name,
    required this.participantIds,
    required this.isEnabled,
  });

  final String id;
  final String name;
  final Set<String> participantIds;
  final bool isEnabled;
}

/// Entrada imutável para verificar e gerar um sorteio.
class DrawRequest {
  const DrawRequest({required this.participantIds, required this.groups});

  final List<String> participantIds;
  final List<DrawGroupConstraint> groups;
}

/// Um par proibido, tratado como não ordenado.
class DrawPair {
  const DrawPair(this.giverId, this.receiverId);

  final String giverId;
  final String receiverId;

  bool matches(String first, String second) {
    return (giverId == first && receiverId == second) ||
        (giverId == second && receiverId == first);
  }
}

/// Explicações e sugestões quando não existe um pareamento perfeito.
class DrawDiagnostics {
  const DrawDiagnostics({
    required this.message,
    this.participantsWithoutOptions = const [],
    this.groupsLargerThanHalf = const [],
    this.groupsThatWouldRestorePossibility = const [],
  });

  final String message;
  final List<String> participantsWithoutOptions;
  final List<String> groupsLargerThanHalf;
  final List<String> groupsThatWouldRestorePossibility;
}

/// Saída do motor. `assignments` só existe quando todo ativo tem um par.
class DrawEngineResult {
  const DrawEngineResult.success(this.assignments) : diagnostics = null;

  const DrawEngineResult.impossible(this.diagnostics) : assignments = const {};

  final Map<String, String> assignments;
  final DrawDiagnostics? diagnostics;

  bool get isPossible => diagnostics == null;
}
