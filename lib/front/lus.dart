import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../back/models/book.dart';
import '../back/providers/book_provider.dart';
import '../widgets/book_card.dart';
import '../utils/constants.dart';

class LusScreen extends StatefulWidget {
  const LusScreen({super.key});

  @override
  State<LusScreen> createState() => _LusScreenState();
}

class _LusScreenState extends State<LusScreen> {
  String _sortBy = 'recent'; // 'recent', 'rating', 'title'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<BookProvider>(
          builder: (context, provider, _) {
            final readBooks = _getSortedBooks(provider.readBooks);

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: _buildHeader(readBooks.length, provider),
                ),

                // Filtres de tri
                if (readBooks.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildSortOptions(),
                  ),

                // Stats rapides
                if (readBooks.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildQuickStats(provider),
                  ),

                // Liste ou état vide
                if (readBooks.isEmpty)
                  SliverFillRemaining(child: _buildEmptyState())
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _ReadBookCard(book: readBooks[index]);
                      },
                      childCount: readBooks.length,
                    ),
                  ),

                // Padding bottom
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Book> _getSortedBooks(List<Book> books) {
    final sorted = List<Book>.from(books);
    switch (_sortBy) {
      case 'rating':
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'title':
        sorted.sort((a, b) => a.title.compareTo(b.title));
        break;
      default:
        // 'recent' - garder l'ordre par défaut
        break;
    }
    return sorted;
  }

  Widget _buildHeader(int count, BookProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 28,
              ),
              const SizedBox(width: 10),
              const Text(
                'Livres Lus',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            count == 0
              ? 'Aucun livre lu pour l\'instant'
              : '$count livre${count > 1 ? 's' : ''} lu${count > 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text(
            'Trier par: ',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          _SortChip(
            label: 'Récent',
            isSelected: _sortBy == 'recent',
            onTap: () => setState(() => _sortBy = 'recent'),
          ),
          const SizedBox(width: 8),
          _SortChip(
            label: 'Note',
            isSelected: _sortBy == 'rating',
            onTap: () => setState(() => _sortBy = 'rating'),
          ),
          const SizedBox(width: 8),
          _SortChip(
            label: 'Titre',
            isSelected: _sortBy == 'title',
            onTap: () => setState(() => _sortBy = 'title'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BookProvider provider) {
    final stats = provider.statistics;
    final ratedCount = stats['rated'] as int;
    final avgRating = stats['averageRating'] as double;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.star,
            iconColor: AppColors.accent,
            value: avgRating > 0 ? avgRating.toStringAsFixed(1) : '-',
            label: 'Note moyenne',
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.primary.withValues(alpha: 0.1),
          ),
          _StatItem(
            icon: Icons.rate_review,
            iconColor: AppColors.secondary,
            value: ratedCount.toString(),
            label: 'Livres notés',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun livre lu',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Marquez vos livres comme lus et donnez-leur une note pour améliorer vos recommandations.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primary.withValues(alpha: 0.5),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte de livre lu avec notation inline
class _ReadBookCard extends StatelessWidget {
  final Book book;

  const _ReadBookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookProvider>(context, listen: false);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                book.imageUrl,
                width: 50,
                height: 75,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  width: 50,
                  height: 75,
                  color: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.book, size: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book.author,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Étoiles interactives
                  Row(
                    children: [
                      const Text(
                        'Ma note: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                      ...List.generate(5, (index) {
                        final starIndex = index + 1;
                        return GestureDetector(
                          onTap: () {
                            final newRating = starIndex == book.rating ? 0 : starIndex;
                            provider.updateRating(book, newRating);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Icon(
                              starIndex <= book.rating 
                                ? Icons.star_rounded 
                                : Icons.star_outline_rounded,
                              size: 22,
                              color: starIndex <= book.rating 
                                ? AppColors.accent 
                                : AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            Column(
              children: [
                IconButton(
                  icon: Icon(
                    book.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: book.isFavorite ? Colors.red : AppColors.primary.withValues(alpha: 0.4),
                    size: 20,
                  ),
                  onPressed: () => provider.toggleFavorite(book),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
                IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: AppColors.primary.withValues(alpha: 0.4),
                    size: 20,
                  ),
                  onPressed: () => _showRemoveDialog(context, provider),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveDialog(BuildContext context, BookProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Retirer de la liste'),
        content: Text('Voulez-vous retirer "${book.title}" de vos livres lus ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              provider.toggleRead(book);
              Navigator.pop(context);
            },
            child: const Text('Retirer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
              ? AppColors.primary 
              : AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.primary.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}