/// Vínculo de uma pessoa com um evento.
class Participant {
  const Participant({
    required this.id,
    required this.eventId,
    required this.personId,
    required this.isActive,
    required this.guardianPersonId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String eventId;
  final String personId;
  final bool isActive;

  /// Pessoa que recebe a mensagem no lugar do participante.
  ///
  /// Referencia `Person` diretamente; nunca há cadeia de responsáveis.
  final String? guardianPersonId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Participant copyWith({
    bool? isActive,
    String? guardianPersonId,
    bool clearGuardian = false,
    DateTime? updatedAt,
  }) {
    return Participant(
      id: id,
      eventId: eventId,
      personId: personId,
      isActive: isActive ?? this.isActive,
      guardianPersonId: clearGuardian
          ? null
          : guardianPersonId ?? this.guardianPersonId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'personId': personId,
      'isActive': isActive,
      'guardianPersonId': guardianPersonId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Participant.fromMap(Map<String, Object?> map) {
    return Participant(
      id: map['id'] as String,
      eventId: map['eventId'] as String,
      personId: map['personId'] as String,
      isActive: map['isActive'] as bool? ?? true,
      guardianPersonId: map['guardianPersonId'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
