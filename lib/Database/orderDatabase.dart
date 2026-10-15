import 'package:inventory/Database/store.dart';
import 'package:inventory/model/ordertrack.dart';

class Orderdatabase {
  final ObjectBoxService db;

  Orderdatabase(this.db);

  // Add order
  void addOrder(Ordertrack order) {
    db.store.box<Ordertrack>().put(order);
  }

  // Get all orders
  List<Ordertrack> getAllOrders() {
    return db.store.box<Ordertrack>().getAll();
  }

  // Get order by ID
  Ordertrack? getOrder(int id) {
    return db.store.box<Ordertrack>().get(id);
  }

  // Update only fields that are not null
  void updateOrder({
    required int id,
    int? selerid,
    int? warehouseid,
    int? productid,
    int? quantity,
    int? totalprice,
    String? descriptive_remark,
    bool? fullfilled,
    bool? partially_completed,
  }) {
    final orderBox = db.store.box<Ordertrack>();
    final existingOrder = orderBox.get(id);

    if (existingOrder == null) {
      return;
    }

    final updatedOrder = Ordertrack(
      id: existingOrder.id,
      selerid: selerid ?? existingOrder.selerid,
      warehouseid: warehouseid ?? existingOrder.warehouseid,
      productid: productid ?? existingOrder.productid,
      quantity: quantity ?? existingOrder.quantity,
      totalprice: totalprice ?? existingOrder.totalprice,
      descriptive_remark:
          descriptive_remark ?? existingOrder.descriptive_remark,
      fullfilled: fullfilled ?? existingOrder.fullfilled,
      partially_completed:
          partially_completed ?? existingOrder.partially_completed,
    );

    orderBox.put(updatedOrder);
  }

  // Delete order
  bool deleteOrder(int id) {
    return db.store.box<Ordertrack>().remove(id);
  }

  // Delete all orders
  void deleteAllOrders() {
    db.store.box<Ordertrack>().removeAll();
  }
}
