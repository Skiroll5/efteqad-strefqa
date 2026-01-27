import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobile/core/components/premium_card.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/home/data/home_insights_repository.dart';
import 'package:mobile/features/statistics/data/statistics_repository.dart';
import 'package:mobile/features/auth/data/auth_controller.dart';
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
    final l10n = AppLocalizations.of(context)!;

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
                  l10n.noAtRiskStudents,
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
                l10n.atRiskStudents,
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
          height: 200,
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

  Future<void> _openWhatsApp(
    BuildContext context,
    WidgetRef ref,
    String phoneNumber,
  ) async {
    var cleanNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final repo = ref.read(homeInsightsRepositoryProvider);
    final user = ref.read(authControllerProvider).value;

    // Use default if user is null (shouldn't happen if logged in)
    if (user == null) return;

    final message = await repo.getStudentWhatsAppMessage(
      item.student.id,
      user: user,
      defaultTemplate: AppLocalizations.of(context)!.whatsappDefaultTemplate,
    );

    final Uri launchUri = Uri.parse(
      "https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}",
    );

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    }
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 75) return const Color(0xFF25D366);
    if (percentage >= 50) return Colors.amber;
    return AppColors.redPrimary;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final percentColor = _getPercentageColor(item.attendancePercentage);

    return SizedBox(
      width: 240,
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
                // Top Row: Avatar + Info + Circular Progress
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar with percentage color
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            percentColor.withValues(alpha: 0.7),
                            percentColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          item.student.name.characters.first.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Name + Class
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.student.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.className ?? l10n.unknownClass,
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Circular Progress
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 4,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.06),
                            ),
                          ),
                          CircularProgressIndicator(
                            value: item.attendancePercentage / 100,
                            strokeWidth: 4,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              percentColor,
                            ),
                          ),
                          Text(
                            '${item.attendancePercentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: percentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Stats Row in a subtle container
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      // Present count - left half
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 14,
                              color: const Color(0xFF25D366),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${item.totalPresences}/${item.totalSessions}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              l10n.present,
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? Colors.white38 : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Vertical divider
                      Container(
                        width: 1,
                        height: 24,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.1),
                      ),
                      // Consecutive absences - right half
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: isDark
                                  ? Colors.redAccent
                                  : AppColors.redPrimary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${item.consecutiveAbsences}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.redAccent
                                    : AppColors.redPrimary,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              l10n.consecutiveAbsences,
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? Colors.white38 : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                          label: l10n.call,
                          color: Colors.teal,
                          onTap: () => _makePhoneCall(item.phoneNumber!),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionButton(
                          icon: FontAwesomeIcons.whatsapp,
                          label: l10n.whatsappButton,
                          color: const Color(0xFF25D366),
                          onTap: () =>
                              _openWhatsApp(context, ref, item.phoneNumber!),
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
                              l10n.noPhone,
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
