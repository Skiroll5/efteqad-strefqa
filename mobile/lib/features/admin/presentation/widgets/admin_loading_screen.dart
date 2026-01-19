import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Full-page loading screen for Admin Panel.
/// Shows loading spinner initially, then error state after timeout.
/// Auto-retries every 5 seconds when in error state.
class AdminLoadingScreen extends StatefulWidget {
  final String? message;
  final VoidCallback? onRetry;
  final Duration timeoutDuration;
  final Duration autoRetryInterval;

  const AdminLoadingScreen({
    super.key,
    this.message,
    this.onRetry,
    this.timeoutDuration = const Duration(seconds: 10),
    this.autoRetryInterval = const Duration(seconds: 5),
  });

  @override
  State<AdminLoadingScreen> createState() => _AdminLoadingScreenState();
}

class _AdminLoadingScreenState extends State<AdminLoadingScreen> {
  bool _hasTimedOut = false;
  bool _isAutoRetrying = false;
  Timer? _timeoutTimer;
  Timer? _autoRetryTimer;

  @override
  void initState() {
    super.initState();
    _startTimeoutTimer();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _autoRetryTimer?.cancel();
    super.dispose();
  }

  void _startTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(widget.timeoutDuration, () {
      if (mounted) {
        setState(() => _hasTimedOut = true);
        _startAutoRetryTimer();
      }
    });
  }

  void _startAutoRetryTimer() {
    _autoRetryTimer?.cancel();
    _autoRetryTimer = Timer.periodic(widget.autoRetryInterval, (_) {
      if (mounted && _hasTimedOut) {
        _performAutoRetry();
      }
    });
  }

  void _performAutoRetry() {
    if (!mounted) return;
    setState(() => _isAutoRetrying = true);
    widget.onRetry?.call();
    // Reset state after a short delay to allow retry to take effect
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isAutoRetrying = false);
      }
    });
  }

  void _handleManualRetry() {
    setState(() {
      _hasTimedOut = false;
      _isAutoRetrying = false;
    });
    _autoRetryTimer?.cancel();
    widget.onRetry?.call();
    _startTimeoutTimer();
  }

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
        child: _hasTimedOut
            ? _buildErrorState(theme, isDark, l10n)
            : _buildLoadingState(theme, isDark, l10n),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme, bool isDark, AppLocalizations? l10n) {
    return Column(
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
          widget.message ?? l10n?.loadingData ?? 'Loading...',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ).animate().fade(delay: 300.ms),
      ],
    );
  }

  Widget _buildErrorState(ThemeData theme, bool isDark, AppLocalizations? l10n) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Error icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.redPrimary.withValues(alpha: 0.12)
                  : AppColors.redPrimary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.wifi_off_rounded,
                size: 28,
                color: AppColors.redPrimary.withValues(alpha: 0.9),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Title
          Text(
            l10n?.cannotConnect ?? 'Cannot Connect',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ).animate().fade(delay: 100.ms),

          const SizedBox(height: 6),

          // Error message
          Text(
            l10n?.actionFailedCheckConnection ??
                'Unable to connect. Please check your internet connection.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fade(delay: 150.ms),

          const SizedBox(height: 16),

          // Auto-retry indicator
          if (_isAutoRetrying) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.goldPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n?.autoRetrying ?? 'Retrying...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 6),
          Text(
            l10n?.willAutoRetry ?? 'Will auto-retry when connected',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white30 : Colors.black26,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
