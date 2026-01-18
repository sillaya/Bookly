import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Service de base de données SQLite
/// Gère la persistance des états utilisateur (favoris, lus, notes)
/// 
/// Pattern Singleton pour une seule instance de connexion

class DatabaseService {
  // ==================== SINGLETON ====================
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  // ==================== INITIALIZATION ====================
  
  /// Récupère la base de données (création si nécessaire)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('bookly_app.db');
    return _database!;
  }

  /// Initialise la base de données
  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 2, // Version 2 pour le support du rating
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  /// Crée les tables
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_books (
        id TEXT PRIMARY KEY,
        isFavorite INTEGER DEFAULT 0,
        isRead INTEGER DEFAULT 0,
        rating INTEGER DEFAULT 0
      )
    ''');
    
    print('✅ Base de données créée avec succès');
  }

  /// Mise à jour du schéma (ajout du rating si migration)
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Ajouter la colonne rating si elle n'existe pas
      await db.execute('ALTER TABLE user_books ADD COLUMN rating INTEGER DEFAULT 0');
      print('✅ Migration: colonne rating ajoutée');
    }
  }

  // ==================== CRUD OPERATIONS ====================

  /// Met à jour le statut complet d'un livre
  Future<void> updateBookStatus({
    required String id,
    required bool isFavorite,
    required bool isRead,
    required int rating,
  }) async {
    try {
      final db = await instance.database;
      await db.insert(
        'user_books',
        {
          'id': id,
          'isFavorite': isFavorite ? 1 : 0,
          'isRead': isRead ? 1 : 0,
          'rating': rating.clamp(0, 5), // S'assure que rating est entre 0 et 5
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('❌ Erreur updateBookStatus: $e');
      rethrow;
    }
  }

  /// Met à jour uniquement le statut favori
  Future<void> toggleFavorite(String id, bool isFavorite) async {
    try {
      final db = await instance.database;
      final existing = await db.query('user_books', where: 'id = ?', whereArgs: [id]);
      
      if (existing.isEmpty) {
        await db.insert('user_books', {
          'id': id,
          'isFavorite': isFavorite ? 1 : 0,
          'isRead': 0,
          'rating': 0,
        });
      } else {
        await db.update(
          'user_books',
          {'isFavorite': isFavorite ? 1 : 0},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    } catch (e) {
      print('❌ Erreur toggleFavorite: $e');
      rethrow;
    }
  }

  /// Met à jour uniquement le statut lu
  Future<void> toggleRead(String id, bool isRead) async {
    try {
      final db = await instance.database;
      final existing = await db.query('user_books', where: 'id = ?', whereArgs: [id]);
      
      if (existing.isEmpty) {
        await db.insert('user_books', {
          'id': id,
          'isFavorite': 0,
          'isRead': isRead ? 1 : 0,
          'rating': 0,
        });
      } else {
        await db.update(
          'user_books',
          {'isRead': isRead ? 1 : 0},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    } catch (e) {
      print('❌ Erreur toggleRead: $e');
      rethrow;
    }
  }

  /// Met à jour uniquement la note
  Future<void> updateRating(String id, int rating) async {
    try {
      final db = await instance.database;
      final existing = await db.query('user_books', where: 'id = ?', whereArgs: [id]);
      
      if (existing.isEmpty) {
        await db.insert('user_books', {
          'id': id,
          'isFavorite': 0,
          'isRead': 1, // Si on note, on a forcément lu
          'rating': rating.clamp(0, 5),
        });
      } else {
        await db.update(
          'user_books',
          {
            'rating': rating.clamp(0, 5),
            'isRead': 1, // Marquer comme lu automatiquement
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    } catch (e) {
      print('❌ Erreur updateRating: $e');
      rethrow;
    }
  }

  // ==================== READ OPERATIONS ====================

  /// Récupère tous les statuts utilisateur
  Future<Map<String, Map<String, dynamic>>> getAllUserBooks() async {
    try {
      final db = await instance.database;
      final result = await db.query('user_books');

      Map<String, Map<String, dynamic>> map = {};
      for (var row in result) {
        map[row['id'] as String] = row;
      }
      return map;
    } catch (e) {
      print('❌ Erreur getAllUserBooks: $e');
      return {};
    }
  }

  /// Récupère le statut d'un livre spécifique
  Future<Map<String, dynamic>?> getBookStatus(String id) async {
    try {
      final db = await instance.database;
      final result = await db.query(
        'user_books',
        where: 'id = ?',
        whereArgs: [id],
      );
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      print('❌ Erreur getBookStatus: $e');
      return null;
    }
  }

  /// Compte les livres par statut
  Future<Map<String, int>> getBookCounts() async {
    try {
      final db = await instance.database;
      
      final favorites = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM user_books WHERE isFavorite = 1')
      ) ?? 0;
      
      final read = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM user_books WHERE isRead = 1')
      ) ?? 0;
      
      final rated = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM user_books WHERE rating > 0')
      ) ?? 0;

      return {
        'favorites': favorites,
        'read': read,
        'rated': rated,
      };
    } catch (e) {
      print('❌ Erreur getBookCounts: $e');
      return {'favorites': 0, 'read': 0, 'rated': 0};
    }
  }

  // ==================== UTILITY ====================

  /// Efface toutes les données utilisateur (reset)
  Future<void> clearAllData() async {
    try {
      final db = await instance.database;
      await db.delete('user_books');
      print('✅ Toutes les données utilisateur effacées');
    } catch (e) {
      print('❌ Erreur clearAllData: $e');
      rethrow;
    }
  }

  /// Ferme la connexion à la base de données
  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }
}