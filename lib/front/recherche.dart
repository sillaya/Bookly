import 'package:flutter/material.dart';
import '../utils/constants.dart';

class RechercheScreen extends StatefulWidget {
  const RechercheScreen({super.key});

  @override
  State<RechercheScreen> createState() => _RechercheScreenState();
}

class _RechercheScreenState extends State<RechercheScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedGenre = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
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

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
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
                              setState(() {
                                _searchController.clear();
                              });
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
                    setState(() {});
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Genres Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Text(
                'Genres',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Genre Buttons Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _genres.length,
                  itemBuilder: (context, index) {
                    final genre = _genres[index];
                    final isSelected = _selectedGenre == genre;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedGenre = isSelected ? '' : genre;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(
                              alpha: isSelected ? 1.0 : 0.1,
                            ),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            genre,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Mock genre data
final List<String> _genres = [
  'Romance',
  'Thriller',
  'Science-Fiction',
  'Fantasy',
  'Classique',
  'Biographie',
  'Policier',
  'Histoire',
  'Horreur',
  'Aventure',
  'Philosophie',
  'Poésie',
];
