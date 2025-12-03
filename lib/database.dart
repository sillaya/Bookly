import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('books.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onOpen: (db) async {
        // Check if books table has data, if not, insert sample books
        final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM books'),
        );
        if (count == 0) {
          print('Database is empty, inserting sample books...');
          await _insertSampleBooks(db);
        }
      },
    );
  }

  Future _createDB(Database db, int version) async {
    // Books table
    await db.execute('''
      CREATE TABLE books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        genre TEXT NOT NULL,
        rating REAL NOT NULL,
        description TEXT NOT NULL,
        pageCount INTEGER,
        publishYear INTEGER,
        cover TEXT,
        isFavorite INTEGER DEFAULT 0,
        isRead INTEGER DEFAULT 0,
        dateAdded TEXT
      )
    ''');

    // User preferences table (for recommendation algorithm)
    await db.execute('''
      CREATE TABLE user_preferences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        genre TEXT NOT NULL,
        preferenceScore REAL DEFAULT 1.0
      )
    ''');

    // Reading history table
    await db.execute('''
      CREATE TABLE reading_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bookId INTEGER NOT NULL,
        dateRead TEXT NOT NULL,
        FOREIGN KEY (bookId) REFERENCES books (id)
      )
    ''');

    // Insert sample books
    await _insertSampleBooks(db);
  }

  Future _insertSampleBooks(Database db) async {
    final sampleBooks = [
      {
        'title': 'The Great Gatsby',
        'author': 'F. Scott Fitzgerald',
        'genre': 'Classic',
        'rating': 4.5,
        'description': 'A classic American novel set in the Jazz Age, exploring themes of wealth, love, and the American Dream.',
        'pageCount': 180,
        'publishYear': 1925,
        'dateAdded': DateTime.now().toIso8601String(),
      },
      {
        'title': '1984',
        'author': 'George Orwell',
        'genre': 'Science Fiction',
        'rating': 4.7,
        'description': 'A dystopian social science fiction novel about totalitarianism and surveillance.',
        'pageCount': 328,
        'publishYear': 1949,
        'dateAdded': DateTime.now().toIso8601String(),
      },
      {
        'title': 'To Kill a Mockingbird',
        'author': 'Harper Lee',
        'genre': 'Classic',
        'rating': 4.8,
        'description': 'A novel about racial injustice and childhood innocence in the Deep South.',
        'pageCount': 324,
        'publishYear': 1960,
        'dateAdded': DateTime.now().toIso8601String(),
      },
      {
        'title': 'Harry Potter and the Sorcerer\'s Stone',
        'author': 'J.K. Rowling',
        'genre': 'Fantasy',
        'rating': 4.9,
        'description': 'A young wizard discovers his magical heritage and begins his journey at Hogwarts.',
        'pageCount': 309,
        'publishYear': 1997,
        'dateAdded': DateTime.now().toIso8601String(),
      },
      {
        'title': 'Pride and Prejudice',
        'author': 'Jane Austen',
        'genre': 'Romance',
        'rating': 4.6,
        'description': 'A romantic novel of manners set in Georgian England.',
        'pageCount': 432,
        'publishYear': 1813,
        'dateAdded': DateTime.now().toIso8601String(),
      },
      {
        'title': 'The Hobbit',
        'author': 'J.R.R. Tolkien',
        'genre': 'Fantasy',
        'rating': 4.7,
        'description': 'A fantasy adventure about Bilbo Baggins and his unexpected journey.',
        'pageCount': 310,
        'publishYear': 1937,
        'dateAdded': DateTime.now().toIso8601String(),
      },
      {
        'title': 'The Catcher in the Rye',
        'author': 'J.D. Salinger',
        'genre': 'Fiction',
        'rating': 4.3,
        'description': 'A story about teenage rebellion and alienation in 1950s New York.',
        'pageCount': 234,
        'publishYear': 1951,
        'dateAdded': DateTime.now().toIso8601String(),
      },
      {
        'title': 'The Da Vinci Code',
        'author': 'Dan Brown',
        'genre': 'Mystery',
        'rating': 4.4,
        'description': 'A mystery thriller involving art, history, and religious conspiracy.',
        'pageCount': 489,
        'publishYear': 2003,
        'dateAdded': DateTime.now().toIso8601String(),
      },
      {
        'title': 'The Hunger Games',
        'author': 'Suzanne Collins',
        'genre': 'Science Fiction',
        'rating': 4.5,
        'description': 'A dystopian novel about survival and rebellion in a post-apocalyptic world.',
        'pageCount': 374,
        'publishYear': 2008,
        'dateAdded': DateTime.now().toIso8601String(),
      },
      {
        'title': 'The Alchemist',
        'author': 'Paulo Coelho',
        'genre': 'Fiction',
        'rating': 4.6,
        'description': 'A philosophical novel about following your dreams and finding your destiny.',
        'pageCount': 208,
        'publishYear': 1988,
        'dateAdded': DateTime.now().toIso8601String(),
      },
      {
        'title': 'Gone Girl',
        'author': 'Gillian Flynn',
        'genre': 'Mystery',
        'rating': 4.2,
        'description': 'A psychological thriller about a woman who goes missing on her wedding anniversary.',
        'pageCount': 422,
        'publishYear': 2012,
        'dateAdded': DateTime.now().toIso8601String(),
      },
      {
        'title': 'The Lord of the Rings',
        'author': 'J.R.R. Tolkien',
        'genre': 'Fantasy',
        'rating': 4.9,
        'description': 'An epic fantasy trilogy about the quest to destroy the One Ring.',
        'pageCount': 1178,
        'publishYear': 1954,
        'dateAdded': DateTime.now().toIso8601String(),
      },
    ];

    for (var book in sampleBooks) {
      await db.insert('books', book);
    }
    print('Inserted ${sampleBooks.length} sample books');

    // Initialize genre preferences
    final genres = ['Classic', 'Science Fiction', 'Fantasy', 'Romance', 'Fiction', 'Mystery'];
    for (var genre in genres) {
      await db.insert('user_preferences', {
        'genre': genre,
        'preferenceScore': 1.0,
      });
    }
    print('Initialized genre preferences');
  }

  // Method to reset database (useful for testing)
  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'books.db');
    
    await deleteDatabase(path);
    _database = null;
    
    // Reinitialize
    _database = await _initDB('books.db');
    print('Database reset complete');
  }

  // BOOK OPERATIONS

  Future<List<Map<String, dynamic>>> getAllBooks() async {
    final db = await database;
    return await db.query('books', orderBy: 'rating DESC');
  }

  Future<List<Map<String, dynamic>>> getBooksByGenre(String genre) async {
    final db = await database;
    return await db.query(
      'books',
      where: 'genre = ?',
      whereArgs: [genre],
      orderBy: 'rating DESC',
    );
  }

  Future<List<Map<String, dynamic>>> searchBooks(String query) async {
    final db = await database;
    return await db.query(
      'books',
      where: 'title LIKE ? OR author LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'rating DESC',
    );
  }

  Future<Map<String, dynamic>?> getBookById(int id) async {
    final db = await database;
    final results = await db.query(
      'books',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> insertBook(Map<String, dynamic> book) async {
    final db = await database;
    book['dateAdded'] = DateTime.now().toIso8601String();
    return await db.insert('books', book);
  }

  Future<int> updateBook(int id, Map<String, dynamic> book) async {
    final db = await database;
    return await db.update(
      'books',
      book,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteBook(int id) async {
    final db = await database;
    return await db.delete(
      'books',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // FAVORITE OPERATIONS

  Future<int> toggleFavorite(int bookId, bool isFavorite) async {
    final db = await database;
    return await db.update(
      'books',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  Future<List<Map<String, dynamic>>> getFavoriteBooks() async {
    final db = await database;
    return await db.query(
      'books',
      where: 'isFavorite = ?',
      whereArgs: [1],
      orderBy: 'dateAdded DESC',
    );
  }

  // READING HISTORY

  Future<int> markAsRead(int bookId) async {
    final db = await database;
    
    // Update book as read
    await db.update(
      'books',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [bookId],
    );

    // Add to reading history
    await db.insert('reading_history', {
      'bookId': bookId,
      'dateRead': DateTime.now().toIso8601String(),
    });

    // Update genre preference (simple recommendation algorithm)
    final book = await getBookById(bookId);
    if (book != null) {
      await _updateGenrePreference(book['genre']);
    }

    return bookId;
  }

  Future<List<Map<String, dynamic>>> getReadBooks() async {
    final db = await database;
    return await db.query(
      'books',
      where: 'isRead = ?',
      whereArgs: [1],
      orderBy: 'dateAdded DESC',
    );
  }

  // RECOMMENDATION ALGORITHM (Simple)

  Future<void> _updateGenrePreference(String genre) async {
    final db = await database;
    
    // Get current preference
    final result = await db.query(
      'user_preferences',
      where: 'genre = ?',
      whereArgs: [genre],
    );

    if (result.isNotEmpty) {
      double currentScore = result.first['preferenceScore'] as double;
      double newScore = currentScore + 0.5; // Increase preference
      
      await db.update(
        'user_preferences',
        {'preferenceScore': newScore},
        where: 'genre = ?',
        whereArgs: [genre],
      );
    } else {
      // Create preference if doesn't exist
      await db.insert('user_preferences', {
        'genre': genre,
        'preferenceScore': 1.5,
      });
    }
  }

  Future<List<Map<String, dynamic>>> getRecommendedBooks() async {
    final db = await database;
    
    // Get user's top preferred genres
    final preferences = await db.query(
      'user_preferences',
      orderBy: 'preferenceScore DESC',
      limit: 3,
    );

    if (preferences.isEmpty) {
      // If no preferences, return top-rated books
      return await db.query(
        'books',
        where: 'isRead = ?',
        whereArgs: [0],
        orderBy: 'rating DESC',
        limit: 10,
      );
    }

    // Get books from preferred genres that user hasn't read
    final topGenres = preferences.map((p) => p['genre'] as String).toList();
    final placeholders = topGenres.map((_) => '?').join(',');
    
    return await db.query(
      'books',
      where: 'genre IN ($placeholders) AND isRead = ?',
      whereArgs: [...topGenres, 0],
      orderBy: 'rating DESC',
      limit: 10,
    );
  }

  Future<List<Map<String, dynamic>>> getTrendingBooks() async {
    final db = await database;
    
    // Get recently added high-rated books
    return await db.query(
      'books',
      where: 'rating >= ?',
      whereArgs: [4.5],
      orderBy: 'dateAdded DESC, rating DESC',
      limit: 10,
    );
  }

  // STATISTICS

  Future<Map<String, int>> getStatistics() async {
    final db = await database;
    
    final totalBooks = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM books'),
    ) ?? 0;
    
    final readBooks = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM books WHERE isRead = 1'),
    ) ?? 0;
    
    final favoriteBooks = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM books WHERE isFavorite = 1'),
    ) ?? 0;

    return {
      'total': totalBooks,
      'read': readBooks,
      'favorites': favoriteBooks,
    };
  }

  Future<List<String>> getAllGenres() async {
    final db = await database;
    final result = await db.rawQuery('SELECT DISTINCT genre FROM books ORDER BY genre');
    return result.map((row) => row['genre'] as String).toList();
  }

  // Close database
  Future close() async {
    final db = await database;
    db.close();
  }
}