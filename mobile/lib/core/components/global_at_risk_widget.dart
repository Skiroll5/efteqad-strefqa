import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobile/core/components/premium_card.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/home/data/home_insights_repository.dart';
import 'package:mobile/features/statistics/data/statistics_repository.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class GlobalAtRiskWidget extends StatelessWidget {
  final List<AtRiskStudent> atRiskStudents;
  final bool isDark;

  const GlobalAtRiskWidget({
    super.key,
    required this.atRiskStudents,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (atRiskStudents.isEmpty) {
      return PremiumCard(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  l10n?.noAtRiskStudents ?? "No students at risk! 🎉",
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().fade().scale(begin: const Offset(0.95, 0.95));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.redPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.redPrimary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                l10n?.atRiskStudents ?? "At Risk Students",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.redPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${atRiskStudents.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            itemCount: atRiskStudents.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = atRiskStudents[index];
              return _GlobalAtRiskItem(
                item: item,
                isDark: isDark,
              ).animate(delay: (index * 60).ms).fade().slideX(begin: 0.15);
            },
          ),
        ),
      ],
    );
  }
}

class _GlobalAtRiskItem extends ConsumerWidget {
  final AtRiskStudent item;
  final bool isDark;

  const _GlobalAtRiskItem({required this.item, required this.isDark});

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _openWhatsApp(WidgetRef ref, String phoneNumber) async {
    var cleanNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');

    final repo = ref.read(homeInsightsRepositoryProvider);
    String message = await repo.getStudentWhatsAppMessage(item.student.id);

    message = message.replaceAll('{student_name}', item.student.name);
    message = message.replaceAll('{name}', item.student.name);

    final Uri launchUri = Uri.parse(
      "https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}",
    );

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    }
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return AppColors.redPrimary;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final percentColor = _getPercentageColor(item.attendancePercentage);

    return SizedBox(
      width: 260,
      child: PremiumCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: () => context.push('/students/${item.student.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Avatar + Name + Class
                Row(
                  children: [
                    // Colored Avatar with gradient
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.redPrimary.withValues(alpha: 0.8),
                            AppColors.redPrimary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          item.student.name.characters.first.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.student.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.class_rounded,
                                size: 12,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.className,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Stats Row: Percentage + Sessions + Consecutive
                Row(
                  children: [
                    // Attendance Percentage
                    Expanded(
                      child: _StatBadge(
                        icon: Icons.percent,
                        value:
                            '${item.attendancePercentage.toStringAsFixed(0)}%',
                        color: percentColor,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Presences / Sessions
                    Expanded(
                      child: _StatBadge(
                        icon: Icons.event_available_rounded,
                        value: '${item.totalPresences}/${item.totalSessions}',
                        color: Colors.blueGrey,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Consecutive Absences
                    Expanded(
                      child: _StatBadge(
                        icon: Icons.cancel_rounded,
                        value: '${item.consecutiveAbsences}',
                        color: AppColors.redPrimary,
                        isDark: isDark,
                        tooltip: l10n?.consecutiveAbsences ?? 'Consecutive',
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Action Buttons
                Row(
                  children: [
                    if (item.phoneNumber != null &&
                        item.phoneNumber!.isNotEmpty) ...[
                      Expanded(
                        child: _ActionButton(
                          icon: FontAwesomeIcons.phone,
                          label: l10n?.call ?? 'Call',
                          color: Colors.teal,
                          onTap: () => _makePhoneCall(item.phoneNumber!),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionButton(
                          icon: FontAwesomeIcons.whatsapp,
                          label: 'WhatsApp',
                          color: const Color(0xFF25D366),
                          onTap: () => _openWhatsApp(ref, item.phoneNumber!),
                          isDark: isDark,
                        ),
                      ),
                    ] else
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              l10n?.noPhone ?? 'No phone number',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  final bool isDark;
  final String? tooltip;

  const _StatBadge({
    required this.icon,
    required this.value,
    required this.color,
    required this.isDark,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
