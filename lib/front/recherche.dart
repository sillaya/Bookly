import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../back/providers/book_provider.dart';
import '../widgets/book_card.dart';
import '../utils/constants.dart';

class RechercheScreen extends StatefulWidget {
  const RechercheScreen({super.key});

  @override
  State<RechercheScreen> createState() => _RechercheScreenState();
}

class _RechercheScreenState extends State<RechercheScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Synchroniser avec le provider au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<BookProvider>(context, listen: false);
      _searchController.text = provider.searchQuery;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<BookProvider>(
          builder: (context, provider, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Text(
                    'Recherche',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                // Barre de recherche
                _buildSearchBar(provider),
                const SizedBox(height: 16),

                // Genres
                _buildGenreSection(provider),
                const SizedBox(height: 16),

                // Résultats
                Expanded(
                  child: _buildResults(provider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar(BookProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _searchFocusNode.hasFocus
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.primary.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            if (_searchFocusNode.hasFocus)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: 'Rechercher un livre, auteur...',
            hintStyle: TextStyle(
              color: AppColors.primary.withValues(alpha: 0.4),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: AppColors.primary.withValues(alpha: 0.4),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                    onPressed: () {
                      _searchController.clear();
                      provider.setSearchQuery('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 14,
          ),
          onChanged: (value) {
            provider.setSearchQuery(value);
            setState(() {}); // Pour mettre à jour l'icône clear
          },
          textInputAction: TextInputAction.search,
        ),
      ),
    );
  }

  Widget _buildGenreSection(BookProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Genres',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              if (provider.selectedGenre.isNotEmpty)
                GestureDetector(
                  onTap: () => provider.clearFilters(),
                  child: Text(
                    'Effacer',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: provider.allGenres.length,
            itemBuilder: (context, index) {
              final genre = provider.allGenres[index];
              final isSelected = provider.selectedGenre == genre;
              
              return GestureDetector(
                onTap: () => provider.setSelectedGenre(genre),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected 
                        ? AppColors.primary 
                        : AppColors.primary.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      genre,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? AppColors.white : AppColors.primary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResults(BookProvider provider) {
    final results = provider.filteredBooks;
    final hasFilters = provider.searchQuery.isNotEmpty || 
                       provider.selectedGenre.isNotEmpty;

    // État de chargement
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // Aucune recherche active - afficher tous les livres
    if (!hasFilters) {
      return _buildAllBooks(provider);
    }

    // Recherche active mais aucun résultat
    if (results.isEmpty) {
      return _buildNoResults();
    }

    // Afficher les résultats
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compteur de résultats
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            '${results.length} résultat${results.length > 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
          ),
        ),
        
        // Liste des résultats
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: results.length,
            itemBuilder: (context, index) {
              return BookCard(book: results[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAllBooks(BookProvider provider) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Section populaires
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text(
              'Tous les livres',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),

        // Grille de livres
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.55,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _GridBookCard(book: provider.books[index]);
              },
              childCount: provider.books.length,
            ),
          ),
        ),

        // Padding bottom
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez avec d\'autres mots-clés ou un autre genre.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte de livre pour la grille
class _GridBookCard extends StatelessWidget {
  final dynamic book;

  const _GridBookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => BookDetailsSheet(book: book),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image avec taille fixe
          AspectRatio(
            aspectRatio: 0.65,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    book.imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.book,
                        color: AppColors.primary.withValues(alpha: 0.3),
                        size: 32,
                      ),
                    ),
                  ),
                ),

                // Badge favori/lu
                if (book.isFavorite || book.isRead)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (book.isFavorite)
                            const Icon(Icons.favorite, size: 12, color: Colors.red),
                          if (book.isRead)
                            const Icon(Icons.check_circle, size: 12, color: Colors.green),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Titre
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),

          // Auteur
          Text(
            book.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}