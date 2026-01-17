import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/components/premium_card.dart';
import 'package:mobile/core/theme/app_colors.dart';
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n?.noAtRiskStudents ?? "No students at risk! 🎉",
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().fade();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.redPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n?.atRiskStudents ?? "At Risk Students",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 150, // Fixed height for horizontal cards
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: atRiskStudents.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = atRiskStudents[index];
              return _GlobalAtRiskItem(
                item: item,
                isDark: isDark,
              ).animate().fade(delay: (index * 50).ms).slideX(begin: 0.1);
            },
          ),
        ),
      ],
    );
  }
}

class _GlobalAtRiskItem extends StatelessWidget {
  final AtRiskStudent item;
  final bool isDark;

  const _GlobalAtRiskItem({required this.item, required this.isDark});

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    var cleanNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final Uri launchUri = Uri.parse("https://wa.me/$cleanNumber");
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Using SizedBox to enforce width since PremiumCard doesn't have width prop
    return SizedBox(
      width: 280,
      child: PremiumCard(
        padding: EdgeInsets.zero, // Use internal padding
        child: InkWell(
          onTap: () {
            context.push('/students/${item.student.id}');
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.redPrimary.withValues(
                        alpha: 0.1,
                      ),
                      child: Text(
                        item.student.name.characters.first.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.redPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            item.className,
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.redPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "${item.consecutiveAbsences} ${l10n?.absent ?? 'Absent'}",
                        style: const TextStyle(
                          color: AppColors.redPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        if (item.phoneNumber != null &&
                            item.phoneNumber!.isNotEmpty) ...[
                          _ActionButton(
                            icon: Icons.call,
                            color: Colors.blue,
                            onTap: () => _makePhoneCall(item.phoneNumber!),
                          ),
                          const SizedBox(width: 8),
                          _ActionButton(
                            icon: Icons.message,
                            color: Colors.green,
                            isWhatsApp: true,
                            onTap: () => _openWhatsApp(item.phoneNumber!),
                          ),
                        ] else
                          Text(
                            l10n?.noPhone ?? 'No Phone',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white30 : Colors.black38,
                            ),
                          ),
                      ],
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
  final Color color;
  final VoidCallback onTap;
  final bool isWhatsApp;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.isWhatsApp = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            isWhatsApp ? Icons.chat_bubble_outline : icon,
            size: 18,
            color: color,
          ),
        ),
      ),
    );
  }
}
