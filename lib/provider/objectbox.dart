import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory/provider/superAdminProvider.dart';
import 'package:riverpod/legacy.dart';

import 'package:inventory/Database/store.dart';
import 'package:inventory/model/supermodel.dart';

final objectBoxProvider = FutureProvider<ObjectBoxService>((ref) async {
  return await ObjectBoxService.create();
});
