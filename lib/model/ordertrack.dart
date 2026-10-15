import 'package:objectbox/objectbox.dart';

@Entity()
class Ordertrack {
  @Id()
  int id;

  int selerid;
  int warehouseid;
  int productid;
  int quantity;
  int totalprice;
  String descriptive_remark;
  bool fullfilled;
  bool partially_completed;

  Ordertrack({
    this.id = 0,
    required this.selerid,
    required this.warehouseid,
    required this.productid,
    required this.descriptive_remark,
    required this.fullfilled,
    required this.partially_completed,
    required this.quantity,
    required this.totalprice,
  });
}
