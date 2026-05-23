import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  static Database? _database;

  factory DBHelper() {
    return _instance;
  }

  DBHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'beautycare.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT UNIQUE,
        password TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE chat_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        title TEXT,
        timestamp TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE chats(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sessionId INTEGER,
        userId INTEGER,
        message TEXT,
        isUser INTEGER,
        imagePath TEXT,
        timestamp TEXT,
        FOREIGN KEY (sessionId) REFERENCES chat_sessions (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // Drop existing chats table because schema changed and user agreed to reset
      await db.execute('DROP TABLE IF EXISTS chats');
      await db.execute('''
        CREATE TABLE chat_sessions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER,
          title TEXT,
          timestamp TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE chats(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sessionId INTEGER,
          userId INTEGER,
          message TEXT,
          isUser INTEGER,
          imagePath TEXT,
          timestamp TEXT,
          FOREIGN KEY (sessionId) REFERENCES chat_sessions (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  // User CRUD
  Future<int> registerUser(User user) async {
    final db = await database;
    try {
      return await db.insert('users', user.toMap());
    } catch (e) {
      return -1;
    }
  }

  Future<User?> loginUser(String email, String password) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (results.isNotEmpty) {
      return User.fromMap(results.first);
    }
    return null;
  }
  
  Future<List<User>> getAllUsers() async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query('users');
    return results.map((map) => User.fromMap(map)).toList();
  }

  // Chat Session CRUD
  Future<int> createChatSession(Map<String, dynamic> sessionData) async {
    final db = await database;
    return await db.insert('chat_sessions', sessionData);
  }

  Future<List<Map<String, dynamic>>> getChatSessions(int userId) async {
    final db = await database;
    return await db.query(
      'chat_sessions',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC'
    );
  }

  Future<int> deleteChatSession(int sessionId) async {
    final db = await database;
    await db.delete('chats', where: 'sessionId = ?', whereArgs: [sessionId]);
    return await db.delete('chat_sessions', where: 'id = ?', whereArgs: [sessionId]);
  }

  // Chat Message CRUD
  Future<int> insertChat(Map<String, dynamic> chatData) async {
    final db = await database;
    return await db.insert('chats', chatData);
  }

  Future<List<Map<String, dynamic>>> getChatsBySession(int sessionId) async {
    final db = await database;
    return await db.query(
      'chats',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC'
    );
  }
}
