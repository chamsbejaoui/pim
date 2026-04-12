import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/events_provider.dart';
import '../../models/event.dart';
import 'event_detail_screen.dart';
import 'event_form_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  void _loadEvents() {
    final provider = Provider.of<EventsProvider>(context, listen: false);
    final start = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
    final end = DateTime(_focusedDay.year, _focusedDay.month + 2, 0);
    provider.fetchCalendar(start, end);
    provider.fetchEvents();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EventsProvider>(context);
    final upcomingEvents = provider.events.where((e) {
      // show events from today onwards
      return e.startDate.isAfter(DateTime.now().subtract(const Duration(days: 1)));
    }).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
      
    final hasEventsToDisplay = upcomingEvents.isNotEmpty;

    return Scaffold(
      backgroundColor: OdinTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF020617),
                    Color(0xFF0B1120),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: OdinTheme.primaryBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: const Icon(
                      Icons.event_available_rounded,
                      color: OdinTheme.primaryBlue,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Entraînements & Matchs',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Planification et suivi des événements',
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ─── Calendar section ──────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Text(
                          DateFormat('MMMM yyyy').format(_focusedDay),
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded, color: Colors.white70),
                          onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1)),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => setState(() {
                            _focusedDay = DateTime.now();
                            _selectedDay = DateTime.now();
                            _loadEvents();
                          }),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: OdinTheme.primaryBlue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'TODAY',
                              style: TextStyle(color: OdinTheme.primaryBlue, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                          onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1)),
                        ),
                      ],
                    ),
                  ),
                  TableCalendar(
                    firstDay: DateTime(2023),
                    lastDay: DateTime(2030),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) => setState(() => _calendarFormat = format),
                    onPageChanged: (focusedDay) {
                      setState(() => _focusedDay = focusedDay);
                      _loadEvents();
                    },
                    eventLoader: (day) => provider.getEventsForDay(day),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: false,
                      leftChevronVisible: false,
                      rightChevronVisible: false,
                      titleTextStyle: TextStyle(fontSize: 0),
                      headerPadding: EdgeInsets.zero,
                      headerMargin: EdgeInsets.zero,
                    ),
                    calendarStyle: CalendarStyle(
                      defaultTextStyle: const TextStyle(color: Colors.white70, fontSize: 13),
                      weekendTextStyle: const TextStyle(color: Colors.white70, fontSize: 13),
                      outsideTextStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                      todayDecoration: BoxDecoration(
                        color: OdinTheme.primaryBlue.withValues(alpha: 0.15),
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: OdinTheme.primaryBlue, width: 2),
                      ),
                      markerDecoration: const BoxDecoration(color: OdinTheme.primaryBlue, shape: BoxShape.circle),
                      markersMaxCount: 4,
                    ),
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
                      weekendStyle: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        if (events.isEmpty) return null;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: events.take(3).map((e) {
                            final type = (e as dynamic).eventType;
                            Color c = OdinTheme.primaryBlue;
                            if (type == 'match') c = OdinTheme.accentOrange;
                            if (type == 'detection') c = OdinTheme.accentGreen;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        _LegendItem(label: 'MATCH', color: OdinTheme.accentOrange),
                        SizedBox(width: 16),
                        _LegendItem(label: 'TRAINING', color: OdinTheme.primaryBlue),
                        SizedBox(width: 16),
                        _LegendItem(label: 'SCOUTING', color: OdinTheme.accentGreen),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Selected day events header ───────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prochains Événements', // Upcoming Events header
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${upcomingEvents.length} événements à venir',
                        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                      ),
                    ],
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: OdinTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: OdinTheme.primaryBlue.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const EventFormScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Event list ──────────────────────────────
          if (!hasEventsToDisplay)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'Aucun événement programmé à venir',
                  style: TextStyle(color: OdinTheme.textTertiary),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildEventTile(upcomingEvents[i]),
                ),
                childCount: upcomingEvents.length,
              ),
            ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const EventFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildEventTile(Event event) {
    final typeColors = {
      'match': OdinTheme.accentOrange,
      'entrainement': OdinTheme.primaryBlue,
      'reunion': OdinTheme.accentCyan,
      'detection': OdinTheme.accentGreen,
      'test_physique': OdinTheme.accentPurple,
    };
    final color = typeColors[event.eventType] ?? OdinTheme.primaryBlue;
    final tf = DateFormat('HH:mm');
    final ampm = DateFormat('a');

    return GestureDetector(
      onTap: () {
        Provider.of<EventsProvider>(context, listen: false).selectEvent(event);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EventDetailScreen(eventId: event.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: const BoxConstraints(minHeight: 108),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            // Left Glow Bar
            Container(
              width: 4,
              height: 70,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)],
              ),
            ),
            const SizedBox(width: 20),
            
            // Time Column
            SizedBox(
              width: 60,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tf.format(event.startDate),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    ampm.format(event.startDate),
                    style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            
            // Info Column
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (event.location?.toUpperCase() ?? 'PITCH 1'),
                            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFF6B7280)),
                        const SizedBox(width: 4),
                        Text(
                          event.location ?? 'Main Training Complex',
                          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Stack(
                            children: [
                              CircleAvatar(radius: 10, backgroundColor: const Color(0xFF1F2937), child: Text('JD', style: TextStyle(fontSize: 8, color: color))),
                              Positioned(left: 12, child: CircleAvatar(radius: 10, backgroundColor: const Color(0xFF374151), child: Text('MK', style: TextStyle(fontSize: 8, color: color)))),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Spacer(),
                        Text(
                          'Lead: ${event.createdBy ?? 'Staff'}',
                          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
                          child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ],
    );
  }
}
