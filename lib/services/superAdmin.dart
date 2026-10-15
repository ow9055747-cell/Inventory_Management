import 'package:inventory/Database/store.dart';
import 'package:inventory/Database/userDatabase.dart';
import 'package:inventory/Database/warehouseDatabase.dart';
import 'package:inventory/model/usermodel.dart';
import 'package:inventory/model/warehouse.dart';

class Superadmin {
  final ObjectBoxService db;
  final Userdatabase ob;
  final Warehousedatabase wb;

  Superadmin(this.db) : ob = Userdatabase(db), wb = Warehousedatabase(db);

  // ==================== USER OPERATIONS ====================

  // Create user, including nullable warehouseId and branchCode
  void createUser(UserModel user) {
    ob.addUser(user);
  }

  // Get all admin users
  List<UserModel> getAllUsers() {
    return ob.getAllUsers().where((user) => user.role == 'admin').toList();
  }

  // Get user by email
  UserModel? getUser(String email) {
    return ob.getUserByEmail(email);
  }

  // Update user using email
  bool updateUser({
    required String email,
    String? name,
    int? warehouseId,
    String? role,
    String? passcode,
    String? branchCode,
  }) {
    return ob.updateUser(
      email: email,
      name: name,
      warehouseId: warehouseId,
      role: role,
      passcode: passcode,
      branchCode: branchCode,
    );
  }

  // Delete user using email
  bool deleteUser(String email) {
    return ob.deleteUser(email);
  }

  // Check whether user email exists
  bool emailExists(String email) {
    return ob.emailExists(email);
  }

  // Delete all users
  void deleteAllUsers() {
    ob.deleteAllUsers();
  }

  // ==================== WAREHOUSE OPERATIONS ====================

  // Create warehouse
  void createWarehouse(Warehouse warehouse) {
    wb.addWarehouse(warehouse);
  }

  // Get all warehouses
  List<Warehouse> getAllWarehouses() {
    return wb.getAllWarehouses();
  }

  // Get warehouse by ID
  Warehouse? getWarehouse(int id) {
    return wb.getWarehouse(id);
  }

  // Update warehouse
  void updateWarehouse({
    required int id,
    bool? mainBranch,
    String? name,
    String? branchCode,
    String? address,
  }) {
    wb.updateWarehouse(
      id: id,
      mainBranch: mainBranch,
      name: name,
      branchCode: branchCode,
      address: address,
    );
  }

  // Delete warehouse
  bool deleteWarehouse(int id) {
    return wb.deleteWarehouse(id);
  }

  // Delete all warehouses
  void deleteAllWarehouses() {
    wb.deleteAllWarehouses();
  }
}
