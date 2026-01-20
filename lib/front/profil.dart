import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../back/providers/book_provider.dart';
import '../utils/constants.dart';

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<BookProvider>(
          builder: (context, provider, _) {
            final stats = provider.statistics;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(),

                  // Avatar et nom
                  _buildProfileCard(context, provider),

                  // Statistiques
                  _buildStatsSection(stats),

                  // Préférences détectées
                  _buildPreferencesSection(stats),

                  // Actions
                  _buildActionsSection(context, provider),

                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        'Mon Profil',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, BookProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Membre depuis 2025',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),

          // Edit button
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            onPressed: () => _showEditNameDialog(context, provider),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, BookProvider provider) {
    final controller = TextEditingController(text: provider.userName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Modifier votre nom'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Entrez votre nom',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await provider.updateUserName(newName);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nom mis à jour'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Enregistrer',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(Map<String, dynamic> stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mes statistiques',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          
          // Grid de stats
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.menu_book,
                  iconColor: AppColors.primary,
                  value: '${stats['read']}',
                  label: 'Livres lus',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.favorite,
                  iconColor: Colors.red,
                  value: '${stats['favorites']}',
                  label: 'Favoris',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.star,
                  iconColor: AppColors.accent,
                  value: '${stats['rated']}',
                  label: 'Livres notés',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.analytics,
                  iconColor: AppColors.secondary,
                  value: (stats['averageRating'] as double) > 0 
                    ? (stats['averageRating'] as double).toStringAsFixed(1)
                    : '-',
                  label: 'Note moyenne',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(Map<String, dynamic> stats) {
    final favoriteGenre = stats['favoriteGenre'] as String;
    final favoriteAuthor = stats['favoriteAuthor'] as String;
    
    final hasPreferences = favoriteGenre != 'Aucun' || favoriteAuthor != 'Aucun';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: AppColors.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Vos préférences détectées',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (!hasPreferences)
            Text(
              'Lisez plus de livres pour que nous puissions détecter vos préférences et améliorer nos recommandations.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primary.withValues(alpha: 0.6),
                height: 1.4,
              ),
            )
          else ...[
            _PreferenceRow(
              label: 'Genre préféré',
              value: favoriteGenre,
              icon: Icons.category,
            ),
            const SizedBox(height: 12),
            _PreferenceRow(
              label: 'Auteur préféré',
              value: favoriteAuthor,
              icon: Icons.person_outline,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context, BookProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          
          _ActionTile(
            icon: Icons.refresh,
            title: 'Recharger les livres',
            subtitle: 'Actualiser la bibliothèque',
            onTap: () => provider.loadBooks(),
          ),
          
          _ActionTile(
            icon: Icons.delete_outline,
            title: 'Réinitialiser mes données',
            subtitle: 'Effacer favoris, lectures et notes',
            isDestructive: true,
            onTap: () => _showResetDialog(context, provider),
          ),
          
          _ActionTile(
            icon: Icons.info_outline,
            title: 'À propos de Bookly',
            subtitle: 'Version 1.0.0',
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, BookProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Réinitialiser les données ?'),
        content: const Text(
          'Cette action effacera tous vos favoris, livres lus et notes. Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.clearAllData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Données réinitialisées'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
            child: const Text(
              'Réinitialiser',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Row(
          children: [
            Image.asset(
              'images/logo.png',
              width: 40,
              height: 40,
              errorBuilder: (c, e, s) => const Icon(Icons.book, size: 40),
            ),
            const SizedBox(width: 12),
            const Text('Bookly'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Version 1.0.0'),
            const SizedBox(height: 12),
            Text(
              AppStrings.tagline,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Développé avec ❤️ pour les amoureux des livres.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
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
      ),
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _PreferenceRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.secondary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary.withValues(alpha: 0.6),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDestructive 
              ? Colors.red.withValues(alpha: 0.2)
              : AppColors.primary.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : AppColors.primary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? Colors.red : AppColors.primary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}