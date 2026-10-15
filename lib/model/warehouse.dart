import 'package:objectbox/objectbox.dart';

@Entity()
class Warehouse {
  @Id()
  int id;

  bool mainBranch;
  String name;
  String branchCode;
  String address;

  Warehouse({
    this.id = 0,
    required this.mainBranch,
    required this.name,
    required this.branchCode,
    required this.address,
  });
}
