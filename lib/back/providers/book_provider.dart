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

  /// Livres recommandés basés sur les préférences utilisateur
  /// Pondération: 40% favoris + 60% livres lus avec 4+ étoiles (ou 3 si pas de 4+)
  /// Retourne 20 livres recommandés
  List<Book> get recommendedBooks {
    // Séparer les livres favoris et les livres bien notés
    final favoriteBooks = _books.where((b) => b.isFavorite).toList();

    // Livres lus avec bonnes notes (4+ étoiles prioritaire, sinon 3 étoiles)
    final highRatedBooks = _books.where((b) => b.isRead && b.rating >= 4).toList();
    final midRatedBooks = _books.where((b) => b.isRead && b.rating == 3).toList();

    // Utiliser les livres 4+ étoiles, sinon fallback sur 3 étoiles
    final ratedBooksForAlgo = highRatedBooks.isNotEmpty ? highRatedBooks : midRatedBooks;

    // Si aucun historique, retourne les premiers livres
    if (favoriteBooks.isEmpty && ratedBooksForAlgo.isEmpty) {
      return _books.take(20).toList();
    }

    // Comptabilisation des genres et auteurs préférés
    Map<String, double> genreScores = {};
    Map<String, double> authorScores = {};

    // Score des favoris (40% du poids total)
    for (var book in favoriteBooks) {
      double weight = 4.0; // Poids de base pour favoris
      genreScores[book.genre] = (genreScores[book.genre] ?? 0) + weight * 0.4;
      authorScores[book.author] = (authorScores[book.author] ?? 0) + weight * 0.4;
    }

    // Score des livres bien notés (60% du poids total)
    for (var book in ratedBooksForAlgo) {
      double weight = book.rating.toDouble(); // Poids basé sur la note (3, 4 ou 5)
      genreScores[book.genre] = (genreScores[book.genre] ?? 0) + weight * 0.6;
      authorScores[book.author] = (authorScores[book.author] ?? 0) + weight * 0.6;
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
      // Score Genre (60% de l'importance)
      double genreWeight = (genreScores[book.genre] ?? 0) / maxGenreScore;
      double genreScore = genreWeight * 60;

      // Score Auteur (40% de l'importance)
      double authorWeight = (authorScores[book.author] ?? 0) / maxAuthorScore;
      double authorScore = authorWeight * 40;

      double totalScore = genreScore + authorScore;
      return MapEntry(book, totalScore);
    }).toList();

    // Tri par score décroissant
    scoredCandidates.sort((a, b) => b.value.compareTo(a.value));

    // Retourner les 20 meilleurs
    return scoredCandidates.take(20).map((e) => e.key).toList();
  }

  /// Livres à découvrir - livres avec des genres/auteurs différents des préférences
  /// Retourne 30-40 livres pour élargir les horizons de lecture
  List<Book> get discoverBooks {
    // Genres et auteurs déjà connus de l'utilisateur
    final knownGenres = <String>{};
    final knownAuthors = <String>{};

    for (var book in _books) {
      if (book.isFavorite || book.isRead) {
        knownGenres.add(book.genre);
        knownAuthors.add(book.author);
      }
    }

    // Livres candidats (non lus et non favoris)
    List<Book> candidates = _books.where((b) =>
      !b.isRead && !b.isFavorite
    ).toList();

    // Si pas d'historique, mélanger et retourner
    if (knownGenres.isEmpty) {
      candidates.shuffle();
      return candidates.take(35).toList();
    }

    // Calculer le score de "découverte" - plus élevé si genre/auteur inconnu
    List<MapEntry<Book, double>> scoredCandidates = candidates.map((book) {
      double score = 0;

      // Bonus si genre inconnu (plus de diversité)
      if (!knownGenres.contains(book.genre)) {
        score += 50;
      }

      // Bonus si auteur inconnu
      if (!knownAuthors.contains(book.author)) {
        score += 30;
      }

      // Petit bonus aléatoire pour varier les résultats
      score += (book.id.hashCode % 20).toDouble();

      return MapEntry(book, score);
    }).toList();

    // Tri par score décroissant (nouveaux genres/auteurs en premier)
    scoredCandidates.sort((a, b) => b.value.compareTo(a.value));

    // Retourner entre 30 et 40 livres
    return scoredCandidates.take(35).map((e) => e.key).toList();
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