import 'package:inventory/Database/store.dart';
import 'package:inventory/model/stock.dart';

class Stockdatabase {
  final ObjectBoxService db;

  Stockdatabase(this.db);

  // Add stock
  void addStock(Stock stock) {
    db.store.box<Stock>().put(stock);
  }

  // Get all stock records
  List<Stock> getAllStock() {
    return db.store.box<Stock>().getAll();
  }

  // Get stock record by ID
  Stock? getStock(int id) {
    return db.store.box<Stock>().get(id);
  }

  // Update only non-null fields
  void updateStock({
    required int id,
    int? warehouseId,
    String? branchCode,
    int? categoryId,
    int? productId,
    int? sellingPrice,
    int? quantity,
  }) {
    final stockBox = db.store.box<Stock>();
    final existingStock = stockBox.get(id);

    if (existingStock == null) {
      return;
    }

    final updatedStock = Stock(
      id: existingStock.id,
      warehouseId: warehouseId ?? existingStock.warehouseId,
      branchCode: branchCode ?? existingStock.branchCode,
      categoryId: categoryId ?? existingStock.categoryId,
      productId: productId ?? existingStock.productId,
      sellingPrice: sellingPrice ?? existingStock.sellingPrice,
      // Include quantity only if your Stock model defines this field.
    );

    stockBox.put(updatedStock);
  }

  // Delete stock record
  bool deleteStock(int id) {
    return db.store.box<Stock>().remove(id);
  }

  // Delete all stock records
  void deleteAllStock() {
    db.store.box<Stock>().removeAll();
  }
}
