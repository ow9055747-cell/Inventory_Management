import 'package:inventory/Database/store.dart';
import 'package:inventory/model/product_category.dart';

class Categorydatabase {
  final ObjectBoxService db;

  Categorydatabase(this.db);

  // Add category
  void addCategory(ProductCategory category) {
    db.store.box<ProductCategory>().put(category);
  }

  // Get all categories
  List<ProductCategory> getAllCategories() {
    return db.store.box<ProductCategory>().getAll();
  }

  // Get category by ID
  ProductCategory? getCategory(int id) {
    return db.store.box<ProductCategory>().get(id);
  }

  // Update category: only update non-null values
  void updateCategory({required int id, String? name, int? warehouseId}) {
    final categoryBox = db.store.box<ProductCategory>();
    final existingCategory = categoryBox.get(id);

    if (existingCategory == null) {
      return;
    }

    final updatedCategory = ProductCategory(
      id: existingCategory.id,
      name: name ?? existingCategory.name,
      warehouseId: warehouseId ?? existingCategory.warehouseId,
    );

    categoryBox.put(updatedCategory);
  }

  // Delete category
  bool deleteCategory(int id) {
    return db.store.box<ProductCategory>().remove(id);
  }
}
