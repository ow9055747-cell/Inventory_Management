import 'package:inventory/model/ordertrack.dart';
import 'package:inventory/model/product.dart';
import 'package:inventory/model/product_category.dart';
import 'package:inventory/model/saler.dart';
import 'package:inventory/model/stock.dart';

class Shopmodel {
  final List<ProductCategory>? cattegory;
  final List<Product>? actualProduct;
  final List<Product>? filteredProduct;
  final List<Stock>? stock;
  final List<Saler>? saler;
  final List<Ordertrack>? orders;
  final List<String>? alert;
  const Shopmodel({
    this.alert,
    this.cattegory,
    this.actualProduct,
    this.filteredProduct,
    this.stock,
    this.saler,
    this.orders,
  });

  Shopmodel copyWith({
    List<ProductCategory>? cattegory,
    List<Product>? actualProduct,
    List<Product>? filteredProduct,
    List<Stock>? stock,
    List<Saler>? saler,
    List<Ordertrack>? orders,
    List<String>? alert,
  }) {
    return Shopmodel(
      cattegory: cattegory ?? this.cattegory,
      actualProduct: actualProduct ?? this.actualProduct,
      filteredProduct: filteredProduct ?? this.filteredProduct,
      stock: stock ?? this.stock,
      saler: saler ?? this.saler,
      orders: orders ?? this.orders,
      alert: alert ?? this.alert,
    );
  }
}
