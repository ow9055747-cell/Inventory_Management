import 'package:objectbox/objectbox.dart';

@Entity()
class UserModel {
  @Id()
  int id;
  String email;
  String name;
  int? warehouseId;
  String role;
  String passcode;
  String? branchCode;

  UserModel({
    this.id = 0,
    required this.name,
    this.warehouseId,
    required this.role,
    required this.passcode,
    required this.email,
    this.branchCode,
  });
}
