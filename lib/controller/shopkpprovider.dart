import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory/provider/shopkp.dart';
import 'package:riverpod/legacy.dart';

import 'package:inventory/controller/shopkpprovider.dart';
import 'package:inventory/model/shopmodel.dart';
import 'package:inventory/provider/objectbox.dart';

final shopprovider = StateNotifierProvider<ShopkeeperController, Shopmodel>((
  ref,
) {
  final dbAsync = ref.watch(objectBoxProvider);

  return dbAsync.when(
    data: (db) => ShopkeeperController(db),
    loading: () => throw UnimplementedError('ObjectBox is still initializing'),
    error: (error, stackTrace) => throw error,
  );
});
