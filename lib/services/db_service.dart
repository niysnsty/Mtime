import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mtime_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath(); 
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB); 
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE menstruasi (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      tanggal_mulai TEXT NOT NULL,
      tanggal_selesai TEXT,
      gejala TEXT,
      catatan TEXT
    )
    ''');
  }

  Future<int> insertData(Map<String, dynamic> row) async {
    // Perbaikan di sini: langsung memanggil database
    final db = await database; 
    return await db.insert('menstruasi', row);
  }

  Future<List<Map<String, dynamic>>> readAllData() async {
    // Perbaikan di sini: langsung memanggil database
    final db = await database; 
    return await db.query('menstruasi', orderBy: 'id DESC');
  }

  Future<int> updateData(Map<String, dynamic> row) async {
    final db = await database;
    int id = row['id'];
    return await db.update(
      'menstruasi', 
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}