import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory/controller/Auth.dart';

import 'package:inventory/provider/currentUserProvider.dart';
import 'package:inventory/view/LoginUi.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(Authprovider);

    if (user == null) {
      return const LoginScreen();
    }

    if (user.role.trim().toLowerCase() != 'admin') {
      return const Scaffold(
        body: Center(child: Text('You do not have access to this page.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => ref.read(Authprovider.notifier).Logout(),
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${user.name}',
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Color(0xFF243247),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Admin workspace',
              style: TextStyle(color: Color(0xFF718096)),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE4EAF2)),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.construction_outlined,
                        size: 52,
                        color: Color(0xFF2878D0),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Development in progress',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Admin features will be added here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF718096)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
