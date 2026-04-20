import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

QueryExecutor openAppDatabaseConnection() {
  return LazyDatabase(() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final File file = File(p.join(directory.path, 'gider.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
