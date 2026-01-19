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

  // ==================== GETTERS ====================
  List<Book> get books => _books;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedGenre => _selectedGenre;

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
  
  /// Livres recommandés basés sur les préférences utilisateur
  /// Pondération: 50% Genre + 30% Auteur + 20% Rating
  List<Book> get recommendedBooks {
    // Livres que l'utilisateur a aimés (favoris, lus, ou notés)
    final likedBooks = _books.where((b) => 
      b.isFavorite || b.isRead || b.rating > 0
    ).toList();

    // Si aucun historique, retourne tous les livres
    if (likedBooks.isEmpty) return _books;

    // Comptabilisation des genres préférés
    Map<String, double> genreScores = {};
    Map<String, double> authorScores = {};

    for (var book in likedBooks) {
      // Poids basé sur le rating (1-5) ou 3 par défaut si juste favori/lu
      double weight = book.rating > 0 ? book.rating.toDouble() : 3.0;
      
      // Bonus si favori
      if (book.isFavorite) weight += 1.0;
      
      genreScores[book.genre] = (genreScores[book.genre] ?? 0) + weight;
      authorScores[book.author] = (authorScores[book.author] ?? 0) + weight;
    }

    // Normalisation
    double maxGenreScore = genreScores.values.fold(0.0, (a, b) => a > b ? a : b);
    double maxAuthorScore = authorScores.values.fold(0.0, (a, b) => a > b ? a : b);
    
    if (maxGenreScore == 0) maxGenreScore = 1;
    if (maxAuthorScore == 0) maxAuthorScore = 1;

    // Livres candidats (non lus et non favoris)
    List<Book> candidates = _books.where((b) => 
      !b.isRead && !b.isFavorite
    ).toList();

    // Calcul du score de recommandation pour chaque candidat
    List<MapEntry<Book, double>> scoredCandidates = candidates.map((book) {
      // Score Genre (50%)
      double genreWeight = (genreScores[book.genre] ?? 0) / maxGenreScore;
      double genreScore = genreWeight * 50;

      // Score Auteur (30%)
      double authorWeight = (authorScores[book.author] ?? 0) / maxAuthorScore;
      double authorScore = authorWeight * 30;

      // Score basé sur la moyenne des notes du genre (20%)
      double ratingScore = 0;
      final genreRatedBooks = likedBooks.where((b) => 
        b.genre == book.genre && b.rating > 0
      );
      if (genreRatedBooks.isNotEmpty) {
        double avgRating = genreRatedBooks
          .map((b) => b.rating)
          .reduce((a, b) => a + b) / genreRatedBooks.length;
        ratingScore = (avgRating / 5) * 20;
      }

      double totalScore = genreScore + authorScore + ratingScore;
      return MapEntry(book, totalScore);
    }).toList();

    // Tri par score décroissant
    scoredCandidates.sort((a, b) => b.value.compareTo(a.value));

    return scoredCandidates.map((e) => e.key).toList();
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