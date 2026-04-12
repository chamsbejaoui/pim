import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/event.dart';
import '../../models/event_player.dart';
import '../create_event/create_event_screen.dart';
import '../../providers/events_provider.dart';
import '../../providers/players_provider.dart';
import '../../theme/sp_colors.dart';
import '../../theme/sp_typography.dart';
import '../test_entry/player_test_entry_screen.dart';
import '../reports/event_report_screen.dart';
import '../players/create_player_screen.dart';
import 'widgets/event_player_card.dart';
import 'package:provider/provider.dart' as prov;
import '../scouting/event_scouting_screen.dart';
import '../../../../screens/ai/ai_campaign_screen.dart';
import '../../../../providers/campaign_provider.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;

  const EventDetailScreen({
    super.key,
    required this.eventId,
  });

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventAsyncValue = ref.watch(eventProvider(widget.eventId));
    final eventPlayersAsyncValue = ref.watch(eventPlayersProvider(widget.eventId));

    return Scaffold(
      backgroundColor: SPColors.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          'Fiche de Suivi',
          style: SPTypography.h4.copyWith(color: SPColors.textPrimary),
        ),
        backgroundColor: SPColors.backgroundPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: SPColors.primaryBlue),
            onPressed: () {
               Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventReportScreen(eventId: widget.eventId),
                  ),
               );
            },
          ),
          eventAsyncValue.when(
            data: (event) => PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              color: SPColors.backgroundSecondary,
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateEventScreen(eventToEdit: event),
                    ),
                  ).then((_) => ref.invalidate(eventProvider(widget.eventId)));
                } else if (value == 'delete') {
                  _confirmDeleteEvent(context);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, color: SPColors.textSecondary, size: 20),
                      SizedBox(width: 12),
                      Text('Modifier le Suivi', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: SPColors.error, size: 20),
                      SizedBox(width: 12),
                      Text('Supprimer le Suivi', style: TextStyle(color: SPColors.error)),
                    ],
                  ),
                ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: eventAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (event) {
          return eventPlayersAsyncValue.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
            data: (players) {
              final filteredPlayers = players.where((p) {
                final name = p.player.fullName.toLowerCase();
                return name.contains(_searchQuery.toLowerCase());
              }).toList();

              final completedCount = players.where((p) => p.status == ParticipationStatus.completed).length;
              final completionRate = players.isNotEmpty ? completedCount / players.length : 0.0;
              final completionPercent = (completionRate * 100).toInt();

              return Column(
                children: [
                  _buildEventHeader(event, completionRate, completionPercent),
                  _buildSearchBar(),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'JOUEURS (${players.length})',
                                style: SPTypography.overline.copyWith(
                                  color: SPColors.textSecondary,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'SORT: NAME',
                                    style: SPTypography.overline.copyWith(
                                      color: SPColors.textTertiary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.sort,
                                    size: 16,
                                    color: SPColors.textTertiary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: filteredPlayers.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: filteredPlayers.length,
                                  itemBuilder: (context, index) {
                                    return EventPlayerCard(
                                      eventPlayer: filteredPlayers[index],
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PlayerTestEntryScreen(
                                              eventPlayer: filteredPlayers[index],
                                            ),
                                          ),
                                        ).then((_) => ref.invalidate(eventPlayersProvider(widget.eventId)));
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddPlayerModal(context);
        },
        backgroundColor: SPColors.primaryBlue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEventHeader(Event event, double completionRate, int completionPercent) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SPColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SPColors.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: SPColors.primaryBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  event.typeLabel.toUpperCase(),
                  style: SPTypography.caption.copyWith(
                    color: SPColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                DateFormat('MMM dd').format(event.date),
                style: SPTypography.bodyMedium.copyWith(
                  color: SPColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            event.title,
            style: SPTypography.h3.copyWith(color: SPColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: SPColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                event.location,
                style: SPTypography.bodySmall.copyWith(color: SPColors.textSecondary),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, size: 16, color: SPColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                DateFormat('HH:mm').format(event.date),
                style: SPTypography.bodySmall.copyWith(color: SPColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PROGRESSION DU SUIVI',
                style: SPTypography.overline.copyWith(color: SPColors.textTertiary),
              ),
              // Filter completed players manually since we don't have the list here easily without passing it or refetching
              // For UI mockup purposes, we'll use a static value or simple calc if available.
              // Ideally calculated from stats or local logic.
              Text(
                '$completionPercent%',
                style: SPTypography.caption.copyWith(
                  color: SPColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: completionRate,
              backgroundColor: SPColors.backgroundPrimary,
              valueColor: const AlwaysStoppedAnimation<Color>(SPColors.primaryBlue),
              minHeight: 4,
            ),
          ),
          if (!event.isCompleted) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmCloseEvent(context),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('TERMINER LE SUIVI'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: SPColors.primaryBlue,
                  side: const BorderSide(color: SPColors.primaryBlue),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
          if (event.isCompleted) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openAiCampaign(context),
                icon: const Icon(Icons.psychology, size: 18),
                label: const Text('LANCER ANALYSE IA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SPColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openAiCampaign(BuildContext context, {bool replace = false}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final eventsService = ref.read(eventsServiceProvider);

      // Trigger backend AI analysis (best-effort)
      try {
        await eventsService.analyzeEvent(widget.eventId);
        ref.invalidate(eventPlayersProvider(widget.eventId));
        await ref.read(eventPlayersProvider(widget.eventId).future);
      } catch (_) {}

      // Use freshest list from provider (falls back to empty list)
      final players = ref.read(eventPlayersProvider(widget.eventId)).value ?? [];

      if (!mounted) return;
      Navigator.pop(context);

      final provider = CampaignProvider();
      await provider.loadFromEventPlayers(players);

      final route = MaterialPageRoute(
        builder: (_) => prov.ChangeNotifierProvider<CampaignProvider>.value(
          value: provider,
          child: const AiCampaignScreen(),
        ),
      );

      if (replace) {
        Navigator.pushReplacement(context, route);
      } else {
        Navigator.push(context, route);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: SPColors.error,
        ));
      }
    }
  }

  void _confirmDeleteEvent(BuildContext outerContext) {
    showDialog(
      context: outerContext,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: SPColors.backgroundSecondary,
        title: const Text('Supprimer le Suivi', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Voulez-vous vraiment supprimer ce suivi ? Cette action est irréversible.',
          style: TextStyle(color: SPColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL', style: TextStyle(color: SPColors.textTertiary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              final result = await ref.read(eventFormProvider.notifier).deleteEvent(widget.eventId);
              if (result && mounted) {
                ScaffoldMessenger.of(outerContext).showSnackBar(
                  const SnackBar(
                    content: Text('Event deleted successfully'),
                    backgroundColor: SPColors.success,
                  ),
                );
                Navigator.pop(outerContext); // Back to calendar
              } else if (mounted) {
                ScaffoldMessenger.of(outerContext).showSnackBar(
                  const SnackBar(
                    content: Text('Error deleting event'),
                    backgroundColor: SPColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: SPColors.error),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  void _confirmCloseEvent(BuildContext outerContext) {
    showDialog(
      context: outerContext,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: SPColors.backgroundSecondary,
        title: const Text('Terminer le Suivi', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Voulez-vous vraiment clôturer ce suivi ? L\'analyse IA sera lancée pour tous les joueurs complétés.',
          style: TextStyle(color: SPColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ANNULER', style: TextStyle(color: SPColors.textTertiary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(eventFormProvider.notifier).closeEvent(widget.eventId);
              if (mounted) {
                await _openAiCampaign(outerContext, replace: true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: SPColors.primaryBlue),
            child: const Text('TERMINER & ANALYSER'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: const TextStyle(color: SPColors.textPrimary),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: SPColors.textTertiary),
                hintText: 'Search player...',
                hintStyle: TextStyle(color: SPColors.textTertiary.withOpacity(0.5)),
                fillColor: SPColors.backgroundSecondary,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SPColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.filter_list, color: SPColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 48, color: SPColors.textTertiary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No players found',
            style: SPTypography.bodyMedium.copyWith(color: SPColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showAddPlayerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SPColors.backgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddPlayerModal(eventId: widget.eventId),
    );
  }
}

class _AddPlayerModal extends ConsumerStatefulWidget {
  final String eventId;

  const _AddPlayerModal({required this.eventId});

  @override
  ConsumerState<_AddPlayerModal> createState() => _AddPlayerModalState();
}

class _AddPlayerModalState extends ConsumerState<_AddPlayerModal> {
  final Set<String> _selectedPlayerIds = {};
  bool _isAdding = false;

  @override
  Widget build(BuildContext context) {
    // Fetch all players
    final playersAsyncValue = ref.watch(playersProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add Players',
                style: SPTypography.h4.copyWith(color: SPColors.textPrimary),
              ),
              Row(
                children: [
               if (_selectedPlayerIds.isNotEmpty)
                Text(
                  '${_selectedPlayerIds.length} selected',
                  style: SPTypography.caption.copyWith(color: SPColors.primaryBlue),
                ),
                IconButton(
                  icon: const Icon(Icons.person_add, color: SPColors.primaryBlue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreatePlayerScreen(),
                      ),
                    );
                  },
                ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: playersAsyncValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (players) {
                if (players.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         const Text('No players available', style: TextStyle(color: SPColors.textSecondary)),
                         const SizedBox(height: 16),
                         ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Create New Player'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SPColors.backgroundSecondary,
                            foregroundColor: SPColors.primaryBlue,
                          ),
                          onPressed: () {
                             Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreatePlayerScreen(),
                              ),
                            );
                          },
                         ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = players[index];
                    final isSelected = _selectedPlayerIds.contains(player.id);
                    
                    return Card(
                      color: isSelected 
                          ? SPColors.primaryBlue.withOpacity(0.1) 
                          : SPColors.backgroundTertiary,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? SPColors.primaryBlue : Colors.transparent,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: SPColors.backgroundPrimary,
                          backgroundImage: player.photo != null 
                              ? NetworkImage(player.photo!) 
                              : null,
                          child: player.photo == null 
                              ? Text(player.firstName[0], style: const TextStyle(color: SPColors.textPrimary))
                              : null,
                        ),
                        title: Text(
                          player.fullName,
                          style: SPTypography.bodyLarge.copyWith(color: SPColors.textPrimary),
                        ),
                        subtitle: Text(
                          player.position,
                          style: SPTypography.caption.copyWith(color: SPColors.textSecondary),
                        ),
                        trailing: Checkbox(
                          value: isSelected,
                          activeColor: SPColors.primaryBlue,
                          checkColor: Colors.white,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedPlayerIds.add(player.id!); // Assuming ID is not null
                              } else {
                                _selectedPlayerIds.remove(player.id);
                              }
                            });
                          },
                        ),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedPlayerIds.remove(player.id);
                            } else {
                              _selectedPlayerIds.add(player.id!);
                            }
                          });
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _selectedPlayerIds.isEmpty || _isAdding 
                  ? null 
                  : () async {
                      setState(() => _isAdding = true);
                      try {
                        // Add each selected player
                        final notifier = ref.read(eventFormProvider.notifier);
                        for (final playerId in _selectedPlayerIds) {
                          await notifier.addPlayerToEvent(widget.eventId, playerId);
                        }
                        
                        // Refresh the event players list
                        ref.invalidate(eventPlayersProvider(widget.eventId));
                        
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${_selectedPlayerIds.length} players added'),
                              backgroundColor: SPColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                         if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error adding players: $e'),
                              backgroundColor: SPColors.error,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isAdding = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: SPColors.primaryBlue,
                disabledBackgroundColor: SPColors.backgroundTertiary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isAdding 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Add Selected (${_selectedPlayerIds.length})',
                      style: SPTypography.h4.copyWith(color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
