import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/events_provider.dart';
import '../../widgets/status_badge.dart';

class EventDetailScreen extends StatefulWidget {
  final String? eventId;
  const EventDetailScreen({super.key, this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final id = widget.eventId ?? (ModalRoute.of(context)?.settings.arguments as String?);
      if (id != null) {
        final provider = Provider.of<EventsProvider>(context, listen: false);
        provider.fetchEvent(id);
        provider.fetchParticipants(id);
      }
      _isInit = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EventsProvider>(context);
    final event = provider.selectedEvent;
    final df = DateFormat('dd/MM/yyyy HH:mm');

    if (provider.error != null && event == null) {
      return Scaffold(
        backgroundColor: OdinTheme.background,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: OdinTheme.accentRed, size: 48),
              const SizedBox(height: 16),
              Text(provider.error!, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final id = widget.eventId ?? (ModalRoute.of(context)?.settings.arguments as String?);
                  if (id != null) {
                    provider.fetchEvent(id);
                    provider.fetchParticipants(id);
                  }
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if ((provider.isLoading && event == null) || event == null) {
      return Scaffold(
        backgroundColor: OdinTheme.background,
        appBar: AppBar(title: const Text('Événement')),
        body: const Center(
          child: CircularProgressIndicator(color: OdinTheme.primaryBlue),
        ),
      );
    }

    final typeColors = {
      'match': OdinTheme.accentRed,
      'entrainement': OdinTheme.accentGreen,
      'reunion': OdinTheme.accentOrange,
      'detection': OdinTheme.accentCyan,
      'test_physique': OdinTheme.accentPurple,
    };
    final color = typeColors[event.eventType] ?? OdinTheme.primaryBlue;

    return Scaffold(
      backgroundColor: OdinTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: OdinTheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withValues(alpha: 0.8), OdinTheme.surface],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            event.eventTypeLabel,
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        StatusBadge(status: event.status),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              PopupMenuButton<String>(
                color: OdinTheme.surface,
                onSelected: _handleAction,
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Text('Annuler l\'événement',
                        style: TextStyle(color: OdinTheme.accentRed)),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Supprimer',
                        style: TextStyle(color: OdinTheme.accentRed)),
                  ),
                ],
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Details cards
                  _infoCard([
                    _row(Icons.calendar_today_rounded, 'Début',
                        df.format(event.startDate)),
                    _row(Icons.calendar_today_outlined, 'Fin',
                        df.format(event.endDate)),
                    if (event.location != null)
                      _row(Icons.location_on_rounded, 'Lieu',
                          event.location!),
                    _row(Icons.visibility_rounded, 'Visibilité',
                        event.visibility.toUpperCase()),
                    if (event.teamName != null)
                      _row(Icons.groups_rounded, 'Équipe',
                          event.teamName!),
                  ]),

                  if (event.homeScore != null && event.awayScore != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: OdinTheme.glassCard,
                      child: Column(
                        children: [
                          const Text('RÉSULTAT DU MATCH', style: TextStyle(color: OdinTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${event.homeScore}', style: const TextStyle(color: OdinTheme.primaryBlue, fontSize: 48, fontWeight: FontWeight.bold)),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: Text('-', style: TextStyle(color: OdinTheme.textTertiary, fontSize: 32)),
                              ),
                              Text('${event.awayScore}', style: const TextStyle(color: OdinTheme.primaryBlue, fontSize: 48, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (event.description != null) ...[
                    const SizedBox(height: 16),
                    _sectionTitle('Description'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: OdinTheme.glassCard,
                      child: Text(
                        event.description!,
                        style: const TextStyle(
                          color: OdinTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  _sectionTitle('Participants'),
                  const SizedBox(height: 8),
                  if (provider.participants.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: OdinTheme.glassCard,
                      child: const Text(
                        'Aucun participant',
                        style: TextStyle(color: OdinTheme.textTertiary),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ...provider.participants.map(_buildParticipant),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: OdinTheme.glassCard,
      child: Column(children: children),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: OdinTheme.textTertiary),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  color: OdinTheme.textTertiary, fontSize: 13)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: OdinTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: OdinTheme.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      );

  Widget _buildParticipant(dynamic p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: OdinTheme.glassCard,
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor:
                OdinTheme.primaryBlue.withValues(alpha: 0.2),
            child: Icon(Icons.person_rounded,
                color: OdinTheme.primaryBlue, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${p.participantType} #${p.participantId.substring(0, 8)}',
                  style: const TextStyle(
                      color: OdinTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                if (p.performanceRating != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Note de perf. : ${p.performanceRating}/10',
                    style: const TextStyle(
                        color: OdinTheme.primaryBlue, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          StatusBadge(status: p.status, fontSize: 9),
        ],
      ),
    );
  }

  void _handleAction(String action) {
    final provider = Provider.of<EventsProvider>(context, listen: false);
    final event = provider.selectedEvent;
    if (event == null) return;

    switch (action) {
      case 'edit':
        Navigator.pushNamed(context, '/events/form', arguments: event.id);
        break;
      case 'cancel':
        provider.updateEventStatus(event.id, 'cancelled');
        break;
      case 'delete':
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Supprimer ?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Annuler')),
              TextButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final dialogNavigator = Navigator.of(ctx);
                    await provider.deleteEvent(event.id);
                    if (mounted) {
                      dialogNavigator.pop();
                      navigator.pop();
                    }
                  },
                  child: const Text('Supprimer',
                      style: TextStyle(color: OdinTheme.accentRed))),
            ],
          ),
        );
        break;
    }
  }
}
