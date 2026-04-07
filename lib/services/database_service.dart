import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/message.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'offgrid.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE messages (
            id TEXT PRIMARY KEY,
            senderId TEXT NOT NULL,
            senderName TEXT NOT NULL,
            content TEXT NOT NULL,
            type INTEGER NOT NULL,
            timestamp INTEGER NOT NULL,
            isMe INTEGER NOT NULL,
            hopCount INTEGER DEFAULT 0,
            delivered INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE seen_message_ids (
            id TEXT PRIMARY KEY,
            seenAt INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  // ── Messages ────────────────────────────────────────────────────────────────

  Future<void> insertMessage(Message msg) async {
    final db = await database;
    await db.insert('messages', msg.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<Message>> getAllMessages() async {
    final db = await database;
    final rows = await db.query('messages', orderBy: 'timestamp ASC');
    return rows.map(Message.fromMap).toList();
  }

  Future<void> markDelivered(String id) async {
    final db = await database;
    await db.update('messages', {'delivered': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  // ── Deduplication (prevent relay loops) ────────────────────────────────────

  Future<bool> hasSeenMessage(String id) async {
    final db = await database;
    final rows = await db
        .query('seen_message_ids', where: 'id = ?', whereArgs: [id]);
    return rows.isNotEmpty;
  }

  Future<void> markMessageSeen(String id) async {
    final db = await database;
    await db.insert(
      'seen_message_ids',
      {'id': id, 'seenAt': DateTime.now().millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // Purge old seen IDs to keep DB lean (keep last 24h)
  Future<void> pruneSeenIds() async {
    final db = await database;
    final cutoff = DateTime.now()
        .subtract(const Duration(hours: 24))
        .millisecondsSinceEpoch;
    await db.delete('seen_message_ids',
        where: 'seenAt < ?', whereArgs: [cutoff]);
  }
}