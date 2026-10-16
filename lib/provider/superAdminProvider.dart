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

  // Refresh all data from ObjectBox.
  void syncData() {
    final users = service.getAllUsers();
    final warehouses = service.getAllWarehouses();

    state = state.copyWith(
      adminsac: List<UserModel>.of(users),
      adminfi: List<UserModel>.of(users),
      actual: List<Warehouse>.of(warehouses),
      filtered: List<Warehouse>.of(warehouses),
    );
  }

  // ---------------- USERS ----------------

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
    return service.emailExists(email.trim().toLowerCase());
  }

  bool updateUser({
    required String email,
    String? name,
    int? warehouseId,
    String? role,
    String? passcode,
    String? branchCode,
  }) {
    final success = service.updateUser(
      email: email,
      name: name,
      warehouseId: warehouseId,
      role: role,
      passcode: passcode,
      branchCode: branchCode,
    );

    if (success) {
      syncData();
    }

    return success;
  }

  bool deleteUser(String email) {
    final success = service.deleteUser(email);

    if (success) {
      syncData();
    }

    return success;
  }

  void deleteAllUsers() {
    service.deleteAllUsers();
    syncData();
  }

  // Optional controller-side user filters.
  void filterUserByEmail(String email) {
    final query = email.trim().toLowerCase();

    state = state.copyWith(
      adminfi: state.adminsac
          .where((user) => user.email.toLowerCase() == query)
          .toList(),
    );
  }

  void filterUserByName(String query) {
    final value = query.trim().toLowerCase();

    state = state.copyWith(
      adminfi: value.isEmpty
          ? List<UserModel>.of(state.adminsac)
          : state.adminsac
                .where((user) => user.name.toLowerCase().contains(value))
                .toList(),
    );
  }

  void searchUserByEmail(String query) {
    final value = query.trim().toLowerCase();

    state = state.copyWith(
      adminfi: value.isEmpty
          ? List<UserModel>.of(state.adminsac)
          : state.adminsac
                .where((user) => user.email.toLowerCase().contains(value))
                .toList(),
    );
  }

  void resetUserFilter() {
    state = state.copyWith(adminfi: List<UserModel>.of(state.adminsac));
  }

  // ---------------- WAREHOUSES ----------------

  List<Warehouse> getAllWarehouses() {
    return service.getAllWarehouses();
  }

  Warehouse? getWarehouse(int id) {
    return service.getWarehouse(id);
  }

  bool warehouseNameExists(String name, {int? excludeId}) {
    final value = name.trim().toLowerCase();

    if (value.isEmpty) return false;

    return getAllWarehouses().any((warehouse) {
      if (excludeId != null && warehouse.id == excludeId) {
        return false;
      }

      return warehouse.name.trim().toLowerCase() == value;
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
    final existing = service.getWarehouse(id);

    if (existing == null) return false;

    if (name != null) {
      final cleanedName = name.trim();

      if (cleanedName.isEmpty ||
          warehouseNameExists(cleanedName, excludeId: id)) {
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
    final success = service.deleteWarehouse(id);

    if (success) {
      syncData();
    }

    return success;
  }

  void deleteAllWarehouses() {
    service.deleteAllWarehouses();
    syncData();
  }

  void filterWarehouseById(int id) {
    state = state.copyWith(
      filtered: state.actual.where((warehouse) => warehouse.id == id).toList(),
    );
  }

  void filterWarehouseByName(String query) {
    final value = query.trim().toLowerCase();

    state = state.copyWith(
      filtered: value.isEmpty
          ? List<Warehouse>.of(state.actual)
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
          ? List<Warehouse>.of(state.actual)
          : state.actual
                .where((warehouse) => warehouse.id.toString().contains(value))
                .toList(),
    );
  }

  void resetWarehouseFilter() {
    state = state.copyWith(filtered: List<Warehouse>.of(state.actual));
  }
}
