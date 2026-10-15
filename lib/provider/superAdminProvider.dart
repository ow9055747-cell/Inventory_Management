import 'package:riverpod/legacy.dart';

import 'package:inventory/Database/store.dart';
import 'package:inventory/model/supermodel.dart';
import 'package:inventory/model/usermodel.dart';
import 'package:inventory/model/warehouse.dart';
import 'package:inventory/services/superAdmin.dart';

class Supercontroller extends StateNotifier<Supermodel> {
  final ObjectBoxService db;
  final Superadmin service;

  Supercontroller(this.db)
    : service = Superadmin(db),
      super(Supermodel(actual: [], filtered: [], adminsac: [], adminfi: []));

  // ==================== SYNC STATE ====================

  void syncData() {
    final users = service.getAllUsers();
    final warehouses = service.getAllWarehouses();

    state = state.copyWith(
      adminsac: users,
      adminfi: users,
      actual: warehouses,
      filtered: warehouses,
    );
  }

  // ==================== USER OPERATIONS ====================

  void addUser(UserModel user) {
    service.createUser(user);
    syncData();
  }

  List<UserModel> getAlluser() {
    return service.getAllUsers();
  }

  UserModel? getUser(String email) {
    return service.getUser(email);
  }

  bool emailExists(String email) {
    return service.emailExists(email);
  }

  bool updateUser({
    required String email,
    String? name,
    int? warehouseId,
    String? role,
    String? passcode,
    String? branchCode,
  }) {
    final updated = service.updateUser(
      email: email,
      name: name,
      warehouseId: warehouseId,
      role: role,
      passcode: passcode,
      branchCode: branchCode,
    );

    if (updated) {
      syncData();
    }

    return updated;
  }

  bool deleteUser(String email) {
    final deleted = service.deleteUser(email);

    if (deleted) {
      syncData();
    }

    return deleted;
  }

  void deleteAllUsers() {
    service.deleteAllUsers();
    syncData();
  }

  // ==================== USER FILTERS ====================

  void filterUserByEmail(String email) {
    final value = email.trim().toLowerCase();

    state = state.copyWith(
      adminfi: state.adminsac
          .where((user) => user.email.trim().toLowerCase() == value)
          .toList(),
    );
  }

  void filterUserByName(String query) {
    final value = query.trim().toLowerCase();

    state = state.copyWith(
      adminfi: value.isEmpty
          ? state.adminsac
          : state.adminsac
                .where((user) => user.name.toLowerCase().contains(value))
                .toList(),
    );
  }

  void searchUserByEmail(String query) {
    final value = query.trim().toLowerCase();

    state = state.copyWith(
      adminfi: value.isEmpty
          ? state.adminsac
          : state.adminsac
                .where((user) => user.email.toLowerCase().contains(value))
                .toList(),
    );
  }

  void resetUserFilter() {
    state = state.copyWith(adminfi: state.adminsac);
  }

  // ==================== WAREHOUSE OPERATIONS ====================

  List<Warehouse> getAllWarehouses() {
    return service.getAllWarehouses();
  }

  Warehouse? getWarehouse(int id) {
    return service.getWarehouse(id);
  }

  bool warehouseNameExists(String name, {int? excludeId}) {
    final normalizedName = name.trim().toLowerCase();

    if (normalizedName.isEmpty) {
      return false;
    }

    return getAllWarehouses().any((warehouse) {
      if (excludeId != null && warehouse.id == excludeId) {
        return false;
      }

      return warehouse.name.trim().toLowerCase() == normalizedName;
    });
  }

  bool addWarehouse(Warehouse warehouse) {
    final name = warehouse.name.trim();

    if (name.isEmpty || warehouseNameExists(name)) {
      return false;
    }

    final cleanedWarehouse = Warehouse(
      id: warehouse.id,
      mainBranch: warehouse.mainBranch,
      name: name,
      branchCode: warehouse.branchCode.trim(),
      address: warehouse.address.trim(),
    );

    service.createWarehouse(cleanedWarehouse);
    syncData();

    return true;
  }

  bool updateWarehouse({
    required int id,
    bool? mainBranch,
    String? name,
    String? branchCode,
    String? address,
  }) {
    final existingWarehouse = service.getWarehouse(id);

    if (existingWarehouse == null) {
      return false;
    }

    if (name != null) {
      final cleanedName = name.trim();

      if (cleanedName.isEmpty) {
        return false;
      }

      if (warehouseNameExists(cleanedName, excludeId: id)) {
        return false;
      }

      name = cleanedName;
    }

    service.updateWarehouse(
      id: id,
      mainBranch: mainBranch,
      name: name,
      branchCode: branchCode?.trim(),
      address: address?.trim(),
    );

    syncData();

    return true;
  }

  bool deleteWarehouse(int id) {
    final deleted = service.deleteWarehouse(id);

    if (deleted) {
      syncData();
    }

    return deleted;
  }

  void deleteAllWarehouses() {
    service.deleteAllWarehouses();
    syncData();
  }

  // ==================== WAREHOUSE FILTERS ====================

  void filterWarehouseById(int id) {
    state = state.copyWith(
      filtered: state.actual.where((warehouse) => warehouse.id == id).toList(),
    );
  }

  void filterWarehouseByName(String query) {
    final value = query.trim().toLowerCase();

    state = state.copyWith(
      filtered: value.isEmpty
          ? state.actual
          : state.actual
                .where(
                  (warehouse) => warehouse.name.toLowerCase().contains(value),
                )
                .toList(),
    );
  }

  void searchWarehouseById(String query) {
    final value = query.trim();

    state = state.copyWith(
      filtered: value.isEmpty
          ? state.actual
          : state.actual
                .where((warehouse) => warehouse.id.toString().contains(value))
                .toList(),
    );
  }

  void resetWarehouseFilter() {
    state = state.copyWith(filtered: state.actual);
  }
}
