/// Model for a queue entry as returned by GET /queue?date= (Receptionist view)
class QueueModel {
  final int id;
  final int tokenNumber;
  final String status; // waiting | in_progress | done | skipped
  final String queueDate;
  final int? appointmentId;
  final String? patientName;
  final String? patientPhone;

  const QueueModel({
    required this.id,
    required this.tokenNumber,
    required this.status,
    required this.queueDate,
    this.appointmentId,
    this.patientName,
    this.patientPhone,
  });

  factory QueueModel.fromJson(Map<String, dynamic> json) {
    // Patient info may be nested inside appointment.patient
    String? name;
    String? phone;
    final appt = json['appointment'] as Map<String, dynamic>?;
    if (appt != null) {
      final patient = appt['patient'] as Map<String, dynamic>?;
      if (patient != null) {
        name = patient['name'] as String?;
        phone = patient['phone'] as String?;
      }
    }

    return QueueModel(
      id: json['id'] as int? ?? 0,
      tokenNumber: json['tokenNumber'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      queueDate: json['queueDate'] as String? ?? '',
      appointmentId: json['appointmentId'] as int?,
      patientName: name,
      patientPhone: phone,
    );
  }
}
