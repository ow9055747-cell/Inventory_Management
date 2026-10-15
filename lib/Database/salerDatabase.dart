import 'package:inventory/Database/store.dart';
import 'package:inventory/model/saler.dart';

class Salerdatabase {
  final ObjectBoxService db;

  Salerdatabase(this.db);

  // Add seller
  void addSaler(Saler saler) {
    db.store.box<Saler>().put(saler);
  }

  // Get all sellers
  List<Saler> getAllSalers() {
    return db.store.box<Saler>().getAll();
  }

  // Get seller by ID
  Saler? getSaler(int id) {
    return db.store.box<Saler>().get(id);
  }

  // Update only non-null fields
  void updateSaler({
    required int id,
    String? salerName,
    String? salerContact,
    String? remarks,
    int? categoryId,
    int? warehouseId,
  }) {
    final salerBox = db.store.box<Saler>();
    final existingSaler = salerBox.get(id);

    if (existingSaler == null) {
      return;
    }

    final updatedSaler = Saler(
      id: existingSaler.id,
      salerName: salerName ?? existingSaler.salerName,
      salerContact: salerContact ?? existingSaler.salerContact,
      remarks: remarks ?? existingSaler.remarks,
      categoryId: categoryId ?? existingSaler.categoryId,
      warehouseId: warehouseId ?? existingSaler.warehouseId,
    );

    salerBox.put(updatedSaler);
  }

  // Delete seller
  bool deleteSaler(int id) {
    return db.store.box<Saler>().remove(id);
  }

  // Delete all sellers
  void deleteAllSalers() {
    db.store.box<Saler>().removeAll();
  }
}
