/// The web stand-in for `connection_io.dart`.
///
/// The web build has no SQLite, so it has no database: `providers.dart` sees
/// [hasDatabaseSupport] is false and serves the bundled demo ledger instead.
/// Selection happens at compile time through the conditional import in
/// `db.dart`, which is what keeps `dart:io` and `dart:ffi` out of the web
/// bundle entirely.
library;

import 'package:drift/drift.dart';

/// Never called on web — the guard in `providers.dart` short-circuits first.
/// Throwing loudly beats returning a database that silently loses data.
QueryExecutor openAppConnection() =>
    throw UnsupportedError('SpendStory does not open a database on the web.');

QueryExecutor openMemoryConnection() =>
    throw UnsupportedError('SpendStory does not open a database on the web.');

/// False on web: this build runs on `lib/data/demo_data.dart`.
const bool hasDatabaseSupport = false;
