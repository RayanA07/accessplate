import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../domain/entities/user_constraints.dart';
import '../../domain/entities/user_profile.dart';
import '../copy/app_copy.dart';
import 'section_card.dart';

class WeeklyTrackerSection extends StatelessWidget {
  const WeeklyTrackerSection({
    super.key,
    required this.profile,
    required this.dailyTargetCalories,
  });

  final UserProfile profile;
  final double dailyTargetCalories;

  @override
  Widget build(BuildContext context) {
    final history = profile.constraints.loggedMealHistory;
    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    final copy = AppCopy(profile.constraints.access.language);
    final snapshot = _WeeklyTrackerSnapshot.fromHistory(
      history: history,
      dailyTargetCalories: dailyTargetCalories,
      now: DateTime.now(),
      copy: copy,
    );

    return SectionCard(
      key: const ValueKey('weekly-tracker-section'),
      fillColor: NihPalette.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            copy.choose('This week at a glance.', 'Esta semana de un vistazo.'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            copy.choose(
              'Calories logged across the current week.',
              'Calorias registradas durante la semana actual.',
            ),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: NihPalette.grayDark),
          ),
          const SizedBox(height: 14),
          Text(
            copy.choose('Calories logged', 'Calorias registradas'),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: NihPalette.grayDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 220,
            child: BarChart(
              key: const ValueKey('weekly-calorie-chart'),
              _buildChartData(context, snapshot),
            ),
          ),
          const SizedBox(height: 18),
          _WeeklySummaryLine(
            key: const ValueKey('weekly-days-logged'),
            label: copy.choose(
              'Days logged this week',
              'Dias registrados esta semana',
            ),
            value: '${snapshot.daysLogged}/7',
          ),
          const SizedBox(height: 8),
          _WeeklySummaryLine(
            key: const ValueKey('weekly-average-calories'),
            label: copy.choose('Average calories', 'Calorias promedio'),
            value: '${snapshot.averageCalories.round()}kcal',
          ),
          const SizedBox(height: 8),
          _WeeklySummaryLine(
            key: const ValueKey('weekly-most-logged-meal'),
            label: copy.choose('Most logged meal', 'Comida mas registrada'),
            value: snapshot.mostLoggedMeal,
          ),
        ],
      ),
    );
  }

  BarChartData _buildChartData(
    BuildContext context,
    _WeeklyTrackerSnapshot snapshot,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final maxCalories = snapshot.maxCalories <= 0
        ? dailyTargetCalories
        : snapshot.maxCalories > dailyTargetCalories
        ? snapshot.maxCalories
        : dailyTargetCalories;
    final maxY = _roundedMaxY(maxCalories);
    final interval = maxY <= 0 ? 100.0 : (maxY / 4).clamp(100.0, maxY);

    return BarChartData(
      minY: 0,
      maxY: maxY,
      alignment: BarChartAlignment.spaceAround,
      gridData: FlGridData(
        drawVerticalLine: false,
        horizontalInterval: interval,
        getDrawingHorizontalLine: (value) => FlLine(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant),
          left: BorderSide(color: scheme.outlineVariant),
          top: BorderSide.none,
          right: BorderSide.none,
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            interval: interval,
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  value.round().toString(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: NihPalette.grayDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= snapshot.days.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  snapshot.days[index].label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: snapshot.days[index].isToday
                        ? NihPalette.primaryDarkest
                        : NihPalette.grayDark,
                    fontWeight: snapshot.days[index].isToday
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      barTouchData: BarTouchData(enabled: false),
      barGroups: [
        for (var index = 0; index < snapshot.days.length; index++)
          BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: snapshot.days[index].calories,
                width: 22,
                color: snapshot.days[index].color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                borderSide: snapshot.days[index].isToday
                    ? const BorderSide(
                        color: NihPalette.primaryDarkest,
                        width: 2,
                      )
                    : BorderSide.none,
              ),
            ],
          ),
      ],
    );
  }

  double _roundedMaxY(double base) {
    final safeBase = base <= 0 ? 400.0 : base;
    final rounded = ((safeBase * 1.1) / 100).ceil() * 100;
    return rounded.toDouble().clamp(400.0, 10000.0);
  }
}

class _WeeklySummaryLine extends StatelessWidget {
  const _WeeklySummaryLine({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            '$label:',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: NihPalette.grayDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _WeeklyTrackerSnapshot {
  const _WeeklyTrackerSnapshot({
    required this.days,
    required this.daysLogged,
    required this.averageCalories,
    required this.maxCalories,
    required this.mostLoggedMeal,
  });

  final List<_WeekDaySnapshot> days;
  final int daysLogged;
  final double averageCalories;
  final double maxCalories;
  final String mostLoggedMeal;

  factory _WeeklyTrackerSnapshot.fromHistory({
    required List<LoggedMealEntry> history,
    required double dailyTargetCalories,
    required DateTime now,
    required AppCopy copy,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final dayStartByIndex = <int, DateTime>{
      for (var index = 0; index < 7; index++)
        index: weekStart.add(Duration(days: index)),
    };
    final caloriesByIndex = <int, double>{
      for (var index = 0; index < 7; index++) index: 0,
    };
    final logsThisWeek = <LoggedMealEntry>[];

    for (final entry in history) {
      final loggedDay = DateTime(
        entry.loggedAt.year,
        entry.loggedAt.month,
        entry.loggedAt.day,
      );
      final dayOffset = loggedDay.difference(weekStart).inDays;
      if (dayOffset < 0 || dayOffset > 6) {
        continue;
      }
      caloriesByIndex[dayOffset] =
          (caloriesByIndex[dayOffset] ?? 0) + entry.caloriesKcal;
      logsThisWeek.add(entry);
    }

    final days = <_WeekDaySnapshot>[
      for (var index = 0; index < 7; index++)
        _WeekDaySnapshot(
          label: _dayLabel(index),
          calories: caloriesByIndex[index] ?? 0,
          isToday: _sameDay(dayStartByIndex[index]!, today),
          color: _barColor(
            calories: caloriesByIndex[index] ?? 0,
            dailyTargetCalories: dailyTargetCalories,
          ),
        ),
    ];
    final daysLogged = days.where((day) => day.calories > 0).length;
    final totalCalories = days.fold<double>(
      0,
      (sum, day) => sum + day.calories,
    );
    final averageCalories = daysLogged == 0 ? 0.0 : totalCalories / daysLogged;
    final maxCalories = days.fold<double>(
      0,
      (current, day) => day.calories > current ? day.calories : current,
    );

    return _WeeklyTrackerSnapshot(
      days: days,
      daysLogged: daysLogged,
      averageCalories: averageCalories,
      maxCalories: maxCalories,
      mostLoggedMeal: _mostLoggedMeal(logsThisWeek, copy),
    );
  }

  static String _dayLabel(int index) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[index];
  }

  static Color _barColor({
    required double calories,
    required double dailyTargetCalories,
  }) {
    if (calories <= 0) {
      return NihPalette.grayLight;
    }
    final lowerBound = dailyTargetCalories * 0.8;
    final upperBound = dailyTargetCalories * 1.2;
    if (calories >= lowerBound && calories <= upperBound) {
      return NihPalette.success;
    }
    return NihPalette.warning;
  }

  static String _mostLoggedMeal(List<LoggedMealEntry> logs, AppCopy copy) {
    if (logs.isEmpty) {
      return copy.choose('None this week', 'Nada esta semana');
    }

    final counts = <String, int>{};
    final latestAt = <String, DateTime>{};
    for (final entry in logs) {
      counts[entry.mealName] = (counts[entry.mealName] ?? 0) + 1;
      final currentLatest = latestAt[entry.mealName];
      if (currentLatest == null || entry.loggedAt.isAfter(currentLatest)) {
        latestAt[entry.mealName] = entry.loggedAt;
      }
    }

    final ranked = counts.keys.toList()
      ..sort((left, right) {
        final countCompare = (counts[right] ?? 0).compareTo(counts[left] ?? 0);
        if (countCompare != 0) {
          return countCompare;
        }
        final latestCompare =
            (latestAt[right] ?? DateTime.fromMillisecondsSinceEpoch(0))
                .compareTo(
                  latestAt[left] ?? DateTime.fromMillisecondsSinceEpoch(0),
                );
        if (latestCompare != 0) {
          return latestCompare;
        }
        return left.compareTo(right);
      });
    return ranked.first;
  }

  static bool _sameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}

class _WeekDaySnapshot {
  const _WeekDaySnapshot({
    required this.label,
    required this.calories,
    required this.isToday,
    required this.color,
  });

  final String label;
  final double calories;
  final bool isToday;
  final Color color;
}
