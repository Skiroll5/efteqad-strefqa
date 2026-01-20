import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/premium_card.dart';
import '../../data/statistics_repository.dart';
import '../../../settings/data/settings_controller.dart';
// import '../screens/statistics_screen.dart'; // Removed as file is deleted

class StatisticsDashboard extends ConsumerWidget {
  const StatisticsDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    if (l10n == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            l10n.statisticsDashboard,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Chart Section
        Text(
          l10n.attendanceTrends,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: PremiumCard(
            padding: const EdgeInsets.only(
              right: 24,
              left: 12,
              top: 24,
              bottom: 12,
            ),
            child: const _AttendanceLineChart(),
          ),
        ).animate().fade().scale(),

        const SizedBox(height: 24),

        // At Risk Header
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.redPrimary,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.atRiskStudents,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Consumer(
              builder: (context, ref, _) {
                final threshold = ref.watch(statisticsSettingsProvider);
                return Padding(
                  padding: const EdgeInsets.only(left: 36, top: 4),
                  child: Text(
                    l10n.thresholdCaption(threshold),
                    style: theme.textTheme.titleSmall?.copyWith(
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),

        // At Risk List
        Consumer(
          builder: (context, ref, child) {
            final atRiskAsync = ref.watch(atRiskStudentsProvider);
            return atRiskAsync.when(
              data: (students) {
                if (students.isEmpty) {
                  return SizedBox(
                    width: double.infinity,
                    child: PremiumCard(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 48,
                              color: AppColors.goldPrimary.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.noAtRiskStudents,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ).animate().fade(),
                  );
                }

                return Column(
                  children: students.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return SizedBox(
                      width: double.infinity,
                      child: _AtRiskStudentCard(item: item)
                          .animate()
                          .fade(delay: (index * 100).ms)
                          .slideX(begin: 0.1),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text(l10n.errorGeneric(e.toString())),
            );
          },
        ),
      ],
    );
  }
}

class _AttendanceLineChart extends ConsumerWidget {
  const _AttendanceLineChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(weeklyStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return statsAsync.when(
      data: (stats) {
        if (stats.isEmpty) return Center(child: Text(AppLocalizations.of(context)?.notEnoughData ?? "Not enough data"));

        final spots = stats.asMap().entries.map((e) {
          return FlSpot(e.key.toDouble(), e.value.attendanceRate);
        }).toList();

        return LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= stats.length) {
                      return const SizedBox();
                    }
                    // Show limited labels to avoid crowding
                    if (stats.length > 6 && index % 2 != 0) {
                      return const SizedBox();
                    }

                    final date = stats[index].weekStart;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "${date.day}/${date.month}",
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: (stats.length - 1).toDouble(),
            minY: 0,
            maxY: 110,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: isDark ? AppColors.goldPrimary : AppColors.goldPrimary,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color:
                      (isDark ? AppColors.goldPrimary : AppColors.goldPrimary)
                          .withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text(AppLocalizations.of(context)!.genericError),
      ),
    );
  }
}

class _AtRiskStudentCard extends StatelessWidget {
  final AtRiskStudent item;

  const _AtRiskStudentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.redPrimary.withValues(alpha: 0.1),
          child: Text(
            item.student.name.characters.first.toUpperCase(),
            style: const TextStyle(
              color: AppColors.redPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          item.student.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.className ?? l10n.unknownClass,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black87,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.redPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                l10n.absentTimes(item.consecutiveAbsences),
                style: const TextStyle(
                  color: AppColors.redPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.goldPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.call, color: AppColors.goldDark, size: 20),
          ),
          onPressed: () async {
            if (item.student.phone != null) {
              final Uri launchUri = Uri(
                scheme: 'tel',
                path: item.student.phone!,
              );
              if (await canLaunchUrl(launchUri)) {
                await launchUrl(launchUri);
              }
            }
          },
        ),
      ),
    );
  }
}
