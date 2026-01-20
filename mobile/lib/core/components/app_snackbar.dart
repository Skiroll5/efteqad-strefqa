import 'package:flutter/material.dart';

enum AppSnackBarType { info, success, warning, error }

class AppSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    AppSnackBarType type = AppSnackBarType.info,
    Duration? duration,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        build(
          context,
          message: message,
          title: title,
          type: type,
          duration: duration,
        ),
      );
  }

  static SnackBar build(
    BuildContext context, {
    required String message,
    String? title,
    AppSnackBarType type = AppSnackBarType.info,
    Duration? duration,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = _accentFor(type);
    final titleText = title?.trim();
    final hasTitle = titleText != null && titleText.isNotEmpty;

    return SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      duration: duration ?? _durationFor(type),
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: isDark ? 0.3 : 0.18),
              accent.withValues(alpha: isDark ? 0.55 : 0.35),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: accent.withValues(alpha: isDark ? 0.5 : 0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: isDark ? 0.6 : 0.2),
              ),
              child: Icon(
                _iconFor(type),
                color: isDark ? Colors.white : accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasTitle)
                    Text(
                      titleText,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Duration _durationFor(AppSnackBarType type) {
    switch (type) {
      case AppSnackBarType.success:
        return const Duration(seconds: 2);
      case AppSnackBarType.warning:
      case AppSnackBarType.error:
        return const Duration(seconds: 4);
      case AppSnackBarType.info:
        return const Duration(seconds: 3);
    }
  }

  static IconData _iconFor(AppSnackBarType type) {
    switch (type) {
      case AppSnackBarType.success:
        return Icons.check_circle_rounded;
      case AppSnackBarType.warning:
        return Icons.warning_rounded;
      case AppSnackBarType.error:
        return Icons.error_rounded;
      case AppSnackBarType.info:
        return Icons.info_rounded;
    }
  }

  static Color _accentFor(AppSnackBarType type) {
    switch (type) {
      case AppSnackBarType.success:
        return const Color(0xFF2E7D32);
      case AppSnackBarType.warning:
        return const Color(0xFFEF6C00);
      case AppSnackBarType.error:
        return const Color(0xFFC62828);
      case AppSnackBarType.info:
        return const Color(0xFF1565C0);
    }
  }
}
