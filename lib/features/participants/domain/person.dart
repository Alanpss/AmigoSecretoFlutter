/// Identidade reutilizável em vários eventos.
///
/// O telefone é armazenado em E.164 (`+` seguido de dígitos) ou nulo.
class Person {
  const Person({
    required this.id,
    required this.name,
    required this.nickname,
    required this.phoneE164,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? nickname;
  final String? phoneE164;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Nome usado nas mensagens: apelido quando preenchido, senão o nome.
  String get displayName => nickname ?? name;

  Person copyWith({
    String? name,
    String? nickname,
    bool clearNickname = false,
    String? phoneE164,
    bool clearPhone = false,
    DateTime? updatedAt,
  }) {
    return Person(
      id: id,
      name: name ?? this.name,
      nickname: clearNickname ? null : nickname ?? this.nickname,
      phoneE164: clearPhone ? null : phoneE164 ?? this.phoneE164,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'nickname': nickname,
      'phoneE164': phoneE164,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Person.fromMap(Map<String, Object?> map) {
    return Person(
      id: map['id'] as String,
      name: map['name'] as String,
      nickname: map['nickname'] as String?,
      phoneE164: map['phoneE164'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
