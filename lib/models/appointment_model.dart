/// Model for a single queue entry embedded inside an appointment
class QueueEntry {
  final int id;
  final int tokenNumber;
  final String status; // waiting | in_progress | done | skipped
  final String queueDate;

  const QueueEntry({
    required this.id,
    required this.tokenNumber,
    required this.status,
    required this.queueDate,
  });

  factory QueueEntry.fromJson(Map<String, dynamic> json) {
    return QueueEntry(
      id: json['id'] as int? ?? 0,
      tokenNumber: json['tokenNumber'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      queueDate: json['queueDate'] as String? ?? '',
    );
  }
}

/// Model for a patient appointment (GET /appointments/my, GET /appointments/:id)
class AppointmentModel {
  final int id;
  final String appointmentDate;
  final String timeSlot;
  final String status; // scheduled | queued | in_progress | done | cancelled
  final int? patientId;
  final int? clinicId;
  final String? createdAt;
  final QueueEntry? queueEntry;

  const AppointmentModel({
    required this.id,
    required this.appointmentDate,
    required this.timeSlot,
    required this.status,
    this.patientId,
    this.clinicId,
    this.createdAt,
    this.queueEntry,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as int? ?? 0,
      appointmentDate: json['appointmentDate'] as String? ?? '',
      timeSlot: json['timeSlot'] as String? ?? '',
      status: json['status'] as String? ?? '',
      patientId: json['patientId'] as int?,
      clinicId: json['clinicId'] as int?,
      createdAt: json['createdAt'] as String?,
      queueEntry: json['queueEntry'] != null
          ? QueueEntry.fromJson(json['queueEntry'] as Map<String, dynamic>)
          : null,
    );
  }
}
