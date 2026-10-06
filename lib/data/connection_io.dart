/// Platform-supplied database connection, for builds that have a file system
/// (Android, iOS, desktop, tests).
///
/// Split out behind a conditional import in `db.dart` so that the web build
/// never pulls in `dart:io`, `dart:ffi` or `path_provider`. The web preview has
/// no database at all — it runs on the bundled demo ledger
/// (`lib/data/demo_data.dart`), which is why the import exists.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The real database: a file in the app's private documents directory.
///
/// `createInBackground` runs SQLite on its own isolate, so a slow query can
/// never jank a frame while the user is scrolling the ledger.
QueryExecutor openAppConnection() => LazyDatabase(() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, 'spendstory.sqlite'));
  return NativeDatabase.createInBackground(file);
});

/// In-memory database for tests and for the "try it without saving" path.
QueryExecutor openMemoryConnection() => NativeDatabase.memory();

/// True when this platform can host a database at all.
const bool hasDatabaseSupport = true;
