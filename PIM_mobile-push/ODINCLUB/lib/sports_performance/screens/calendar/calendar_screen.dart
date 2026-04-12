import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../models/event.dart';
import '../../providers/events_provider.dart';
import '../../theme/sp_colors.dart';
import '../../theme/sp_typography.dart';
import '../event_detail/event_detail_screen.dart';
import '../create_event/create_event_screen.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsyncValue = ref.watch(eventsProvider(null));

    return Scaffold(
      backgroundColor: SPColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Sports Performance'),
        backgroundColor: SPColors.backgroundPrimary,
        elevation: 0,
      ),
      body: eventsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Erreur: $error',
            style: SPTypography.bodyMedium.copyWith(color: SPColors.error),
          ),
        ),
        data: (events) {
          final selectedDayEvents = _getEventsForDay(_selectedDay!, events);

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildCalendarHeader(),
                _buildCalendar(events),
                const SizedBox(height: 24),
                _buildSelectedDateSection(selectedDayEvents),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateEventScreen(),
            ),
          );
        },
        backgroundColor: SPColors.primaryBlue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(_focusedDay),
                style: SPTypography.h3.copyWith(color: SPColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'SPORTS PERFORMANCE',
                style: SPTypography.overline.copyWith(
                  color: SPColors.primaryBlue,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                color: SPColors.textPrimary,
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(
                      _focusedDay.year,
                      _focusedDay.month - 1,
                    );
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                color: SPColors.textPrimary,
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(
                      _focusedDay.year,
                      _focusedDay.month + 1,
                    );
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(List<Event> events) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: SPColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SPColors.borderPrimary),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: _calendarFormat,
        startingDayOfWeek: StartingDayOfWeek.monday,
        eventLoader: (day) => _getEventsForDay(day, events),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: SPTypography.bodyMedium.copyWith(
            color: SPColors.textSecondary,
          ),
          defaultTextStyle: SPTypography.bodyMedium.copyWith(
            color: SPColors.textPrimary,
          ),
          selectedDecoration: const BoxDecoration(
            color: SPColors.primaryBlue,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: SPColors.primaryBlue.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: SPColors.primaryBlue,
            shape: BoxShape.circle,
          ),
        ),
        headerVisible: false,
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: SPTypography.caption.copyWith(
            color: SPColors.textTertiary,
          ),
          weekendStyle: SPTypography.caption.copyWith(
            color: SPColors.textTertiary,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDateSection(List<Event> events) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SPColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SPColors.borderPrimary),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SELECTED DATE',
                      style: SPTypography.overline.copyWith(
                        color: SPColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, MMM dd').format(_selectedDay!),
                      style: SPTypography.h4.copyWith(
                        color: SPColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: SPColors.primaryBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                    child: Text(
                    '${events.length} SUIVI${events.length > 1 ? 'S' : ''}',
                    style: SPTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (events.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Aucun suivi pour cette date',
                  style: SPTypography.bodyMedium.copyWith(
                    color: SPColors.textTertiary,
                  ),
                ),
              ),
            )
          else
            ...events.map((event) => _buildEventCard(event)),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: SPColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SPColors.borderPrimary),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: SPColors.backgroundTertiary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getEventIcon(event.type),
            color: SPColors.primaryBlue,
          ),
        ),
        title: Text(
          event.title,
          style: SPTypography.h5.copyWith(color: SPColors.textPrimary),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: SPColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('HH:mm').format(event.date),
                  style: SPTypography.caption.copyWith(
                    color: SPColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: SPColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  event.location,
                  style: SPTypography.caption.copyWith(
                    color: SPColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: _getStatusColor(event.status),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                event.statusLabel.toUpperCase(),
                style: SPTypography.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: SPColors.textTertiary,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(eventId: event.id!),
            ),
          );
        },
      ),
    );
  }

  List<Event> _getEventsForDay(DateTime day, List<Event> allEvents) {
    return allEvents.where((event) {
      return isSameDay(event.date, day);
    }).toList();
  }

  IconData _getEventIcon(EventType type) {
    switch (type) {
      case EventType.testSession:
        return Icons.fitness_center;
      case EventType.match:
        return Icons.sports_soccer;
      case EventType.evaluation:
        return Icons.assessment;
      case EventType.detection:
        return Icons.search;
      case EventType.medical:
        return Icons.medical_services_outlined;
      case EventType.recovery:
        return Icons.self_improvement_outlined;
      case EventType.aiAnalysis:
        return Icons.psychology;
    }
  }

  Color _getStatusColor(EventStatus status) {
    switch (status) {
      case EventStatus.draft:
        return SPColors.textTertiary;
      case EventStatus.inProgress:
        return SPColors.warning;
      case EventStatus.completed:
        return SPColors.success;
    }
  }
}
