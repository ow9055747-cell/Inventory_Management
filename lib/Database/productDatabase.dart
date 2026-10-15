import 'package:inventory/Database/store.dart';
import 'package:inventory/model/product.dart';

class ProductStore {
  final ObjectBoxService db;

  ProductStore(this.db);

  void addProduct(Product product) {
    db.store.box<Product>().put(product);
  }

  List<Product> getAllProducts() {
    return db.store.box<Product>().getAll();
  }

  Product? getProduct(int id) {
    return db.store.box<Product>().get(id);
  }

  bool deleteProduct(int id) {
    return db.store.box<Product>().remove(id);
  }

  void updateProduct({
    required int id,
    String? productname,
    int? categoryId,
    int? warehouseid,
    int? quantity,
  }) {
    final productBox = db.store.box<Product>();

    final existingProduct = productBox.get(id);

    if (existingProduct == null) {
      return;
    }

    final updatedProduct = Product(
      id: existingProduct.id,
      productname: productname ?? existingProduct.productname,
      categoryId: categoryId ?? existingProduct.categoryId,
      warehouseid: warehouseid ?? existingProduct.warehouseid,
      quantity: quantity ?? existingProduct.quantity,
    );

    productBox.put(updatedProduct);
  }
}
