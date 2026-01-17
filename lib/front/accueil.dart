import 'package:flutter/material.dart';
import '../utils/constants.dart';


class AccueilScreen extends StatefulWidget {
  const AccueilScreen({super.key});

  @override
  State<AccueilScreen> createState() => _AccueilScreenState();
}

class _AccueilScreenState extends State<AccueilScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // HEADER
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),

            // SECTION: RECOMMANDATIONS
            SliverToBoxAdapter(
              child: _buildSectionTitle('Recommandé pour vous', onSeeAll: () {}),
            ),
            SliverToBoxAdapter(
              child: _buildBookCarousel(_recommendedBooks),
            ),

            // SECTION: AUTHOR RECOMMENDATION
            SliverToBoxAdapter(
              child: _buildAuthorSection(),
            ),

            // Bottom padding for nav bar
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  /// HEADER WIDGET
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: const Text(
        'Bookly',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }

  /// AUTHOR RECOMMENDATION SECTION 
  Widget _buildAuthorSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vous avez aimé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 75,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.book,
                          color: AppColors.primary.withValues(alpha: 0.4),
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Le Petit Prince',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Antoine de Saint-Exupéry',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.primary.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Autres livres',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildAuthorBookList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// AUTHOR BOOK LIST
  Widget _buildAuthorBookList() {
    return Column(
      children: [
        _buildAuthorBook('Vol de nuit'),
        const SizedBox(height: 8),
        _buildAuthorBook('Terre des hommes'),
        const SizedBox(height: 8),
        _buildAuthorBook('Courrier Sud'),
      ],
    );
  }

  ///  AUTHOR BOOK ITEM 
  Widget _buildAuthorBook(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.primary,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 18,
            color: AppColors.primary.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  /// SECTION TITLE WIDGET
  Widget _buildSectionTitle(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  ///BOOK CAROUSEL WIDGET 
  Widget _buildBookCarousel(List<Map<String, String>> books) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: books.length,
        itemBuilder: (context, index) {
          return _BookCard(book: books[index]);
        },
      ),
    );
  }

}

/// BOOK CARD WIDGET 
class _BookCard extends StatelessWidget {
  final Map<String, String> book;

  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
              child: Center(
                child: Icon(
                  Icons.book,
                  color: AppColors.primary.withValues(alpha: 0.3),
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              book['title'] ?? 'Titre du livre',
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
            // Author
            Text(
              book['author'] ?? 'Auteur',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ==========================================
// MOCK DATA (Replace with real data later)
// ==========================================

final List<Map<String, String>> _recommendedBooks = [
  {'title': 'L\'Étranger', 'author': 'Albert Camus', 'rating': '4.8'},
  {'title': 'Les Misérables', 'author': 'Victor Hugo', 'rating': '4.9'},
  {'title': 'Madame Bovary', 'author': 'Gustave Flaubert', 'rating': '4.6'},
  {'title': 'Le Rouge et le Noir', 'author': 'Stendhal', 'rating': '4.5'},
  {'title': 'Germinal', 'author': 'Émile Zola', 'rating': '4.7'},
];

