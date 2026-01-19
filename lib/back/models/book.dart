
class Book {
  final String id;
  final String title;
  final String author;
  final String description;
  final String imageUrl;
  final String genre;
  final bool isFavorite;
  final bool isRead;
  final int rating; // 0-5 étoiles (0 = pas encore noté)

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.imageUrl,
    required this.genre,
    this.isFavorite = false,
    this.isRead = false,
    this.rating = 0,
  });

  /// Crée une copie du livre avec des valeurs modifiées
  Book copyWith({
    bool? isFavorite,
    bool? isRead,
    int? rating,
  }) {
    return Book(
      id: id,
      title: title,
      author: author,
      description: description,
      imageUrl: imageUrl,
      genre: genre,
      isFavorite: isFavorite ?? this.isFavorite,
      isRead: isRead ?? this.isRead,
      rating: rating ?? this.rating,
    );
  }

  /// Convertit en Map pour la base de données (seulement l'état utilisateur)
  Map<String, dynamic> toUserStatusMap() {
    return {
      'id': id,
      'isFavorite': isFavorite ? 1 : 0,
      'isRead': isRead ? 1 : 0,
      'rating': rating,
    };
  }

  /// Crée un Book depuis le JSON (données statiques)
  factory Book.fromJson(Map<String, dynamic> json, {Map<String, dynamic>? userStatus}) {
    return Book(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      genre: json['genre'] ?? 'Général',
      isFavorite: userStatus?['isFavorite'] == 1,
      isRead: userStatus?['isRead'] == 1,
      rating: userStatus?['rating'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'Book(id: $id, title: $title, author: $author, genre: $genre, '
           'isFavorite: $isFavorite, isRead: $isRead, rating: $rating)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Book && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}