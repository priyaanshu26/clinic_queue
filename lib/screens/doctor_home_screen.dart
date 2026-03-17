import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/doctor_queue_model.dart';
import '../widgets/status_badge.dart';
import 'login_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  final _api = ApiService();
  List<DoctorQueueModel> _queue = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getDoctorQueue();
      setState(() => _queue = data);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openTreatmentDialog(DoctorQueueModel patient) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text('Serving: ${patient.patientName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.medication, color: Colors.blue),
            title: const Text('Add Prescription'),
            onTap: () {
              Navigator.pop(ctx);
              _showPrescriptionForm(patient);
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment, color: Colors.green),
            title: const Text('Add Medical Report'),
            onTap: () {
              Navigator.pop(ctx);
              _showReportForm(patient);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showPrescriptionForm(DoctorQueueModel patient) {
    final nameCtrl = TextEditingController();
    final doseCtrl = TextEditingController();
    final durCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Prescription Form'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Medicine Name')),
            const SizedBox(height: 8),
            TextField(controller: doseCtrl, decoration: const InputDecoration(labelText: 'Dosage (e.g. 1-0-1)')),
            const SizedBox(height: 8),
            TextField(controller: durCtrl, decoration: const InputDecoration(labelText: 'Duration (e.g. 5 days)')),
            const SizedBox(height: 8),
            TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'General Notes')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final medicines = [{
                  'name': nameCtrl.text.trim(),
                  'dosage': doseCtrl.text.trim(),
                  'duration': durCtrl.text.trim(),
                }];
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(ctx);
                await _api.addPrescription(patient.appointmentId!, medicines, notesCtrl.text.trim());
                if (!mounted) return;
                navigator.pop();
                messenger.showSnackBar(const SnackBar(content: Text('Prescription saved successfully')));
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Save Prescription'),
          ),
        ],
      ),
    );
  }

  void _showReportForm(DoctorQueueModel patient) {
    final diagCtrl = TextEditingController();
    final testCtrl = TextEditingController();
    final remarkCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Medical Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: diagCtrl, decoration: const InputDecoration(labelText: 'Diagnosis')),
            const SizedBox(height: 8),
            TextField(controller: testCtrl, decoration: const InputDecoration(labelText: 'Recommended Tests')),
            const SizedBox(height: 8),
            TextField(controller: remarkCtrl, decoration: const InputDecoration(labelText: 'Remarks')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(ctx);
                await _api.addReport(
                  patient.appointmentId!,
                  diagCtrl.text.trim(),
                  testCtrl.text.trim(),
                  remarkCtrl.text.trim(),
                );
                if (!mounted) return;
                navigator.pop();
                messenger.showSnackBar(const SnackBar(content: Text('Report saved successfully')));
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Save Report'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text('Dr. ${_api.currentUser?.name ?? 'Doctor'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Medical Professional', style: TextStyle(fontSize: 12)),
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
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadQueue,
            child: _queue.isEmpty
                ? ListView(children: [SizedBox(height: MediaQuery.of(context).size.height*0.3), const Center(child: Text('No patients in your queue'))])
                : ListView.builder(
                    itemCount: _queue.length,
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (context, index) {
                      final item = _queue[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo[50],
                            radius: 24,
                            child: Text('${item.tokenNumber}', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                          title: Text(item.patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: StatusBadge(status: item.status),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.indigo),
                          onTap: () => _openTreatmentDialog(item),
                        ),
                      );
                    },
                  ),
          ),
    );
  }
}
