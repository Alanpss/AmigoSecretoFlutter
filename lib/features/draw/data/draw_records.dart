import '../domain/draw_models.dart';

enum PersistedDrawStatus { active, invalidated }

class DrawRecord {
  const DrawRecord({
    required this.id,
    required this.eventId,
    required this.createdAt,
    required this.algorithmVersion,
    required this.pairingRevision,
    required this.status,
    this.invalidatedAt,
  });

  final String id;
  final String eventId;
  final DateTime createdAt;
  final int algorithmVersion;
  final int pairingRevision;
  final PersistedDrawStatus status;
  final DateTime? invalidatedAt;

  DrawRecord copyWith({PersistedDrawStatus? status, DateTime? invalidatedAt}) {
    return DrawRecord(
      id: id,
      eventId: eventId,
      createdAt: createdAt,
      algorithmVersion: algorithmVersion,
      pairingRevision: pairingRevision,
      status: status ?? this.status,
      invalidatedAt: invalidatedAt ?? this.invalidatedAt,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'eventId': eventId,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'algorithmVersion': algorithmVersion,
    'pairingRevision': pairingRevision,
    'status': status.name,
    'invalidatedAt': invalidatedAt?.toUtc().toIso8601String(),
  };

  factory DrawRecord.fromMap(Map<String, Object?> map) {
    return DrawRecord(
      id: map['id'] as String,
      eventId: map['eventId'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      algorithmVersion: (map['algorithmVersion'] as num).toInt(),
      pairingRevision: (map['pairingRevision'] as num).toInt(),
      status: PersistedDrawStatus.values.firstWhere(
        (value) => value.name == map['status'],
        orElse: () => PersistedDrawStatus.invalidated,
      ),
      invalidatedAt: (map['invalidatedAt'] as String?) == null
          ? null
          : DateTime.parse(map['invalidatedAt'] as String),
    );
  }
}

class AssignmentRecord {
  const AssignmentRecord({
    required this.id,
    required this.drawId,
    required this.eventId,
    required this.giverParticipantId,
    required this.receiverParticipantId,
  });

  final String id;
  final String drawId;
  final String eventId;
  final String giverParticipantId;
  final String receiverParticipantId;

  Map<String, Object?> toMap() => {
    'id': id,
    'drawId': drawId,
    'eventId': eventId,
    'giverParticipantId': giverParticipantId,
    'receiverParticipantId': receiverParticipantId,
  };

  factory AssignmentRecord.fromMap(Map<String, Object?> map) {
    return AssignmentRecord(
      id: map['id'] as String,
      drawId: map['drawId'] as String,
      eventId: map['eventId'] as String,
      giverParticipantId: map['giverParticipantId'] as String,
      receiverParticipantId: map['receiverParticipantId'] as String,
    );
  }
}

class DeliveryRecord {
  const DeliveryRecord({
    required this.id,
    required this.drawId,
    required this.assignmentId,
    required this.eventId,
    required this.ownerParticipantId,
    required this.ownerNameSnapshot,
    required this.drawnNameSnapshot,
    required this.createdAt,
    required this.recipientKind,
    required this.recipientNameSnapshot,
    required this.channel,
    required this.status,
    required this.messageSnapshot,
    this.recipientPersonId,
    this.recipientPhoneSnapshot,
    this.openedAt,
    this.confirmedAt,
    this.confirmationMethod,
  });

  final String id;
  final String drawId;
  final String assignmentId;
  final String eventId;
  final String ownerParticipantId;
  final String ownerNameSnapshot;
  final String drawnNameSnapshot;
  final DateTime createdAt;
  final String recipientKind;
  final String? recipientPersonId;
  final String recipientNameSnapshot;
  final String? recipientPhoneSnapshot;
  final String channel;
  final String status;
  final String messageSnapshot;
  final DateTime? openedAt;
  final DateTime? confirmedAt;
  final String? confirmationMethod;

  DeliveryRecord copyWith({
    String? status,
    String? messageSnapshot,
    DateTime? openedAt,
    DateTime? confirmedAt,
    String? confirmationMethod,
  }) {
    return DeliveryRecord(
      id: id,
      drawId: drawId,
      assignmentId: assignmentId,
      eventId: eventId,
      ownerParticipantId: ownerParticipantId,
      ownerNameSnapshot: ownerNameSnapshot,
      drawnNameSnapshot: drawnNameSnapshot,
      createdAt: createdAt,
      recipientKind: recipientKind,
      recipientPersonId: recipientPersonId,
      recipientNameSnapshot: recipientNameSnapshot,
      recipientPhoneSnapshot: recipientPhoneSnapshot,
      channel: channel,
      status: status ?? this.status,
      messageSnapshot: messageSnapshot ?? this.messageSnapshot,
      openedAt: openedAt ?? this.openedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      confirmationMethod: confirmationMethod ?? this.confirmationMethod,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'drawId': drawId,
    'assignmentId': assignmentId,
    'eventId': eventId,
    'ownerParticipantId': ownerParticipantId,
    'ownerNameSnapshot': ownerNameSnapshot,
    'drawnNameSnapshot': drawnNameSnapshot,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'recipientKind': recipientKind,
    'recipientPersonId': recipientPersonId,
    'recipientNameSnapshot': recipientNameSnapshot,
    'recipientPhoneSnapshot': recipientPhoneSnapshot,
    'channel': channel,
    'status': status,
    'messageSnapshot': messageSnapshot,
    'openedAt': openedAt?.toUtc().toIso8601String(),
    'confirmedAt': confirmedAt?.toUtc().toIso8601String(),
    'confirmationMethod': confirmationMethod,
  };

  factory DeliveryRecord.fromMap(Map<String, Object?> map) {
    DateTime? parseDate(String key) {
      final value = map[key] as String?;
      return value == null ? null : DateTime.parse(value);
    }

    return DeliveryRecord(
      id: map['id'] as String,
      drawId: map['drawId'] as String,
      assignmentId: map['assignmentId'] as String,
      eventId: map['eventId'] as String,
      ownerParticipantId: map['ownerParticipantId'] as String,
      ownerNameSnapshot: map['ownerNameSnapshot'] as String? ?? '',
      drawnNameSnapshot: map['drawnNameSnapshot'] as String? ?? '',
      createdAt: DateTime.parse(
        map['createdAt'] as String? ??
            DateTime.fromMillisecondsSinceEpoch(
              0,
              isUtc: true,
            ).toIso8601String(),
      ),
      recipientKind: map['recipientKind'] as String,
      recipientPersonId: map['recipientPersonId'] as String?,
      recipientNameSnapshot: map['recipientNameSnapshot'] as String,
      recipientPhoneSnapshot: map['recipientPhoneSnapshot'] as String?,
      channel: map['channel'] as String,
      status: map['status'] as String,
      messageSnapshot: map['messageSnapshot'] as String,
      openedAt: parseDate('openedAt'),
      confirmedAt: parseDate('confirmedAt'),
      confirmationMethod: map['confirmationMethod'] as String?,
    );
  }
}

class PersistedDraw {
  const PersistedDraw({
    required this.draw,
    required this.assignments,
    required this.deliveries,
  });

  final DrawRecord draw;
  final List<AssignmentRecord> assignments;
  final List<DeliveryRecord> deliveries;

  Map<String, String> get pairing => {
    for (final assignment in assignments)
      assignment.giverParticipantId: assignment.receiverParticipantId,
  };
}

class DrawPreparation {
  const DrawPreparation({
    required this.eventId,
    required this.pairingRevision,
    required this.request,
    required this.hasActiveDraw,
  });

  final String eventId;
  final int pairingRevision;
  final DrawRequest request;
  final bool hasActiveDraw;
}
