import 'package:inventory/Database/store.dart';
import 'package:inventory/Database/userDatabase.dart';
import 'package:inventory/model/usermodel.dart';

class Adminservice {
  final ObjectBoxService db;
  final Userdatabase userDb;

  Adminservice(this.db) : userDb = Userdatabase(db);

  // ==================== USER OPERATIONS ====================

  // Add user
  void createUser(UserModel user) {
    userDb.addUser(user);
  }

  // Get all users
  List<UserModel> getAllUsers() {
    return userDb.getAllUsers();
  }

  // Get user by email
  UserModel? getUser(String email) {
    return userDb.getUserByEmail(email);
  }

  // Check whether email exists
  bool emailExists(String email) {
    return userDb.emailExists(email);
  }

  // Update user using email
  bool updateUser({
    required String email,
    String? name,
    int? warehouseId,
    String? role,
    String? passcode,
  }) {
    return userDb.updateUser(
      email: email,
      name: name,
      warehouseId: warehouseId,
      role: role,
      passcode: passcode,
    );
  }

  // Delete user using email
  bool deleteUser(String email) {
    return userDb.deleteUser(email);
  }

  // Delete all users
  void deleteAllUsers() {
    userDb.deleteAllUsers();
  }
}
