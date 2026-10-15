import 'package:objectbox/objectbox.dart';
import 'package:path_provider/path_provider.dart';

import '../objectbox.g.dart';

class ObjectBoxService {
  late final Store store;

  static ObjectBoxService? _instance;

  ObjectBoxService._create(this.store);

  static Future<ObjectBoxService> create() async {
    // Reuse the existing database instance.
    if (_instance != null) {
      return _instance!;
    }

    // Get a writable, app-specific directory on Android.
    final directory = await getApplicationSupportDirectory();

    // Create the ObjectBox database in that directory.
    final store = await openStore(directory: '${directory.path}/objectbox');

    _instance = ObjectBoxService._create(store);

    return _instance!;
  }
}
