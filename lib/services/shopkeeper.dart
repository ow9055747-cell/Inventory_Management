import 'package:inventory/Database/store.dart';
import 'package:inventory/Database/categoryDatabase.dart';
import 'package:inventory/Database/orderDatabase.dart';
import 'package:inventory/Database/productDatabase.dart';
import 'package:inventory/Database/salerDatabase.dart';
import 'package:inventory/Database/stockDatabase.dart';

import 'package:inventory/model/product_category.dart';
import 'package:inventory/model/ordertrack.dart';
import 'package:inventory/model/product.dart';
import 'package:inventory/model/saler.dart';
import 'package:inventory/model/stock.dart';

//ordertracking (update manually like remarks)->model-ordertracking.dart,saler id present here
// add product category in product category model
// add product in product model
// crud saler details in saler model
// add or crud stock in shop
//where warehouse id required it will automatically assigns from current user credentials
// it is shop keeper services so all time branch code will be null here only warehouse id will be given here
//user means shoopkeeper can do any thing with warehouse id it automatically fetched and will be given where required
//
//view page
//  |
// <..>
//Here on product page will be a search option on product (after clicking on product add product happens in stock) and two button add seller and add category
// first it will show all current stock avail (Here shoop keeper can crud stock)
// here in each product card have a order option after click have to choose saller among th sellors belong to the product category
//this order details can be show in order tracking page and seller can crud details //if a order fully completed then crud cant be performed on it
//and a alert option if a product quantity go down to a below limit then it will give alert if value up then automatically alert will remove

class ShopkeeperService {
  final ObjectBoxService db;

  final Categorydatabase categoryDb;
  final Orderdatabase orderDb;
  final ProductStore productDb;
  final Salerdatabase salerDb;
  final Stockdatabase stockDb;

  ShopkeeperService(this.db)
    : categoryDb = Categorydatabase(db),
      orderDb = Orderdatabase(db),
      productDb = ProductStore(db),
      salerDb = Salerdatabase(db),
      stockDb = Stockdatabase(db);

  // ==================== CATEGORY OPERATIONS ====================

  void createCategory(ProductCategory category) {
    categoryDb.addCategory(category);
  }

  //get only the warehouse data where shopkeeper belong
  List<ProductCategory>? getAllCategories(int warehouseId) {
    return categoryDb
        .getAllCategories()
        .where((e) => e.warehouseId == warehouseId)
        .toList();
  }

  ProductCategory? getCategory(int id) {
    return categoryDb.getCategory(id);
  }

  void updateCategory({required int id, String? name, int? warehouseId}) {
    categoryDb.updateCategory(id: id, name: name, warehouseId: warehouseId);
  }

  bool deleteCategory(int id) {
    return categoryDb.deleteCategory(id);
  }

  // ==================== ORDER OPERATIONS ====================

  void createOrder(Ordertrack order) {
    orderDb.addOrder(order);
  }

  List<Ordertrack> getAllOrders() {
    return orderDb.getAllOrders();
  }

  Ordertrack? getOrder(int id) {
    return orderDb.getOrder(id);
  }

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
    orderDb.updateOrder(
      id: id,
      selerid: selerid,
      warehouseid: warehouseid,
      productid: productid,
      quantity: quantity,
      totalprice: totalprice,
      descriptive_remark: descriptive_remark,
      fullfilled: fullfilled,
      partially_completed: partially_completed,
    );
  }

  bool deleteOrder(int id) {
    return orderDb.deleteOrder(id);
  }

  void deleteAllOrders() {
    orderDb.deleteAllOrders();
  }

  // ==================== PRODUCT OPERATIONS ====================

  void createProduct(Product product) {
    productDb.addProduct(product);
  }

  List<Product> getAllProducts() {
    return productDb.getAllProducts();
  }

  Product? getProduct(int id) {
    return productDb.getProduct(id);
  }

  void updateProduct({
    required int id,
    String? productname,
    int? categoryId,
    int? warehouseid,
    int? quantity,
  }) {
    productDb.updateProduct(
      id: id,
      productname: productname,
      categoryId: categoryId,
      warehouseid: warehouseid,
      quantity: quantity,
    );
  }

  bool deleteProduct(int id) {
    return productDb.deleteProduct(id);
  }

  // ==================== SELLER OPERATIONS ====================

  void createSaler(Saler saler) {
    salerDb.addSaler(saler);
  }

  List<Saler> getAllSalers() {
    return salerDb.getAllSalers();
  }

  Saler? getSaler(int id) {
    return salerDb.getSaler(id);
  }

  void updateSaler({
    required int id,
    String? salerName,
    String? salerContact,
    String? remarks,
    int? categoryId,
    int? warehouseId,
  }) {
    salerDb.updateSaler(
      id: id,
      salerName: salerName,
      salerContact: salerContact,
      remarks: remarks,
      categoryId: categoryId,
      warehouseId: warehouseId,
    );
  }

  bool deleteSaler(int id) {
    return salerDb.deleteSaler(id);
  }

  void deleteAllSalers() {
    salerDb.deleteAllSalers();
  }

  // ==================== STOCK OPERATIONS ====================

  void createStock(Stock stock) {
    stockDb.addStock(stock);
  }

  List<Stock> getAllStock() {
    return stockDb.getAllStock();
  }

  Stock? getStock(int id) {
    return stockDb.getStock(id);
  }

  void updateStock({
    required int id,
    int? warehouseId,
    String? branchCode,
    int? categoryId,
    int? productId,
    int? sellingPrice,
    int? quantity,
  }) {
    stockDb.updateStock(
      id: id,
      warehouseId: warehouseId,
      branchCode: branchCode,
      categoryId: categoryId,
      productId: productId,
      sellingPrice: sellingPrice,
      quantity: quantity,
    );
  }

  bool deleteStock(int id) {
    return stockDb.deleteStock(id);
  }

  void deleteAllStock() {
    stockDb.deleteAllStock();
  }
}
