/// Tipo de agrupamento dentro de um evento.
enum GroupType { family, couple, other }

extension GroupTypeLabel on GroupType {
  String get label => switch (this) {
    GroupType.family => 'Família',
    GroupType.couple => 'Casal',
    GroupType.other => 'Outro',
  };

  String get storageValue => name;

  static GroupType fromStorage(String? value) {
    return GroupType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => GroupType.other,
    );
  }
}

const int maxGroupNameLength = 80;

/// Grupo de participantes do mesmo evento.
///
/// Quando `restrictionEnabled` é verdadeiro, integrantes do grupo não podem
/// tirar uns aos outros. A restrição efetiva é a união dos grupos ativos.
class Group {
  const Group({
    required this.id,
    required this.eventId,
    required this.name,
    required this.type,
    required this.restrictionEnabled,
    required this.memberParticipantIds,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String eventId;
  final String name;
  final GroupType type;
  final bool restrictionEnabled;
  final List<String> memberParticipantIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  Group copyWith({
    String? name,
    GroupType? type,
    bool? restrictionEnabled,
    List<String>? memberParticipantIds,
    DateTime? updatedAt,
  }) {
    return Group(
      id: id,
      eventId: eventId,
      name: name ?? this.name,
      type: type ?? this.type,
      restrictionEnabled: restrictionEnabled ?? this.restrictionEnabled,
      memberParticipantIds: memberParticipantIds ?? this.memberParticipantIds,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'name': name,
      'type': type.storageValue,
      'restrictionEnabled': restrictionEnabled,
      'memberParticipantIds': memberParticipantIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Group.fromMap(Map<String, Object?> map) {
    final members = (map['memberParticipantIds'] as List<Object?>? ?? const [])
        .whereType<String>()
        .toList(growable: false);
    return Group(
      id: map['id'] as String,
      eventId: map['eventId'] as String,
      name: map['name'] as String,
      type: GroupTypeLabel.fromStorage(map['type'] as String?),
      restrictionEnabled: map['restrictionEnabled'] as bool? ?? true,
      memberParticipantIds: members,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
