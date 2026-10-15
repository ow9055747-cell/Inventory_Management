import 'package:objectbox/objectbox.dart';

@Entity()
class ProductCategory {
  @Id()
  int id;

  String name;
  int warehouseId;

  ProductCategory({this.id = 0, required this.name, required this.warehouseId});
}
