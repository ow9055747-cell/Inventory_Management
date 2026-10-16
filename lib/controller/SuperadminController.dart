import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory/provider/superAdminProvider.dart';
import 'package:riverpod/legacy.dart';

import 'package:inventory/model/supermodel.dart';
import 'package:inventory/controller/SuperadminController.dart';
import 'package:inventory/provider/objectbox.dart';

final superprovider = StateNotifierProvider<Supercontroller, Supermodel>((ref) {
  final dbAsync = ref.watch(objectBoxProvider);

  return dbAsync.when(
    data: (db) => Supercontroller(db),
    loading: () => throw UnimplementedError('ObjectBox is still initializing'),
    error: (error, stackTrace) => throw error,
  );
});
