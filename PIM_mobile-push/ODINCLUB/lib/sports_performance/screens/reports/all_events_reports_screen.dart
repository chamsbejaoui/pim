import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/event.dart';
import '../../providers/events_provider.dart';
import '../../theme/sp_colors.dart';
import '../../theme/sp_typography.dart';
import 'event_report_screen.dart';

class AllEventsReportsScreen extends ConsumerStatefulWidget {
  const AllEventsReportsScreen({super.key});

  @override
  ConsumerState<AllEventsReportsScreen> createState() => _AllEventsReportsScreenState();
}

class _AllEventsReportsScreenState extends ConsumerState<AllEventsReportsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fetch all events without specific filters
    final eventsAsync = ref.watch(eventsProvider(null));

    return Scaffold(
      backgroundColor: SPColors.backgroundPrimary,
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          Expanded(
            child: eventsAsync.when(
              data: (events) {
                final filteredEvents = events.where((e) {
                  return e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                         e.type.toString().toLowerCase().contains(_searchQuery.toLowerCase());
                }).toList();

                // Sort events by date descending (most recent first)
                filteredEvents.sort((a, b) => b.date.compareTo(a.date));

                if (filteredEvents.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    return _buildEventReportCard(filteredEvents[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: SPColors.error, size: 48),
                    const SizedBox(height: 16),
                    Text('Error loading reports', style: SPTypography.h4.copyWith(color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(e.toString(), style: TextStyle(color: SPColors.textTertiary), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        ],
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
                'PERFORMANCE ANALYTICS',
                style: SPTypography.overline.copyWith(color: SPColors.primaryBlue, letterSpacing: 1.5),
              ),
              const SizedBox(height: 4),
              Text(
                'Rapports de Suivis',
                style: SPTypography.h3.copyWith(color: Colors.white),
              ),
            ],
          ),
          const Icon(Icons.analytics_outlined, color: SPColors.textTertiary, size: 28),
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
          hintText: 'Chercher un suivi par titre ou type...',
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

  Widget _buildEventReportCard(Event event) {
    final bool isCompleted = event.status == EventStatus.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: SPColors.backgroundSecondary.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SPColors.borderPrimary.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getEventTypeColor(event.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getEventTypeIcon(event.type),
            color: _getEventTypeColor(event.type),
            size: 24,
          ),
        ),
        title: Text(
          event.title,
          style: SPTypography.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: SPColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd MMM yyyy • HH:mm').format(event.date),
                  style: SPTypography.caption.copyWith(color: SPColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isCompleted ? SPColors.success.withOpacity(0.1) : SPColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                event.status.toString().split('.').last.toUpperCase(),
                style: SPTypography.overline.copyWith(
                  color: isCompleted ? SPColors.success : SPColors.warning,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: SPColors.textTertiary),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventReportScreen(eventId: event.id!),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_chart_outlined, size: 64, color: SPColors.textTertiary.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'Aucun rapport disponible',
            style: SPTypography.bodyMedium.copyWith(color: SPColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Les suivis apparaîtront ici une fois créés.',
            style: SPTypography.caption.copyWith(color: SPColors.textTertiary),
          ),
        ],
      ),
    );
  }

  IconData _getEventTypeIcon(EventType type) {
    switch (type) {
      case EventType.testSession: return Icons.timer_outlined;
      case EventType.match: return Icons.sports_soccer;
      case EventType.evaluation: return Icons.assignment_outlined;
      case EventType.detection: return Icons.person_search_outlined;
      case EventType.medical: return Icons.medical_services_outlined;
      case EventType.recovery: return Icons.rebase_edit;
      default: return Icons.event;
    }
  }

  Color _getEventTypeColor(EventType type) {
    switch (type) {
      case EventType.testSession: return SPColors.primaryBlue;
      case EventType.match: return const Color(0xFFFFB020);
      case EventType.evaluation: return const Color(0xFF1CC98A);
      case EventType.detection: return const Color(0xFF9E77ED);
      case EventType.medical: return const Color(0xFFE95464);
      case EventType.recovery: return const Color(0xFF00D2FF);
      default: return SPColors.primaryBlue;
    }
  }
}
