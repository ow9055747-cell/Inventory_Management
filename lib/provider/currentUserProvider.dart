import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';

import 'package:inventory/Database/store.dart';
import 'package:inventory/model/usermodel.dart';
import 'package:inventory/services/loginService.dart';

class AuthController extends StateNotifier<UserModel?> {
  final ObjectBoxService db;
  final Loginservice service;

  AuthController(this.db) : service = Loginservice(db), super(null);

  // Login using email and passcode
  void Login(String email, String passcode) {
    state = service.Login(email, passcode);
  }

  // Logout
  void Logout() {
    state = null;
  }
}
