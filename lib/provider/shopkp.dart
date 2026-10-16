import 'package:flutter/foundation.dart';
import 'package:riverpod/legacy.dart';

import 'package:inventory/Database/store.dart';
import 'package:inventory/model/warehouse.dart';
import 'package:inventory/model/ordertrack.dart';
import 'package:inventory/model/product.dart';
import 'package:inventory/model/product_category.dart';
import 'package:inventory/model/saler.dart';
import 'package:inventory/model/shopmodel.dart';
import 'package:inventory/model/stock.dart';
import 'package:inventory/services/shopkeeper.dart';

class ShopkeeperController extends StateNotifier<Shopmodel> {
  final ObjectBoxService db;
  final ShopkeeperService service;

  static const int lowStockLimit = 20;

  ShopkeeperController(this.db)
    : service = ShopkeeperService(db),
      super(
        const Shopmodel(
          actualProduct: [],
          filteredProduct: [],
          cattegory: [],
          stock: [],
          saler: [],
          orders: [],
          alert: [],
        ),
      );

  // =========================================================
  // WAREHOUSE / BRANCH CODE
  // =========================================================

  String? getBranchCodeForWarehouse(int warehouseId) {
    final warehouse = db.store.box<Warehouse>().get(warehouseId);

    if (warehouse == null) {
      debugPrint('Warehouse $warehouseId was not found.');
      return null;
    }

    return warehouse.branchCode;
  }

  bool warehouseExists(int warehouseId) {
    return db.store.box<Warehouse>().get(warehouseId) != null;
  }

  // =========================================================
  // AUTOMATIC LOW-STOCK ALERTS
  // =========================================================

  /// Rebuilds the alert list for the specified warehouse.
  ///
  /// Quantity < 20  -> alert is added.
  /// Quantity >= 20 -> alert is removed.
  ///
  /// Because the list is rebuilt from current product data,
  /// deleted products' alerts are removed automatically too.
  void checkLowStockAlerts(int warehouseId) {
    if (!warehouseExists(warehouseId)) {
      state = state.copyWith(alert: []);
      return;
    }

    final products = service
        .getAllProducts()
        .where((product) => product.warehouseid == warehouseId)
        .toList();

    final alerts = products
        .where((product) => product.quantity < lowStockLimit)
        .map(
          (product) =>
              'Low stock: ${product.productname} has only '
              '${product.quantity} items remaining.',
        )
        .toList();

    state = state.copyWith(alert: alerts);
  }

  // =========================================================
  // SYNC DATA
  // =========================================================

  void syncData(int warehouseId) {
    if (!warehouseExists(warehouseId)) {
      state = state.copyWith(
        cattegory: [],
        actualProduct: [],
        filteredProduct: [],
        stock: [],
        saler: [],
        orders: [],
        alert: [],
      );
      return;
    }

    final categories =
        service.getAllCategories(warehouseId) ?? <ProductCategory>[];

    final products = service
        .getAllProducts()
        .where((p) => p.warehouseid == warehouseId)
        .toList();

    final stocks = service
        .getAllStock()
        .where((s) => s.warehouseId == warehouseId)
        .toList();

    final sellers = service
        .getAllSalers()
        .where((s) => s.warehouseId == warehouseId)
        .toList();

    final orders = service
        .getAllOrders()
        .where((o) => o.warehouseid == warehouseId)
        .toList();

    state = state.copyWith(
      cattegory: categories,
      actualProduct: products,
      filteredProduct: products,
      stock: stocks,
      saler: sellers,
      orders: orders,
    );

    // Automatically refresh alerts whenever data is synchronized.
    checkLowStockAlerts(warehouseId);
  }

  // =========================================================
  // CATEGORY CRUD
  // =========================================================

  List<ProductCategory> getAllCategory(int warehouseId) {
    return service.getAllCategories(warehouseId) ?? [];
  }

  ProductCategory? getCategory(int id, int warehouseId) {
    final category = service.getCategory(id);

    if (category == null || category.warehouseId != warehouseId) {
      return null;
    }

    return category;
  }

  bool createCategory(ProductCategory category, int warehouseId) {
    if (!warehouseExists(warehouseId)) return false;

    category.warehouseId = warehouseId;
    service.createCategory(category);

    syncData(warehouseId);
    return true;
  }

  bool updateCategory({
    required int id,
    required int warehouseId,
    String? name,
  }) {
    if (getCategory(id, warehouseId) == null) return false;

    service.updateCategory(id: id, name: name, warehouseId: warehouseId);

    syncData(warehouseId);
    return true;
  }

  bool deleteCategory(int id, int warehouseId) {
    if (getCategory(id, warehouseId) == null) return false;

    final deleted = service.deleteCategory(id);

    if (deleted) {
      syncData(warehouseId);
    }

    return deleted;
  }

  // =========================================================
  // PRODUCT CRUD
  // =========================================================

  List<Product> getAllProducts(int warehouseId) {
    return service
        .getAllProducts()
        .where((p) => p.warehouseid == warehouseId)
        .toList();
  }

  Product? getProduct(int id, int warehouseId) {
    final product = service.getProduct(id);

    if (product == null || product.warehouseid != warehouseId) {
      return null;
    }

    return product;
  }

  /// Creates a product and refreshes low-stock alerts.
  bool createProduct(Product product, int warehouseId) {
    if (!warehouseExists(warehouseId)) return false;

    if (getCategory(product.categoryId, warehouseId) == null) {
      return false;
    }

    product.warehouseid = warehouseId;

    service.createProduct(product);

    // syncData() also calls checkLowStockAlerts().
    syncData(warehouseId);

    return true;
  }

  /// Searches products by partial product name.
  void searchProduct(String query, int warehouseId) {
    final products = getAllProducts(warehouseId);
    final search = query.trim().toLowerCase();

    final filtered = products.where((product) {
      return product.productname.toLowerCase().contains(search);
    }).toList();

    state = state.copyWith(actualProduct: products, filteredProduct: filtered);
  }

  void clearProductSearch(int warehouseId) {
    final products = getAllProducts(warehouseId);

    state = state.copyWith(actualProduct: products, filteredProduct: products);
  }

  /// Updates a product and recalculates its low-stock alert.
  bool updateProduct({
    required int id,
    required int warehouseId,
    String? productname,
    int? categoryId,
    int? quantity,
  }) {
    if (getProduct(id, warehouseId) == null) return false;

    if (categoryId != null && getCategory(categoryId, warehouseId) == null) {
      return false;
    }

    service.updateProduct(
      id: id,
      productname: productname,
      categoryId: categoryId,
      warehouseid: warehouseId,
      quantity: quantity,
    );

    // For example, quantity 10 -> 25 removes its alert.
    // Quantity 25 -> 10 adds its alert.
    syncData(warehouseId);

    return true;
  }

  /// Deletes a product and removes its alert automatically.
  bool deleteProduct(int id, int warehouseId) {
    if (getProduct(id, warehouseId) == null) return false;

    final deleted = service.deleteProduct(id);

    if (deleted) {
      // Rebuilds alerts, so the deleted product's alert disappears.
      syncData(warehouseId);
    }

    return deleted;
  }

  // =========================================================
  // SELLER CRUD
  // =========================================================

  List<Saler> getAllSalers(int warehouseId) {
    return service
        .getAllSalers()
        .where((s) => s.warehouseId == warehouseId)
        .toList();
  }

  Saler? getSaler(int id, int warehouseId) {
    final saler = service.getSaler(id);

    if (saler == null || saler.warehouseId != warehouseId) {
      return null;
    }

    return saler;
  }

  List<Saler> getSalersByCategory(int categoryId, int warehouseId) {
    if (getCategory(categoryId, warehouseId) == null) return [];

    return getAllSalers(warehouseId)
        .where((s) => s.categoryId == categoryId)
        .toList();
  }

  bool createSaler(Saler saler, int warehouseId) {
    if (!warehouseExists(warehouseId)) return false;

    if (getCategory(saler.categoryId, warehouseId) == null) {
      return false;
    }

    saler.warehouseId = warehouseId;

    service.createSaler(saler);
    syncData(warehouseId);

    return true;
  }

  bool updateSaler({
    required int id,
    required int warehouseId,
    String? salerName,
    String? salerContact,
    String? remarks,
    int? categoryId,
  }) {
    if (getSaler(id, warehouseId) == null) return false;

    if (categoryId != null && getCategory(categoryId, warehouseId) == null) {
      return false;
    }

    service.updateSaler(
      id: id,
      salerName: salerName,
      salerContact: salerContact,
      remarks: remarks,
      categoryId: categoryId,
      warehouseId: warehouseId,
    );

    syncData(warehouseId);
    return true;
  }

  bool deleteSaler(int id, int warehouseId) {
    if (getSaler(id, warehouseId) == null) return false;

    final deleted = service.deleteSaler(id);

    if (deleted) {
      syncData(warehouseId);
    }

    return deleted;
  }

  List<Saler> searchSalers(int warehouseId, String query) {
    final search = query.trim().toLowerCase();

    return getAllSalers(warehouseId).where((saler) {
      return saler.salerName.toLowerCase().contains(search) ||
          saler.salerContact.toLowerCase().contains(search);
    }).toList();
  }

  // =========================================================
  // STOCK CRUD
  // =========================================================

  List<Stock> getAllStock(int warehouseId) {
    return service
        .getAllStock()
        .where((s) => s.warehouseId == warehouseId)
        .toList();
  }

  Stock? getStock(int id, int warehouseId) {
    final stock = service.getStock(id);

    if (stock == null || stock.warehouseId != warehouseId) {
      return null;
    }

    return stock;
  }

  bool createStock(Stock stock, int warehouseId) {
    if (!warehouseExists(warehouseId)) return false;

    final branchCode = getBranchCodeForWarehouse(warehouseId);

    if (branchCode == null || branchCode.trim().isEmpty) {
      debugPrint('Cannot create stock: warehouse branch code is missing.');
      return false;
    }

    if (getCategory(stock.categoryId, warehouseId) == null) {
      return false;
    }

    if (getProduct(stock.productId, warehouseId) == null) {
      return false;
    }

    stock.warehouseId = warehouseId;
    stock.branchCode = branchCode;

    service.createStock(stock);
    syncData(warehouseId);

    return true;
  }

  bool updateStock({
    required int id,
    required int warehouseId,
    int? categoryId,
    int? productId,
    int? sellingPrice,
  }) {
    if (getStock(id, warehouseId) == null) return false;

    final branchCode = getBranchCodeForWarehouse(warehouseId);

    if (branchCode == null || branchCode.trim().isEmpty) {
      return false;
    }

    if (categoryId != null && getCategory(categoryId, warehouseId) == null) {
      return false;
    }

    if (productId != null && getProduct(productId, warehouseId) == null) {
      return false;
    }

    service.updateStock(
      id: id,
      warehouseId: warehouseId,
      branchCode: branchCode,
      categoryId: categoryId,
      productId: productId,
      sellingPrice: sellingPrice,
    );

    syncData(warehouseId);
    return true;
  }

  bool deleteStock(int id, int warehouseId) {
    if (getStock(id, warehouseId) == null) return false;

    final deleted = service.deleteStock(id);

    if (deleted) {
      syncData(warehouseId);
    }

    return deleted;
  }

  List<Stock> searchStock(int warehouseId, String query) {
    final search = query.trim().toLowerCase();

    return getAllStock(warehouseId).where((stock) {
      final product = getProduct(stock.productId, warehouseId);

      return product != null &&
          product.productname.toLowerCase().contains(search);
    }).toList();
  }

  // =========================================================
  // ORDER CRUD
  // =========================================================

  List<Ordertrack> getAllOrders(int warehouseId) {
    return service
        .getAllOrders()
        .where((o) => o.warehouseid == warehouseId)
        .toList();
  }

  Ordertrack? getOrder(int id, int warehouseId) {
    final order = service.getOrder(id);

    if (order == null || order.warehouseid != warehouseId) {
      return null;
    }

    return order;
  }

  bool createOrder(Ordertrack order, int warehouseId) {
    if (!warehouseExists(warehouseId)) return false;

    final product = getProduct(order.productid, warehouseId);

    if (product == null) {
      debugPrint('Cannot create order: product does not belong to warehouse.');
      return false;
    }

    final saler = getSaler(order.selerid, warehouseId);

    if (saler == null) {
      debugPrint('Cannot create order: seller does not belong to warehouse.');
      return false;
    }

    if (saler.categoryId != product.categoryId) {
      debugPrint('Cannot create order: seller category does not match.');
      return false;
    }

    order.warehouseid = warehouseId;

    service.createOrder(order);
    syncData(warehouseId);

    return true;
  }

  bool updateOrder({
    required int id,
    required int warehouseId,
    int? selerid,
    int? productid,
    int? quantity,
    int? totalprice,
    String? descriptive_remark,
    bool? fullfilled,
    bool? partially_completed,
  }) {
    final existing = getOrder(id, warehouseId);

    if (existing == null || existing.fullfilled) {
      return false;
    }

    if (productid != null && getProduct(productid, warehouseId) == null) {
      return false;
    }

    if (selerid != null && getSaler(selerid, warehouseId) == null) {
      return false;
    }

    final targetProduct = getProduct(
      productid ?? existing.productid,
      warehouseId,
    );

    final targetSaler = getSaler(selerid ?? existing.selerid, warehouseId);

    if (targetProduct == null ||
        targetSaler == null ||
        targetProduct.categoryId != targetSaler.categoryId) {
      return false;
    }

    service.updateOrder(
      id: id,
      selerid: selerid,
      warehouseid: warehouseId,
      productid: productid,
      quantity: quantity,
      totalprice: totalprice,
      descriptive_remark: descriptive_remark,
      fullfilled: fullfilled,
      partially_completed: partially_completed,
    );

    syncData(warehouseId);
    return true;
  }

  bool deleteOrder(int id, int warehouseId) {
    final existing = getOrder(id, warehouseId);

    if (existing == null || existing.fullfilled) {
      return false;
    }

    final deleted = service.deleteOrder(id);

    if (deleted) {
      syncData(warehouseId);
    }

    return deleted;
  }

  List<Ordertrack> searchOrders(int warehouseId, String query) {
    final search = query.trim().toLowerCase();

    return getAllOrders(warehouseId).where((order) {
      final product = getProduct(order.productid, warehouseId);
      final saler = getSaler(order.selerid, warehouseId);

      return (product?.productname.toLowerCase() ?? '').contains(search) ||
          (saler?.salerName.toLowerCase() ?? '').contains(search) ||
          order.descriptive_remark.toLowerCase().contains(search);
    }).toList();
  }
}
