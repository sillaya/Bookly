import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../back/models/book.dart';
import '../back/providers/book_provider.dart';
import '../utils/constants.dart';


class BookCard extends StatelessWidget {
  final Book book;
  final bool showRating;
  final VoidCallback? onTap;

  const BookCard({
    super.key,
    required this.book,
    this.showRating = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _showBookDetails(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image du livre
              _buildBookCover(),
              const SizedBox(width: 12),
              
              // Informations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Auteur
                    Text(
                      book.author,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Genre tag
                    _buildGenreTag(),
                    
                    if (showRating && book.rating > 0) ...[
                      const SizedBox(height: 6),
                      _buildRatingStars(),
                    ],
                  ],
                ),
              ),
              
              // Actions
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookCover() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        book.imageUrl,
        width: 60,
        height: 90,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 60,
            height: 90,
            color: AppColors.primary.withValues(alpha: 0.1),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 60,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.book,
              color: AppColors.primary.withValues(alpha: 0.3),
              size: 28,
            ),
          );
        },
      ),
    );
  }

  Widget _buildGenreTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        book.genre,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.secondary,
        ),
      ),
    );
  }

  Widget _buildRatingStars() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < book.rating ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 16,
          color: index < book.rating 
            ? AppColors.accent 
            : AppColors.primary.withValues(alpha: 0.2),
        );
      }),
    );
  }

  Widget _buildActions(BuildContext context) {
    final provider = Provider.of<BookProvider>(context, listen: false);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Favori
        IconButton(
          icon: Icon(
            book.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: book.isFavorite ? Colors.red : AppColors.primary.withValues(alpha: 0.4),
            size: 22,
          ),
          onPressed: () => provider.toggleFavorite(book),
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(8),
        ),

        // Lu - show rating dialog if not read
        IconButton(
          icon: Icon(
            book.isRead ? Icons.check_circle : Icons.check_circle_outline,
            color: book.isRead ? Colors.green : AppColors.primary.withValues(alpha: 0.4),
            size: 22,
          ),
          onPressed: () {
            if (book.isRead) {
              // Already read, just toggle off
              provider.toggleRead(book);
            } else {
              // Need to rate before marking as read
              _showRatingDialog(context, provider);
            }
          },
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(8),
        ),
      ],
    );
  }

  void _showRatingDialog(BuildContext context, BookProvider provider) {
    showDialog(
      context: context,
      builder: (context) => _RatingDialog(
        book: book,
        onRate: (rating) {
          provider.updateRating(book, rating);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showBookDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookDetailsSheet(book: book),
    );
  }
}

/// Bottom sheet avec les détails du livre et notation
class BookDetailsSheet extends StatelessWidget {
  final Book book;

  const BookDetailsSheet({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Consumer<BookProvider>(
      builder: (context, provider, _) {
        // Récupérer le livre mis à jour depuis le provider
        final currentBook = provider.books.firstWhere(
          (b) => b.id == book.id,
          orElse: () => book,
        );

        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barre de drag
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header avec image
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      currentBook.imageUrl,
                      width: 100,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        width: 100,
                        height: 150,
                        color: AppColors.primary.withValues(alpha: 0.1),
                        child: const Icon(Icons.book, size: 40),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentBook.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentBook.author,
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.primary.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            currentBook.genre,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Description
              Text(
                currentBook.description,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primary.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Section notation
              const Text(
                'Votre note',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              
              // Étoiles interactives
              _RatingStars(
                currentRating: currentBook.rating,
                onRatingChanged: (rating) {
                  provider.updateRating(currentBook, rating);
                },
              ),
              const SizedBox(height: 24),

              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: currentBook.isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                      label: currentBook.isFavorite ? 'Favori' : 'Ajouter aux favoris',
                      isActive: currentBook.isFavorite,
                      activeColor: Colors.red,
                      onTap: () => provider.toggleFavorite(currentBook),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: currentBook.isRead
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                      label: currentBook.isRead ? 'Lu' : 'Marquer comme lu',
                      isActive: currentBook.isRead,
                      activeColor: Colors.green,
                      onTap: () {
                        if (currentBook.isRead) {
                          provider.toggleRead(currentBook);
                        } else if (currentBook.rating > 0) {
                          // Already rated, can mark as read
                          provider.toggleRead(currentBook);
                        } else {
                          // Need to rate first - show message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Veuillez d\'abord noter le livre ci-dessus'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              
              // Safe area padding
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        );
      },
    );
  }
}

/// Widget d'étoiles interactives pour la notation
class _RatingStars extends StatelessWidget {
  final int currentRating;
  final ValueChanged<int> onRatingChanged;

  const _RatingStars({
    required this.currentRating,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return GestureDetector(
          onTap: () => onRatingChanged(
            starIndex == currentRating ? 0 : starIndex, // Tap sur même note = reset
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              starIndex <= currentRating 
                ? Icons.star_rounded 
                : Icons.star_outline_rounded,
              size: 36,
              color: starIndex <= currentRating 
                ? AppColors.accent 
                : AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
        );
      }),
    );
  }
}

/// Bouton d'action stylisé
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive 
            ? activeColor.withValues(alpha: 0.1)
            : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive 
              ? activeColor.withValues(alpha: 0.3)
              : AppColors.primary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? activeColor : AppColors.primary.withValues(alpha: 0.5),
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isActive ? activeColor : AppColors.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte de livre compacte (pour les carousels)
class CompactBookCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;

  const CompactBookCard({
    super.key,
    required this.book,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => BookDetailsSheet(book: book),
        );
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Couverture
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    book.imageUrl,
                    height: 160,
                    width: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      height: 160,
                      width: 120,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.book,
                        color: AppColors.primary.withValues(alpha: 0.3),
                        size: 40,
                      ),
                    ),
                  ),
                ),
                
                // Indicateurs favori/lu
                if (book.isFavorite || book.isRead)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (book.isFavorite)
                            const Icon(Icons.favorite, size: 14, color: Colors.red),
                          if (book.isFavorite && book.isRead)
                            const SizedBox(width: 2),
                          if (book.isRead)
                            const Icon(Icons.check_circle, size: 14, color: Colors.green),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Titre
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 2),
            
            // Auteur
            Text(
              book.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            
            // Rating si présent
            if (book.rating > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < book.rating ? Icons.star : Icons.star_outline,
                    size: 12,
                    color: index < book.rating
                      ? AppColors.accent
                      : AppColors.primary.withValues(alpha: 0.2),
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Dialog pour noter un livre avant de le marquer comme lu
class _RatingDialog extends StatefulWidget {
  final dynamic book;
  final Function(int) onRate;

  const _RatingDialog({
    required this.book,
    required this.onRate,
  });

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  int _selectedRating = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      title: const Text(
        'Noter ce livre',
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Vous devez noter "${widget.book.title}" pour le marquer comme lu.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRating = starIndex;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    starIndex <= _selectedRating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 40,
                    color: starIndex <= _selectedRating
                        ? AppColors.accent
                        : AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Annuler',
            style: TextStyle(
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
          ),
        ),
        TextButton(
          onPressed: _selectedRating > 0
              ? () => widget.onRate(_selectedRating)
              : null,
          child: Text(
            'Confirmer',
            style: TextStyle(
              color: _selectedRating > 0
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.3),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}