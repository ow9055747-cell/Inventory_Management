import 'package:inventory/model/usermodel.dart';
import 'package:inventory/model/warehouse.dart';

class Supermodel {
  final List<Warehouse> actual;
  final List<Warehouse> filtered;
  final List<UserModel> adminsac;
  final List<UserModel> adminfi;

  Supermodel({
    required this.actual,
    required this.filtered,
    required this.adminsac,
    required this.adminfi,
  });

  Supermodel copyWith({
    List<Warehouse>? actual,
    List<Warehouse>? filtered,
    List<UserModel>? adminsac,
    List<UserModel>? adminfi,
  }) {
    return Supermodel(
      actual: actual ?? this.actual,
      filtered: filtered ?? this.filtered,
      adminsac: adminsac ?? this.adminsac,
      adminfi: adminfi ?? this.adminfi,
    );
  }
}
