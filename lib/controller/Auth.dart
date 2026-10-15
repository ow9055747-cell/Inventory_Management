import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory/model/usermodel.dart';
import 'package:inventory/provider/currentUserProvider.dart';
import 'package:inventory/provider/objectbox.dart';
import 'package:inventory/provider/superAdminProvider.dart';
import 'package:riverpod/legacy.dart';

import 'package:inventory/Database/store.dart';
import 'package:inventory/model/supermodel.dart';

// Create the controller after ObjectBox is ready.
final Authprovider = StateNotifierProvider<AuthController, UserModel?>((ref) {
  final dbAsync = ref.watch(objectBoxProvider);

  return dbAsync.when(
    data: (db) => AuthController(db),
    loading: () => throw UnimplementedError('ObjectBox is still initializing'),
    error: (error, stackTrace) => throw error,
  );
});
