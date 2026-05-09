import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mtime.db');
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
      CREATE TABLE riwayat (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tanggal_mulai TEXT NOT NULL,
        tanggal_selesai TEXT,
        gejala TEXT,
        catatan TEXT
      )
    ''');
  }

  Future<int> insertData(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('riwayat', row);
  }

  Future<List<Map<String, dynamic>>> readAllData() async {
    final db = await instance.database;
    return await db.query('riwayat', orderBy: 'tanggal_mulai DESC');
  }

  Future<int> updateData(Map<String, dynamic> row) async {
    final db = await instance.database;
    int id = row['id'];
    return await db.update('riwayat', row, where: 'id = ?', whereArgs: [id]);
  }

  // --- FUNGSI BARU UNTUK MENGHAPUS SEMUA DATA ---
  Future<void> deleteAllData() async {
    final db = await instance.database;
    await db.delete('riwayat');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}