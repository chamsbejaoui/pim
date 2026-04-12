import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/player_model.dart';
import '../../services/player_service.dart';
import '../../theme/app_theme.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/app_section_header.dart';
import '../../ui/theme/app_spacing.dart';

class MedicalRecoveryCalendarScreen extends StatefulWidget {
  const MedicalRecoveryCalendarScreen({super.key});

  @override
  State<MedicalRecoveryCalendarScreen> createState() =>
      _MedicalRecoveryCalendarScreenState();
}

class _MedicalRecoveryCalendarScreenState
    extends State<MedicalRecoveryCalendarScreen> {
  final PlayerService _playerService = PlayerService();
  final List<Color> _palette = [
    AppTheme.success,
    AppTheme.warning,
    AppTheme.danger,
    AppTheme.accentBlue,
    AppTheme.primaryBlue,
  ];
  late Future<List<PlayerModel>> _playersFuture;
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _playersFuture = _playerService.fetchPlayers();
    final today = DateTime.now();
    _focusedDay = DateTime(today.year, today.month, today.day);
    _selectedDay = _focusedDay;
  }

  DateTime _dayKey(DateTime day) => DateTime(day.year, day.month, day.day);

  Color _colorForPlayer(PlayerModel player) {
    final index = player.id.hashCode.abs() % _palette.length;
    return _palette[index];
  }

  Map<DateTime, List<_ReturnEntry>> _buildEvents(List<PlayerModel> players) {
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    final Map<DateTime, List<_ReturnEntry>> events = {};

    for (final player in players) {
      if (player.isInjured != true) {
        continue;
      }
      final recoveryDays = player.lastRecoveryDays ?? 0;
      if (recoveryDays <= 0) {
        continue;
      }
      final returnDate = _dayKey(base.add(Duration(days: recoveryDays)));
      events.putIfAbsent(returnDate, () => []);
      events[returnDate]!.add(
        _ReturnEntry(
          player: player,
          returnDate: returnDate,
          recoveryDays: recoveryDays,
          color: _colorForPlayer(player),
        ),
      );
    }

    return events;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Recovery Calendar',
            subtitle: 'Estimated return dates for injured players.',
          ),
          const SizedBox(height: AppSpacing.s16),
          FutureBuilder<List<PlayerModel>>(
            future: _playersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text(
                  'Unable to load recovery calendar.',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              }

              final players = snapshot.data ?? const [];
              final events = _buildEvents(players);
              final selectedDay = _selectedDay ?? _focusedDay;
              final selectedEvents = events[_dayKey(selectedDay)] ?? const [];
              final allEntries = events.values.expand((e) => e).toList()
                ..sort((a, b) => a.returnDate.compareTo(b.returnDate));
              final legendEntries = <_ReturnEntry>{
                for (final entry in allEntries) entry,
              }.toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppCard(
                    child: TableCalendar<_ReturnEntry>(
                      firstDay: _focusedDay.subtract(const Duration(days: 120)),
                      lastDay: _focusedDay.add(const Duration(days: 365)),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(day, _selectedDay),
                      eventLoader: (day) => events[_dayKey(day)] ?? const [],
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      headerStyle: HeaderStyle(
                        titleCentered: true,
                        formatButtonVisible: false,
                        titleTextStyle:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ) ??
                            const TextStyle(fontSize: 16),
                        leftChevronIcon: const Icon(
                          Icons.chevron_left,
                          size: 20,
                        ),
                        rightChevronIcon: const Icon(
                          Icons.chevron_right,
                          size: 20,
                        ),
                      ),
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: AppTheme.accentBlue.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: BoxDecoration(
                          color: AppTheme.warning,
                          shape: BoxShape.circle,
                        ),
                        markersMaxCount: 3,
                        defaultTextStyle: TextStyle(
                          color: AppTheme.textPrimary,
                        ),
                        weekendTextStyle: TextStyle(
                          color: AppTheme.textSecondary,
                        ),
                        outsideTextStyle: TextStyle(color: AppTheme.textMuted),
                      ),
                      calendarBuilders: CalendarBuilders<_ReturnEntry>(
                        markerBuilder: (context, day, events) {
                          if (events.isEmpty) {
                            return null;
                          }
                          final visible = events.take(3).toList();
                          return Align(
                            alignment: Alignment.bottomCenter,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final entry in visible)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: entry.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                if (events.length > visible.length)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 2),
                                    child: Text(
                                      '+${events.length - visible.length}',
                                      style: const TextStyle(fontSize: 9),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(color: AppTheme.textSecondary),
                        weekendStyle: TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  if (legendEntries.isNotEmpty) ...[
                    Text(
                      'Legend',
                      style:
                          Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ) ??
                          const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: legendEntries
                          .map(
                            (entry) => _LegendChip(
                              name: entry.player.name,
                              color: entry.color,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                  ],
                  Text(
                    'Return on ${DateFormat('dd MMM yyyy').format(selectedDay)}',
                    style:
                        Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ) ??
                        const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  if (selectedEvents.isEmpty)
                    Text(
                      'No players scheduled to return on this date.',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    Column(
                      children: selectedEvents
                          .map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _ReturnRow(entry: entry),
                            ),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: AppSpacing.s16),
                  Text(
                    'All injured players',
                    style:
                        Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ) ??
                        const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  if (allEntries.isEmpty)
                    Text(
                      'No injured players with recovery dates yet.',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    Column(
                      children: allEntries
                          .map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _ReturnRow(entry: entry),
                            ),
                          )
                          .toList(),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder.withOpacity(0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: textTheme.bodySmall ?? const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ReturnRow extends StatelessWidget {
  const _ReturnRow({required this.entry});

  final _ReturnEntry entry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: entry.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Icon(Icons.health_and_safety, color: AppTheme.accentBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.player.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Return in ${entry.recoveryDays} days',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('dd/MM').format(entry.returnDate),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _ReturnEntry {
  const _ReturnEntry({
    required this.player,
    required this.returnDate,
    required this.recoveryDays,
    required this.color,
  });

  final PlayerModel player;
  final DateTime returnDate;
  final int recoveryDays;
  final Color color;
}
