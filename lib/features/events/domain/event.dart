/// Situação exibida de um evento.
///
/// Na Fase 2 todos os eventos são rascunhos. A situação `drawn` já existe para
/// que a Fase 3 não precise mudar o modelo.
enum EventStatus { draft, drawn }

extension EventStatusLabel on EventStatus {
  String get label => switch (this) {
    EventStatus.draft => 'Rascunho',
    EventStatus.drawn => 'Sorteado',
  };
}

const int maxEventNameLength = 120;
const int maxMessageTemplateLength = 2000;

/// Modelo de mensagem inicial, com variáveis documentadas em `RN-09`.
const String defaultMessageTemplate =
    'Olá, {responsavel}! 🎁\n'
    'Aqui é o Amigo Secreto de {evento}.\n'
    'O resultado de {participante} é: {sorteado}.\n'
    'Guarde este segredo! 🤫';

/// Evento de amigo secreto.
class Event {
  const Event({
    required this.id,
    required this.name,
    required this.eventDate,
    required this.defaultCountryCode,
    required this.messageTemplate,
    required this.activeDrawId,
    required this.pairingRevision,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;

  /// Data sem fuso relevante, sempre à meia-noite local quando informada.
  final DateTime? eventDate;
  final String defaultCountryCode;
  final String messageTemplate;
  final String? activeDrawId;
  final int pairingRevision;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventStatus get status =>
      activeDrawId == null ? EventStatus.draft : EventStatus.drawn;

  Event copyWith({
    String? name,
    DateTime? eventDate,
    bool clearEventDate = false,
    String? defaultCountryCode,
    String? messageTemplate,
    String? activeDrawId,
    bool clearActiveDrawId = false,
    int? pairingRevision,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id,
      name: name ?? this.name,
      eventDate: clearEventDate ? null : eventDate ?? this.eventDate,
      defaultCountryCode: defaultCountryCode ?? this.defaultCountryCode,
      messageTemplate: messageTemplate ?? this.messageTemplate,
      activeDrawId: clearActiveDrawId
          ? null
          : activeDrawId ?? this.activeDrawId,
      pairingRevision: pairingRevision ?? this.pairingRevision,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'eventDate': eventDate == null ? null : _formatDate(eventDate!),
      'defaultCountryCode': defaultCountryCode,
      'messageTemplate': messageTemplate,
      'activeDrawId': activeDrawId,
      'pairingRevision': pairingRevision,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Event.fromMap(Map<String, Object?> map) {
    final eventDateValue = map['eventDate'] as String?;
    return Event(
      id: map['id'] as String,
      name: map['name'] as String,
      eventDate: eventDateValue == null ? null : DateTime.parse(eventDateValue),
      defaultCountryCode: map['defaultCountryCode'] as String? ?? 'BR',
      messageTemplate:
          map['messageTemplate'] as String? ?? defaultMessageTemplate,
      activeDrawId: map['activeDrawId'] as String?,
      pairingRevision: (map['pairingRevision'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-$month-$day';
  }
}
