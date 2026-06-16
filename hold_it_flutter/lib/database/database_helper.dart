import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hold_it.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE resist_records (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        category_emoji TEXT NOT NULL,
        category_id TEXT NOT NULL,
        note TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        amount REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE custom_categories (
        id TEXT PRIMARY KEY,
        emoji TEXT NOT NULL,
        name TEXT NOT NULL,
        has_amount INTEGER NOT NULL,
        default_amount REAL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE rewards (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        reward_description TEXT NOT NULL,
        image_data BLOB,
        target_coins INTEGER NOT NULL,
        current_coins INTEGER NOT NULL,
        category_ids TEXT NOT NULL,
        status_raw TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        unlocked_at INTEGER,
        redeemed_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE reward_coin_records (
        id TEXT PRIMARY KEY,
        reward_id TEXT NOT NULL,
        restraint_record_id TEXT NOT NULL,
        coins INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
