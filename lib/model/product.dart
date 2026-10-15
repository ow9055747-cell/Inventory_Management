import 'package:objectbox/objectbox.dart';

@Entity()
class Product {
  @Id()
  int id;

  String productname;
  int categoryId;
  int warehouseid;
  int quantity;

  Product({
    this.id = 0,
    required this.productname,
    required this.categoryId,
    required this.warehouseid,
    required this.quantity,
  });
}
