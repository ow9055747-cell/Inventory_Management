import 'package:objectbox/objectbox.dart';

@Entity()
class Stock {
  @Id()
  int id;

  int warehouseId;
  String branchCode;
  int categoryId;
  int productId;
  int sellingPrice;

  Stock({
    this.id = 0,
    required this.warehouseId,
    required this.branchCode,
    required this.categoryId,
    required this.productId,
    required this.sellingPrice,
  });
}
