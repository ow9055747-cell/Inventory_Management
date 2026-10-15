import 'package:inventory/Database/store.dart';
import 'package:inventory/Database/userDatabase.dart';
import 'package:inventory/model/usermodel.dart';

class SeedService {
  final Userdatabase userDb;

  SeedService(ObjectBoxService db) : userDb = Userdatabase(db);

  void seedSuperadmin() {
    const email = 'superadmin@example.com';
    const passcode = 'Admin@123';

    final users = userDb.getAllUsers();

    // Find existing Superadmin by role
    final existingAdmins = users.where(
      (user) =>
          user.role.trim().toLowerCase().replaceAll(' ', '') == 'superadmin',
    );

    if (existingAdmins.isNotEmpty) {
      final admin = existingAdmins.first;

      // Migrate the old record if its email is empty
      if (admin.email.trim().isEmpty) {
        final updated = userDb.updateExistingUserEmail(
          id: admin.id,
          newEmail: email,
        );

        print('Existing Superadmin found.');
        print('Superadmin ID: ${admin.id}');
        print('Email migration result: $updated');
        return;
      }

      // Existing Superadmin already has an email
      print('Superadmin already exists.');
      print('Superadmin ID: ${admin.id}');
      print('Superadmin email: ${admin.email}');
      return;
    }

    // Check whether the email is already registered
    if (userDb.emailExists(email)) {
      print('This email is already registered.');
      return;
    }

    // Create a new Superadmin only if none exists
    final superadmin = UserModel(
      name: 'Superadmin',
      email: email,
      warehouseId: 0,
      role: 'superadmin',
      passcode: passcode,
    );

    final generatedId = userDb.addUser(superadmin);

    print('Superadmin seeded successfully!');
    print('Superadmin ID: $generatedId');
    print('Superadmin email: ${superadmin.email}');
  }
}
