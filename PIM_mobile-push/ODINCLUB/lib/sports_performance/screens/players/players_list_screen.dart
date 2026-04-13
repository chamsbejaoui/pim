import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/player.dart';
import '../../providers/players_provider.dart';
import '../../theme/sp_colors.dart';
import '../../theme/sp_typography.dart';
import 'create_player_screen.dart';

class PlayersListScreen extends ConsumerStatefulWidget {
  const PlayersListScreen({super.key});

  @override
  ConsumerState<PlayersListScreen> createState() => _PlayersListScreenState();
}

class _PlayersListScreenState extends ConsumerState<PlayersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(playersProvider);

    return Scaffold(
      backgroundColor: SPColors.backgroundPrimary,
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          Expanded(
            child: playersAsync.when(
              data: (players) {
                final filteredPlayers = players.where((p) {
                  return p.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                         p.position.toLowerCase().contains(_searchQuery.toLowerCase());
                }).toList();

                if (filteredPlayers.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredPlayers.length,
                  itemBuilder: (context, index) {
                    return _buildPlayerCard(filteredPlayers[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePlayerScreen()),
          );
        },
        backgroundColor: SPColors.primaryBlue,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EFFECTIF DU CLUB',
                style: SPTypography.overline.copyWith(color: SPColors.primaryBlue, letterSpacing: 1.5),
              ),
              const SizedBox(height: 4),
              Text(
                'Gérer les Joueurs',
                style: SPTypography.h3.copyWith(color: Colors.white),
              ),
            ],
          ),
          const Icon(Icons.people_outline, color: SPColors.textTertiary, size: 28),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Chercher un joueur par nom ou poste...',
          hintStyle: TextStyle(color: SPColors.textTertiary.withOpacity(0.5)),
          prefixIcon: const Icon(Icons.search, color: SPColors.textTertiary),
          filled: true,
          fillColor: SPColors.backgroundSecondary.withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildPlayerCard(Player player) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: SPColors.backgroundSecondary.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SPColors.borderPrimary.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Hero(
          tag: 'player_${player.id}',
          child: CircleAvatar(
            radius: 24,
            backgroundImage: player.photo != null ? NetworkImage(player.photo!) : null,
            backgroundColor: SPColors.backgroundPrimary,
            child: player.photo == null ? const Icon(Icons.person, color: Colors.white) : null,
          ),
        ),
        title: Text(
          player.fullName,
          style: SPTypography.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: SPColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                player.position.toUpperCase(),
                style: SPTypography.overline.copyWith(color: SPColors.primaryBlue, fontSize: 10),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '#${player.jerseyNumber ?? 'N/A'}',
              style: SPTypography.caption.copyWith(color: SPColors.textSecondary),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: SPColors.textTertiary, size: 20),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreatePlayerScreen(playerToEdit: player)),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: SPColors.error, size: 20),
              onPressed: () => _showDeleteConfirmation(player),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 64, color: SPColors.textTertiary.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'Aucun joueur trouvé',
            style: SPTypography.bodyMedium.copyWith(color: SPColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Player player) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SPColors.backgroundSecondary,
        title: const Text('Supprimer le Joueur', style: TextStyle(color: Colors.white)),
        content: Text(
          'Voulez-vous vraiment retirer ${player.fullName} de l\'effectif ?',
          style: const TextStyle(color: SPColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULER', style: TextStyle(color: SPColors.textTertiary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(playerFormProvider.notifier).deletePlayer(player.id!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Joueur supprimé' : 'Erreur lors de la suppression'),
                    backgroundColor: success ? SPColors.success : SPColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: SPColors.error),
            child: const Text('SUPPRIMER'),
          ),
        ],
      ),
    );
  }
}
