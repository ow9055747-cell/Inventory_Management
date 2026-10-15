import 'package:inventory/Database/store.dart';
import 'package:inventory/model/usermodel.dart';
import 'package:inventory/objectbox.g.dart';

class Userdatabase {
  final ObjectBoxService db;

  Userdatabase(this.db);

  // Add user
  int addUser(UserModel user) {
    db.store.box<UserModel>().put(user);
    return user.id;
  }

  // Get all users
  List<UserModel> getAllUsers() {
    return db.store.box<UserModel>().getAll();
  }

  // Get user by email
  UserModel? getUserByEmail(String email) {
    final userBox = db.store.box<UserModel>();

    final query = userBox
        .query(UserModel_.email.equals(email.trim().toLowerCase()))
        .build();

    try {
      return query.findFirst();
    } finally {
      query.close();
    }
  }

  // Check whether email exists
  bool emailExists(String email) {
    final userBox = db.store.box<UserModel>();

    final query = userBox
        .query(UserModel_.email.equals(email.trim().toLowerCase()))
        .build();

    try {
      return query.count() > 0;
    } finally {
      query.close();
    }
  }

  // Update user using email
  bool updateUser({
    required String email,
    String? name,
    int? warehouseId,
    String? role,
    String? passcode,
    String? branchCode,
    bool clearWarehouseId = false,
    bool clearBranchCode = false,
  }) {
    final userBox = db.store.box<UserModel>();

    final query = userBox
        .query(UserModel_.email.equals(email.trim().toLowerCase()))
        .build();

    try {
      final existingUser = query.findFirst();

      if (existingUser == null) {
        return false;
      }

      final updatedUser = UserModel(
        id: existingUser.id,
        email: existingUser.email,
        name: name ?? existingUser.name,
        warehouseId: clearWarehouseId
            ? null
            : warehouseId ?? existingUser.warehouseId,
        role: role ?? existingUser.role,
        passcode: passcode ?? existingUser.passcode,
        branchCode: clearBranchCode
            ? null
            : branchCode ?? existingUser.branchCode,
      );

      userBox.put(updatedUser);
      return true;
    } finally {
      query.close();
    }
  }

  // Delete user using email
  bool deleteUser(String email) {
    final userBox = db.store.box<UserModel>();

    final query = userBox
        .query(UserModel_.email.equals(email.trim().toLowerCase()))
        .build();

    try {
      final user = query.findFirst();

      if (user == null) {
        return false;
      }

      return userBox.remove(user.id);
    } finally {
      query.close();
    }
  }

  // Delete all users
  void deleteAllUsers() {
    db.store.box<UserModel>().removeAll();
  }

  // Update existing user's email
  bool updateExistingUserEmail({required int id, required String newEmail}) {
    final userBox = db.store.box<UserModel>();
    final user = userBox.get(id);

    if (user == null) {
      print('User not found.');
      return false;
    }

    final email = newEmail.trim().toLowerCase();

    if (email.isEmpty) {
      print('Email cannot be empty.');
      return false;
    }

    final duplicate = getUserByEmail(email);

    if (duplicate != null && duplicate.id != user.id) {
      print('Email already belongs to another user.');
      return false;
    }

    user.email = email;
    userBox.put(user);

    print('Email updated successfully: ${user.email}');
    return true;
  }
}
