import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:sqlite3/wasm.dart';

LazyDatabase openConnection() {
  return LazyDatabase(() async {
    final sqlite3 = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
    final fs = await IndexedDbFileSystem.open(dbName: 'app_db');

    sqlite3.registerVirtualFileSystem(fs, makeDefault: true);

    // Register custom functions if needed here

    return WasmDatabase(
      sqlite3: sqlite3,
      path: 'app_db.sqlite', // File path in the virtual file system
      fileSystem: fs,
      logStatements: true,
    );
  });
}
