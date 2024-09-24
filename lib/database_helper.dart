import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import 'history_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('discount_history.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    // Gunakan path_provider untuk mendapatkan path direktori aplikasi yang benar
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate, // Memperbaiki dari _createDB menjadi _onCreate
    );
  }

  Future _onCreate(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';

    await db.execute('''
      CREATE TABLE history (
        id $idType,
        date $textType,
        originalPrice $textType,
        discount $textType,
        finalPrice $textType,
        profit $textType,
        sellprice $textType
      )
    ''');
  }

  Future<int> insertHistory(DiscountHistory history) async {
    final db = await instance.database;
    return await db.insert('history', history.toMap());
  }

Future<List<DiscountHistory>> fetchHistory() async {
  final db = await instance.database;
  final result = await db.query('history');

  return result
      .map((json) => DiscountHistory(
            id: json['id'] as int?,
            date: json['date'] as String? ?? '',
            originalPrice: json['originalPrice'] as String? ?? '',
            discount: json['discount'] as String? ?? '',
            finalPrice: json['finalPrice'] as String? ?? '',
            profit: json['profit'] as String? ?? '',
            sellprice: json['sellprice'] as String? ?? '',
          ))
      .toList();
}


  // delete history
  Future<int> deleteHistory(int id) async {
    final db = await instance.database;

    return await db.delete(
      'history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
