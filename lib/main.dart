import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:inventory/Database/store.dart';
import 'package:inventory/controller/Auth.dart';
import 'package:inventory/provider/objectbox.dart';
import 'package:inventory/services/seedService.dart';
import 'package:inventory/view/AdminUi.dart';
import 'package:inventory/view/LoginUi.dart';
import 'package:inventory/view/ShoopkeeperUi.dart';
import 'package:inventory/view/superadminUi.dart';
import 'package:inventory/provider/currentUserProvider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = await ObjectBoxService.create();

  // Seed the default superadmin once.
  SeedService(db).seedSuperadmin();

  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Inventory Management',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2878D0),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF243247),
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const AppRouter(),
    );
  }
}

class AppRouter extends ConsumerWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbState = ref.watch(objectBoxProvider);

    return dbState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        body: Center(child: Text('Database initialization failed: $error')),
      ),
      data: (_) => const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(Authprovider);

    if (user == null) {
      return const LoginScreen();
    }

    final role = user.role
        .trim()
        .toLowerCase()
        .replaceAll('_', '')
        .replaceAll(' ', '');

    switch (role) {
      case 'superadmin':
        return const SuperadminScreen();
      case 'admin':
        return const AdminScreen();
      case 'shopkeeper':
        if (user.warehouseId == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Inventory')),
            body: const Center(
              child: Text(
                'No warehouse is assigned to this shopkeeper. '
                'Please contact the administrator.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ShopkeeperScreen(warehouseId: user.warehouseId!);
      default:
        return Scaffold(
          appBar: AppBar(title: const Text('Inventory')),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Your account role is not recognized.'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.read(Authprovider.notifier).Logout(),
                  child: const Text('Logout'),
                ),
              ],
            ),
          ),
        );
    }
  }
}
