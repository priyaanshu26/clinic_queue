import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/queue_model.dart';
import '../widgets/status_badge.dart';
import 'login_screen.dart';

class ReceptionistHomeScreen extends StatefulWidget {
  const ReceptionistHomeScreen({super.key});

  @override
  State<ReceptionistHomeScreen> createState() => _ReceptionistHomeScreenState();
}

class _ReceptionistHomeScreenState extends State<ReceptionistHomeScreen> {
  final _api = ApiService();
  List<QueueModel> _queue = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}";
      final data = await _api.getDailyQueue(dateStr);
      setState(() => _queue = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(int id, String newStatus) async {
    try {
      await _api.updateQueueStatus(id, newStatus);
      if (!mounted) return;
      _loadQueue();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    }
  }

  void _showStatusUpdate(QueueModel item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('Update Patient Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          _statusOption(ctx, item.id, 'in-progress', Icons.play_circle_outline, Colors.blue),
          _statusOption(ctx, item.id, 'skipped', Icons.skip_next_outlined, Colors.orange),
          _statusOption(ctx, item.id, 'done', Icons.check_circle_outline, Colors.green),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _statusOption(BuildContext ctx, int id, String status, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      onTap: () {
        Navigator.pop(ctx);
        _updateStatus(id, status);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(_api.currentUser?.name ?? 'Receptionist', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Clinic Reception', style: TextStyle(fontSize: 12)),
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
              ? ListView(children: [SizedBox(height: MediaQuery.of(context).size.height*0.3), const Center(child: Text('No entries for today'))])
                : ListView.builder(
                    itemCount: _queue.length,
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (context, index) {
                      final item = _queue[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.indigo[50],
                              radius: 24,
                              child: Text('${item.tokenNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
                            ),
                            title: Text(item.patientName ?? 'Guest Patient', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                if (item.patientPhone != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.phone, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(item.patientPhone!, style: const TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                const SizedBox(height: 8),
                                StatusBadge(status: item.status),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => _showStatusUpdate(item),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo[50],
                                foregroundColor: Colors.indigo,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              child: const Text('UPDATE'),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
    );
  }
}
