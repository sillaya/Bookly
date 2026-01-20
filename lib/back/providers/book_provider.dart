import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/book.dart';
import '../services/database_service.dart';


class BookProvider with ChangeNotifier {
  // ==================== STATE ====================
  List<Book> _books = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedGenre = '';
  String _userName = 'Lecteur Bookly';

  // ==================== GETTERS ====================
  List<Book> get books => _books;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedGenre => _selectedGenre;
  String get userName => _userName;

  /// Livres favoris
  List<Book> get favoriteBooks => _books.where((b) => b.isFavorite).toList();

  /// Livres lus
  List<Book> get readBooks => _books.where((b) => b.isRead).toList();

  /// Livres notés (avec une note > 0)
  List<Book> get ratedBooks => _books.where((b) => b.rating > 0).toList();

  /// Tous les genres disponibles
  List<String> get allGenres {
    final genres = _books.map((b) => b.genre).toSet().toList();
    genres.sort();
    return genres;
  }

  /// Livres filtrés par recherche et/ou genre
  List<Book> get filteredBooks {
    return _books.where((book) {
      // Filtre par genre
      if (_selectedGenre.isNotEmpty && book.genre != _selectedGenre) {
        return false;
      }
      
      // Filtre par recherche (titre ou auteur)
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTitle = book.title.toLowerCase().contains(query);
        final matchAuthor = book.author.toLowerCase().contains(query);
        if (!matchTitle && !matchAuthor) return false;
      }
      
      return true;
    }).toList();
  }

// ==================== ALGORITHME DE RECOMMANDATION ====================

List<Book> get recommendedBooks {
  // ========== ÉTAPE 1: COLLECTE DES DONNÉES ==========
  final favoriteBooks = <Book>[];    
  final highRatedBooks = <Book>[];     
  final midRatedBooks = <Book>[];    
  final candidates = <Book>[];         
  
  for (var book in _books) {
    if (book.isFavorite) {
      favoriteBooks.add(book);
    }
    
    if (book.isRead) {
      if (book.rating >= 4) {
        highRatedBooks.add(book);
      } else if (book.rating == 3) {
        midRatedBooks.add(book);
      }
    }
    
    if (!book.isRead && !book.isFavorite) {
      candidates.add(book);
    }
  }
  
  final ratedBooks = highRatedBooks.isNotEmpty ? highRatedBooks : midRatedBooks;
  
  // ========== ÉTAPE 2: CAS SPÉCIAL - PAS D'HISTORIQUE ==========
  if (favoriteBooks.isEmpty && ratedBooks.isEmpty) {
    return candidates.take(20).toList();
  }
  
  // ========== ÉTAPE 3: CALCUL DES SCORES DE PRÉFÉRENCE ==========
  final genreScores = <String, double>{};
  final authorScores = <String, double>{};
  
  // --- Scoring des favoris (40% du poids total) ---
  for (var book in favoriteBooks) {
    genreScores[book.genre] = (genreScores[book.genre] ?? 0) + 2;
    authorScores[book.author] = (authorScores[book.author] ?? 0) + 2;
  }
  
  // --- Scoring des livres bien notés (60% du poids total) ---
  // Le poids varie selon la note: 3×0.6=1.8, 4×0.6=2.4, 5×0.6=3.0
  for (var book in ratedBooks) {
    final weight = book.rating * 0.6; 
    genreScores[book.genre] = (genreScores[book.genre] ?? 0) + weight;
    authorScores[book.author] = (authorScores[book.author] ?? 0) + weight;
  }
  
  // ========== ÉTAPE 4: CALCUL DES SCORES POUR CHAQUE CANDIDAT ==========
  final scores = candidates.map((book) {
    final genreScore = (genreScores[book.genre] ?? 0) * 60;
    final authorScore = (authorScores[book.author] ?? 0) * 40;
    return genreScore + authorScore;
  }).toList();
  
  // ========== ÉTAPE 5: TRI ET SÉLECTION DES TOP 20 ==========
  final indices = List.generate(candidates.length, (i) => i);
  indices.sort((a, b) => scores[b].compareTo(scores[a]));
  return indices.take(20).map((i) => candidates[i]).toList();
}

// ==================== ALGORITHME DE DÉCOUVERTE ====================
List<Book> get discoverBooks {
  // ========== ÉTAPE 1: COLLECTE DES PRÉFÉRENCES CONNUES ==========
  final knownGenres = <String>{};     
  final knownAuthors = <String>{};    
  final candidates = <Book>[];        
  
  for (var book in _books) {
    if (book.isFavorite || book.isRead) {
      knownGenres.add(book.genre);
      knownAuthors.add(book.author);
    }
    
    // Si le livre n'est pas connu, c'est un candidat à la découverte
    if (!book.isRead && !book.isFavorite) {
      candidates.add(book);
    }
  }
  
  // ========== ÉTAPE 2: CAS SPÉCIAL - PAS D'HISTORIQUE ==========
  if (knownGenres.isEmpty) {
    candidates.shuffle();
    return candidates.take(35).toList();
  }
  
  // ========== ÉTAPE 3: CALCUL DU SCORE DE DÉCOUVERTE ==========
  final scores = candidates.map((book) {
    double score = 0;

    if (!knownGenres.contains(book.genre)) {
      score += 50;
    }
    
    if (!knownAuthors.contains(book.author)) {
      score += 30;
    }
    
    score += (book.id.hashCode % 20);
    
    return score;
  }).toList();
  
  // ========== ÉTAPE 4: TRI ET SÉLECTION DES TOP 35 ==========
  final indices = List.generate(candidates.length, (i) => i);
  indices.sort((a, b) => scores[b].compareTo(scores[a]));

  return indices.take(35).map((i) => candidates[i]).toList();
}

  // ==================== DATA LOADING ====================

  /// Charge les livres depuis le JSON et la base de données
  Future<void> loadBooks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Charger les données JSON
      final String response = await rootBundle.loadString('assets/book.json');
      final List<dynamic> data = json.decode(response);

      // Charger les statuts utilisateur depuis SQLite
      final userStatus = await DatabaseService.instance.getAllUserBooks();

      // Charger le nom utilisateur
      _userName = await DatabaseService.instance.getUserName();

      // Combiner les données
      _books = data.map((item) {
        final String id = item['id'].toString();
        return Book.fromJson(item, userStatus: userStatus[id]);
      }).toList();

      print('✅ ${_books.length} livres chargés');
    } catch (e, stackTrace) {
      _error = 'Erreur de chargement: $e';
      debugPrint('❌ Erreur: $e');
      debugPrint('Stack trace: $stackTrace');
      _books = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Met à jour le nom de l'utilisateur
  Future<void> updateUserName(String name) async {
    try {
      await DatabaseService.instance.updateUserName(name);
      _userName = name;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur updateUserName: $e');
      rethrow;
    }
  }

  // ==================== USER ACTIONS ====================

  /// Basculer l'état favori d'un livre
  Future<void> toggleFavorite(Book book) async {
    final index = _books.indexWhere((b) => b.id == book.id);
    if (index == -1) return;

    final newFavoriteStatus = !book.isFavorite;
    _books[index] = book.copyWith(isFavorite: newFavoriteStatus);
    notifyListeners();

    try {
      await DatabaseService.instance.toggleFavorite(book.id, newFavoriteStatus);
    } catch (e) {
      // Rollback en cas d'erreur
      _books[index] = book;
      notifyListeners();
      debugPrint('❌ Erreur toggleFavorite: $e');
    }
  }

  /// Basculer l'état lu d'un livre
  Future<void> toggleRead(Book book) async {
    final index = _books.indexWhere((b) => b.id == book.id);
    if (index == -1) return;

    final newReadStatus = !book.isRead;
    _books[index] = book.copyWith(isRead: newReadStatus);
    notifyListeners();

    try {
      await DatabaseService.instance.toggleRead(book.id, newReadStatus);
    } catch (e) {
      // Rollback en cas d'erreur
      _books[index] = book;
      notifyListeners();
      debugPrint('❌ Erreur toggleRead: $e');
    }
  }

  /// Mettre à jour la note d'un livre
  Future<void> updateRating(Book book, int rating) async {
    final index = _books.indexWhere((b) => b.id == book.id);
    if (index == -1) return;

    final clampedRating = rating.clamp(0, 5);
    _books[index] = book.copyWith(rating: clampedRating, isRead: true);
    notifyListeners();

    try {
      await DatabaseService.instance.updateRating(book.id, clampedRating);
    } catch (e) {
      // Rollback en cas d'erreur
      _books[index] = book;
      notifyListeners();
      debugPrint('❌ Erreur updateRating: $e');
    }
  }

  // ==================== SEARCH & FILTER ====================

  /// Mettre à jour la recherche
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Mettre à jour le filtre de genre
  void setSelectedGenre(String genre) {
    _selectedGenre = _selectedGenre == genre ? '' : genre;
    notifyListeners();
  }

  /// Réinitialiser les filtres
  void clearFilters() {
    _searchQuery = '';
    _selectedGenre = '';
    notifyListeners();
  }

  /// Réinitialiser toutes les données utilisateur
  Future<void> clearAllData() async {
    try {
      await DatabaseService.instance.clearAllData();
      // Reset all books to default state
      _books = _books.map((book) => book.copyWith(
        isFavorite: false,
        isRead: false,
        rating: 0,
      )).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur clearAllData: $e');
      rethrow;
    }
  }

  // ==================== STATISTICS ====================

  /// Statistiques pour le profil
  Map<String, dynamic> get statistics {
    return {
      'totalBooks': _books.length,
      'favorites': favoriteBooks.length,
      'read': readBooks.length,
      'rated': ratedBooks.length,
      'averageRating': ratedBooks.isEmpty 
        ? 0.0 
        : ratedBooks.map((b) => b.rating).reduce((a, b) => a + b) / ratedBooks.length,
      'favoriteGenre': _getFavoriteGenre(),
      'favoriteAuthor': _getFavoriteAuthor(),
    };
  }

  String _getFavoriteGenre() {
    final likedBooks = [...favoriteBooks, ...readBooks];
    if (likedBooks.isEmpty) return 'Aucun';
    
    Map<String, int> counts = {};
    for (var book in likedBooks) {
      counts[book.genre] = (counts[book.genre] ?? 0) + 1;
    }
    
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  String _getFavoriteAuthor() {
    final likedBooks = [...favoriteBooks, ...readBooks];
    if (likedBooks.isEmpty) return 'Aucun';
    
    Map<String, int> counts = {};
    for (var book in likedBooks) {
      counts[book.author] = (counts[book.author] ?? 0) + 1;
    }
    
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}