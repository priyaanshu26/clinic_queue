import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/appointment_model.dart';
import '../models/doctor_queue_model.dart';
import '../models/queue_model.dart';
import '../models/user_model.dart';

class ApiService {
  ApiService._internal();
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  String get _baseUrl => dotenv.env['BASE_URL'] ?? 'https://cmsback.sampaarsh.cloud';

  String? _token;
  UserModel? _currentUser;

  String? get token => _token;
  UserModel? get currentUser => _currentUser;
  
  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_token',
  };

  Future<UserModel> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      _token = body['token'];
      _currentUser = UserModel.fromJson(body['user']);
      return _currentUser!;
    }
    throw Exception(jsonDecode(response.body)['error'] ?? 'Login failed');
  }

  void logout() {
    _token = null;
    _currentUser = null;
  }

  // PATIENT
  Future<List<AppointmentModel>> getMyAppointments() async {
    final response = await http.get(Uri.parse('$_baseUrl/appointments/my'), headers: _authHeaders);
    _checkStatus(response);
    final List list = jsonDecode(response.body);
    return list.map((e) => AppointmentModel.fromJson(e)).toList();
  }

  Future<void> bookAppointment(String date, String timeSlot) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/appointments'),
      headers: _authHeaders,
      body: jsonEncode({'appointmentDate': date, 'timeSlot': timeSlot}),
    );
    _checkStatus(response);
  }

  Future<List<Map<String, dynamic>>> getMyPrescriptions() async {
    final response = await http.get(Uri.parse('$_baseUrl/prescriptions/my'), headers: _authHeaders);
    _checkStatus(response);
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  Future<List<Map<String, dynamic>>> getMyReports() async {
    final response = await http.get(Uri.parse('$_baseUrl/reports/my'), headers: _authHeaders);
    _checkStatus(response);
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  // RECEPTIONIST
  Future<List<QueueModel>> getDailyQueue(String date) async {
    final response = await http.get(Uri.parse('$_baseUrl/queue?date=$date'), headers: _authHeaders);
    _checkStatus(response);
    final List list = jsonDecode(response.body);
    return list.map((e) => QueueModel.fromJson(e)).toList();
  }

  Future<void> updateQueueStatus(int queueId, String status) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/queue/$queueId'),
      headers: _authHeaders,
      body: jsonEncode({'status': status}),
    );
    _checkStatus(response);
  }

  // DOCTOR
  Future<List<DoctorQueueModel>> getDoctorQueue() async {
    final response = await http.get(Uri.parse('$_baseUrl/doctor/queue'), headers: _authHeaders);
    _checkStatus(response);
    final List list = jsonDecode(response.body);
    return list.map((e) => DoctorQueueModel.fromJson(e)).toList();
  }

  Future<void> addPrescription(int appointmentId, List<Map<String, String>> medicines, String notes) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/prescriptions/$appointmentId'),
      headers: _authHeaders,
      body: jsonEncode({'medicines': medicines, 'notes': notes}),
    );
    _checkStatus(response);
  }

  Future<void> addReport(int appointmentId, String diagnosis, String testRecommended, String remarks) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/reports/$appointmentId'),
      headers: _authHeaders,
      body: jsonEncode({
        'diagnosis': diagnosis,
        'testRecommended': testRecommended,
        'remarks': remarks,
      }),
    );
    _checkStatus(response);
  }

  // ADMIN
  Future<Map<String, dynamic>> getClinicInfo() async {
    final response = await http.get(Uri.parse('$_baseUrl/admin/clinic'), headers: _authHeaders);
    _checkStatus(response);
    return jsonDecode(response.body);
  }

  Future<List<Map<String, dynamic>>> getAdminUsers() async {
    final response = await http.get(Uri.parse('$_baseUrl/admin/users'), headers: _authHeaders);
    _checkStatus(response);
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  Future<void> createUser({required String name, required String email, required String password, required String role, String? phone}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/admin/users'),
      headers: _authHeaders,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        if (phone != null) 'phone': phone,
      }),
    );
    _checkStatus(response);
  }

  void _checkStatus(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw Exception(jsonDecode(res.body)['error'] ?? 'Error ${res.statusCode}');
  }
}
