import 'package:objectbox/objectbox.dart';

@Entity()
class Saler {
  @Id()
  int id;

  String salerName;
  String salerContact;
  String remarks;
  int categoryId;
  int warehouseId;

  Saler({
    this.id = 0,
    required this.salerName,
    required this.salerContact,
    required this.remarks,
    required this.categoryId,
    required this.warehouseId,
  });
}
