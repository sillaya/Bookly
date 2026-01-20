import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../back/models/book.dart';
import '../back/providers/book_provider.dart';
import '../widgets/book_card.dart';
import '../utils/constants.dart';

class AccueilScreen extends StatelessWidget {
  const AccueilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<BookProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (provider.error != null) {
            return _buildErrorState(context, provider);
          }

          return SafeArea(
            child: RefreshIndicator(
              onRefresh: provider.loadBooks,
              color: AppColors.primary,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  // Header
                  SliverToBoxAdapter(child: _buildHeader()),

                  // Section: Recommandations (20 livres)
                  if (provider.recommendedBooks.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _buildSectionTitle(
                        'Recommandé pour vous',
                        subtitle: _getRecommendationSubtitle(provider),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildBookCarousel(provider.recommendedBooks),
                    ),
                  ],

                  // Section: Continuer la lecture (livres favoris non lus)
                  if (_getToReadBooks(provider).isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _buildSectionTitle('À lire bientôt'),
                    ),
                    SliverToBoxAdapter(
                      child: _buildBookCarousel(_getToReadBooks(provider)),
                    ),
                  ],

                  // Section: Par genre préféré
                  if (provider.favoriteBooks.isNotEmpty || provider.readBooks.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _buildFavoriteGenreSection(provider),
                    ),
                  ],

                  // Section: Découvrir (30-40 livres avec genres/auteurs différents)
                  if (provider.discoverBooks.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _buildSectionTitle(
                        'Découvrir',
                        subtitle: 'Explorez de nouveaux genres et auteurs',
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildBookCarousel(provider.discoverBooks),
                    ),
                  ],

                  // Bottom padding
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bookly',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Bienvenue ! Que voulez-vous lire aujourd\'hui ?',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookCarousel(List<Book> books) {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: books.length,
        itemBuilder: (context, index) {
          return CompactBookCard(book: books[index]);
        },
      ),
    );
  }

  Widget _buildFavoriteGenreSection(BookProvider provider) {
    final stats = provider.statistics;
    final favoriteGenre = stats['favoriteGenre'] as String;
    
    if (favoriteGenre == 'Aucun') return const SizedBox.shrink();

    final genreBooks = provider.books
      .where((b) => b.genre == favoriteGenre && !b.isRead && !b.isFavorite)
      .take(5)
      .toList();

    if (genreBooks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'Parce que vous aimez $favoriteGenre',
          subtitle: 'Basé sur vos lectures',
        ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: genreBooks.length,
            itemBuilder: (context, index) {
              return CompactBookCard(book: genreBooks[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, BookProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Oups ! Une erreur est survenue',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error ?? 'Erreur inconnue',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: provider.loadBooks,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRecommendationSubtitle(BookProvider provider) {
    final stats = provider.statistics;
    final readCount = stats['read'] as int;
    final favCount = stats['favorites'] as int;
    
    if (readCount == 0 && favCount == 0) {
      return 'Ajoutez des favoris pour des recommandations personnalisées';
    }
    return 'Basé sur vos ${readCount + favCount} livres';
  }

  List<Book> _getToReadBooks(BookProvider provider) {
    return provider.favoriteBooks
      .where((b) => !b.isRead)
      .take(5)
      .toList();
  }
}