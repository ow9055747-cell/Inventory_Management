import 'package:inventory/Database/store.dart';
import 'package:inventory/Database/userDatabase.dart';
import 'package:inventory/model/usermodel.dart';

class Loginservice {
  final ObjectBoxService db;

  Loginservice(this.db);

  UserModel? Login(String email, String passcode) {
    final UserModel? data = Userdatabase(db).getUserByEmail(email);

    if (data != null && data.passcode == passcode) {
      return data;
    } else {
      return null;
    }
  }
}
