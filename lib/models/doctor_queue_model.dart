/// Model for items returned by GET /doctor/queue
class DoctorQueueModel {
  final int id;
  final int tokenNumber;
  final String status;
  final String patientName;
  final int? patientId;
  final int? appointmentId;

  const DoctorQueueModel({
    required this.id,
    required this.tokenNumber,
    required this.status,
    required this.patientName,
    this.patientId,
    this.appointmentId,
  });

  factory DoctorQueueModel.fromJson(Map<String, dynamic> json) {
    return DoctorQueueModel(
      id: json['id'] as int? ?? 0,
      tokenNumber: json['tokenNumber'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      patientName: json['patientName'] as String? ?? 'Unknown',
      patientId: json['patientId'] as int?,
      appointmentId: json['appointmentId'] as int?,
    );
  }
}
