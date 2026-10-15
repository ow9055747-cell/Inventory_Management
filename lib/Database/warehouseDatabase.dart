import 'package:inventory/Database/store.dart';
import 'package:inventory/model/warehouse.dart';

class Warehousedatabase {
  final ObjectBoxService db;

  Warehousedatabase(this.db);

  // Add warehouse
  void addWarehouse(Warehouse warehouse) {
    db.store.box<Warehouse>().put(warehouse);
  }

  // Get all warehouses
  List<Warehouse> getAllWarehouses() {
    return db.store.box<Warehouse>().getAll();
  }

  // Get warehouse by ID
  Warehouse? getWarehouse(int id) {
    return db.store.box<Warehouse>().get(id);
  }

  // Update only non-null fields
  void updateWarehouse({
    required int id,
    bool? mainBranch,
    String? name,
    String? branchCode,
    String? address,
  }) {
    final warehouseBox = db.store.box<Warehouse>();
    final existingWarehouse = warehouseBox.get(id);

    if (existingWarehouse == null) {
      return;
    }

    final updatedWarehouse = Warehouse(
      id: existingWarehouse.id,
      mainBranch: mainBranch ?? existingWarehouse.mainBranch,
      name: name ?? existingWarehouse.name,
      branchCode: branchCode ?? existingWarehouse.branchCode,
      address: address ?? existingWarehouse.address,
    );

    warehouseBox.put(updatedWarehouse);
  }

  // Delete warehouse
  bool deleteWarehouse(int id) {
    return db.store.box<Warehouse>().remove(id);
  }

  // Delete all warehouses
  void deleteAllWarehouses() {
    db.store.box<Warehouse>().removeAll();
  }
}
