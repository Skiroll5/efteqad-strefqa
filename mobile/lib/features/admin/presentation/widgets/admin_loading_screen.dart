import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Full-page loading screen for Admin Panel.
/// Provides a professional, subtle loading experience.
class AdminLoadingScreen extends StatelessWidget {
  final String? message;

  const AdminLoadingScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.backgroundDark, AppColors.surfaceDark]
              : [AppColors.backgroundLight, Colors.white],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Subtle loading indicator
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.goldPrimary.withValues(alpha: 0.8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message ?? l10n?.loadingData ?? 'Loading...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ).animate().fade(delay: 300.ms),
          ],
        ),
      ),
    );
  }
}
