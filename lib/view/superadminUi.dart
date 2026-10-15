import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory/controller/Auth.dart';

import 'package:inventory/provider/currentUserProvider.dart';
import 'package:inventory/view/AdminCRUD.dart';
import 'package:inventory/view/LoginUi.dart';
import 'package:inventory/view/warehousemanage.dart';
import 'package:inventory/view/widgets/dashboards.dart';

class SuperadminScreen extends ConsumerWidget {
  const SuperadminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(Authprovider);

    if (user == null) {
      return const LoginScreen();
    }

    if (user.role
            .trim()
            .toLowerCase()
            .replaceAll('_', '')
            .replaceAll(' ', '') !=
        'superadmin') {
      return const Scaffold(
        body: Center(child: Text('You do not have access to this page.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Superadmin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => ref.read(Authprovider.notifier).Logout(),
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFE5F0FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.admin_panel_settings_outlined,
                  color: Color(0xFF2878D0),
                  size: 36,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Welcome, Superadmin',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF243247),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Signed in as ${user.name}',
                  style: const TextStyle(color: Color(0xFF52647A)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Management',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF243247),
            ),
          ),
          const SizedBox(height: 12),
          DashboardTile(
            icon: Icons.people_outline,
            title: 'Admin management',
            subtitle: 'Create and manage admin accounts',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UserManagementScreen(),
              ),
            ),
          ),
          DashboardTile(
            icon: Icons.warehouse_outlined,
            title: 'Warehouse management',
            subtitle: 'Manage warehouse details and branches',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WarehouseManagementScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInProgress(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Development in progress'),
        content: const Text(
          'This section will be connected to the existing functionality.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
