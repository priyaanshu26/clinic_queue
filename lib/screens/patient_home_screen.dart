import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/appointment_model.dart';
import '../widgets/status_badge.dart';
import 'login_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  final _api = ApiService();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            children: [
              Text(_api.currentUser?.name ?? 'Patient', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Text('Patient Portal', style: TextStyle(fontSize: 12)),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'Logout',
              icon: const Icon(Icons.logout),
              onPressed: () {
                _api.logout();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const LoginScreen()));
              },
            )
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.calendar_today_outlined), text: 'Appointments'),
              Tab(icon: Icon(Icons.medication_outlined), text: 'Prescriptions'),
              Tab(icon: Icon(Icons.description_outlined), text: 'Reports'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AppointmentsTab(),
            _PrescriptionsTab(),
            _ReportsTab(),
          ],
        ),
      ),
    );
  }
}

class _AppointmentsTab extends StatefulWidget {
  const _AppointmentsTab();
  @override
  State<_AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<_AppointmentsTab> {
  final _api = ApiService();
  List<AppointmentModel> _data = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.getMyAppointments();
      setState(() => _data = res);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      final days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
      return "${days[date.weekday % 7]}, ${months[date.month - 1]} ${date.day}, ${date.year}";
    } catch (e) {
      return isoDate;
    }
  }

  void _showBookDialog() {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    double durationMinutes = 15;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          String apiDateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
          String displayDateStr = _formatDate(apiDateStr);
          
          // Calculate end time
          final startTime = DateTime(2000, 1, 1, selectedTime.hour, selectedTime.minute);
          final endTime = startTime.add(Duration(minutes: durationMinutes.toInt()));
          String timeSlot = "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}-${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}";

          return AlertDialog(
            title: const Text('Book Appointment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Date', style: TextStyle(fontWeight: FontWeight.bold)),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_month, color: Colors.indigo),
                  title: Text(displayDateStr),
                  trailing: const Icon(Icons.edit, size: 20),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text('Start Time', style: TextStyle(fontWeight: FontWeight.bold)),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time_filled, color: Colors.indigo),
                  title: Text(selectedTime.format(context)),
                  trailing: const Icon(Icons.edit, size: 20),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (picked != null) {
                      setDialogState(() => selectedTime = picked);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Text('Duration: ${durationMinutes.toInt()} mins', style: const TextStyle(fontWeight: FontWeight.bold)),
                Slider(
                  value: durationMinutes,
                  min: 10,
                  max: 60,
                  divisions: 10,
                  label: '${durationMinutes.toInt()} mins',
                  onChanged: (v) => setDialogState(() => durationMinutes = v),
                ),
                const Divider(),
                Text('Timeslot: $timeSlot', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(ctx);
                  try {
                    await _api.bookAppointment(apiDateStr, timeSlot);
                    if (!mounted) return;
                    navigator.pop();
                    _load();
                    messenger.showSnackBar(const SnackBar(content: Text('Appointment booked successfully')));
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text('Confirm Booking'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showBookDialog,
        label: const Text('New Appointment'),
        icon: const Icon(Icons.add),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: _data.isEmpty 
              ? ListView(children: [SizedBox(height: MediaQuery.of(context).size.height*0.3), const Center(child: Text('No appointments found'))])
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _data.length,
                  itemBuilder: (c, i) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.calendar_today, color: Colors.indigo),
                        ),
                        title: Text(_formatDate(_data[i].appointmentDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Time: ${_data[i].timeSlot}'),
                        trailing: StatusBadge(status: _data[i].status),
                      ),
                    ),
                  ),
                ),
          ),
    );
  }
}

class _PrescriptionsTab extends StatefulWidget {
  const _PrescriptionsTab();
  @override
  State<_PrescriptionsTab> createState() => _PrescriptionsTabState();
}

class _PrescriptionsTabState extends State<_PrescriptionsTab> {
  final _api = ApiService();
  List<Map<String, dynamic>> _data = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.getMyPrescriptions();
      setState(() => _data = res);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_data.isEmpty) return const Center(child: Text('No prescriptions found'));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _data.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (c, i) {
          final pr = _data[i];
          final meds = pr['medicines'] as List? ?? [];
          return Card(
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading: const Icon(Icons.medication, color: Colors.indigo),
                title: Text('Prescription #${pr['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(pr['createdAt']?.toString().split('T')[0] ?? 'Recent'),
                children: [
                  const Divider(indent: 16, endIndent: 16),
                  if (pr['notes'] != null && pr['notes'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('Doctor\'s Notes: ${pr['notes']}', style: const TextStyle(fontStyle: FontStyle.italic)),
                    ),
                  ...meds.map((m) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.circle, size: 8, color: Colors.blue),
                    title: Text(m['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Dosage: ${m['dosage']} | Duration: ${m['duration']}'),
                  )),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReportsTab extends StatefulWidget {
  const _ReportsTab();
  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  final _api = ApiService();
  List<Map<String, dynamic>> _data = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.getMyReports();
      setState(() => _data = res);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_data.isEmpty) return const Center(child: Text('No reports found'));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _data.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (c, i) {
          final r = _data[i];
          return Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.description, color: Colors.green),
                ),
                title: Text(r['diagnosis'] ?? 'Clinical Report', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Test: ${r['testRecommended'] ?? '-'}'),
                    Text('Remarks: ${r['remarks'] ?? '-'}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
