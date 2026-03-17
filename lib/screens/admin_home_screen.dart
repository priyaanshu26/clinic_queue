import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/status_badge.dart';
import 'login_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;

  Map<String, dynamic>? _clinicInfo;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final info = await _api.getClinicInfo();
      final users = await _api.getAdminUsers();
      setState(() {
        _clinicInfo = info;
        _users = users;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _logout() {
    _api.logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddUserDialog(onSuccess: _fetchData),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _clinicInfo == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Column(
          children: [
            Text(_api.currentUser?.name ?? 'Admin', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Administrator Dashboard', style: TextStyle(fontSize: 12)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.business_outlined), text: 'Clinic Info'),
            Tab(icon: Icon(Icons.people_alt_outlined), text: 'Manage Users'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildClinicInfo(),
          _buildUsersList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
      ),
    );
  }

  Widget _buildClinicInfo() {
    if (_clinicInfo == null) return const Center(child: Text('No Info Available'));
    
    // Statistics can be flat in the response
    final Map<String, dynamic> stats = {
      'users': _clinicInfo!['userCount'] ?? 0,
      'appointments': _clinicInfo!['appointmentCount'] ?? 0,
      'queue': _clinicInfo!['queueCount'] ?? 0,
    };

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Clinic Details Section
          const Text('CLINIC DETAILS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1, fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.apartment, color: Colors.indigo),
                  title: const Text('Clinic Name'),
                  subtitle: Text(_clinicInfo!['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const Divider(height: 1, indent: 60),
                ListTile(
                  leading: const Icon(Icons.vpn_key_outlined, color: Colors.indigo),
                  title: const Text('Clinic Code'),
                  subtitle: Text(_clinicInfo!['code'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          // Statistics Section
          const Text('STATISTICS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1, fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: stats.entries.map((e) => _buildStatCard(e.key.toUpperCase(), e.value.toString())).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    return RefreshIndicator(
      onRefresh: _fetchData,
      child: _users.isEmpty
        ? ListView(children: [SizedBox(height: MediaQuery.of(context).size.height*0.3), const Center(child: Text('No users found'))])
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final u = _users[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo[50],
                    child: const Icon(Icons.person, color: Colors.indigo),
                  ),
                  title: Text(u['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(u['email'] ?? '', style: const TextStyle(fontSize: 13)),
                  trailing: StatusBadge(status: u['role'] ?? 'user'),
                ),
              );
            },
          ),
    );
  }
}

class _AddUserDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  const _AddUserDialog({required this.onSuccess});

  @override
  _AddUserDialogState createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _phoneController = TextEditingController();
  String _role = 'patient';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New User'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => v!.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
                validator: (v) => v!.isEmpty ? 'Email is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _role,
                items: ['patient', 'doctor', 'receptionist']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase())))
                    .toList(),
                onChanged: (v) => setState(() => _role = v!),
                decoration: const InputDecoration(labelText: 'Assigned Role', prefixIcon: Icon(Icons.badge_outlined)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number (Optional)', prefixIcon: Icon(Icons.phone_outlined)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24)),
          child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('CREATE'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ApiService().createUser(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
        role: _role,
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User created successfully'), backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
