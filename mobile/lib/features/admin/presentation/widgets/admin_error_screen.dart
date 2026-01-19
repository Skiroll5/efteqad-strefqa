import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Full-page error screen for Admin Panel.
/// Provides a professional "Cannot Connect" experience with retry.
class AdminErrorScreen extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  final bool isAutoRetrying;

  const AdminErrorScreen({
    super.key,
    required this.error,
    required this.onRetry,
    this.isAutoRetrying = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final errorMessage = _getErrorMessage(error, l10n);
    final isConnectionError = _isConnectionError(error);

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
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Subtle error icon
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
                    isConnectionError
                        ? Icons.wifi_off_rounded
                        : Icons.error_outline_rounded,
                    size: 28,
                    color: AppColors.redPrimary.withValues(alpha: 0.9),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Title
              Text(
                isConnectionError
                    ? (l10n?.cannotConnect ?? 'Cannot Connect')
                    : (l10n?.somethingWentWrong ?? 'Something Went Wrong'),
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
                errorMessage,
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
              if (isAutoRetrying) ...[
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
        ),
      ),
    );
  }

  /// Check if error is a connection/network error
  static bool _isConnectionError(Object error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('socketexception') ||
        errorStr.contains('connection refused') ||
        errorStr.contains('network is unreachable') ||
        errorStr.contains('connection timed out') ||
        errorStr.contains('host lookup')) {
      return true;
    }

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return true;
        case DioExceptionType.unknown:
          if (error.message?.contains('SocketException') == true) {
            return true;
          }
          return false;
        default:
          return false;
      }
    }
    return false;
  }

  /// Get user-friendly error message
  static String _getErrorMessage(Object error, AppLocalizations? l10n) {
    if (_isConnectionError(error)) {
      return l10n?.serverConnectionError ??
          'Cannot connect to server. Please check your internet connection.';
    }

    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode != null) {
        if (statusCode >= 500) {
          return l10n?.serverError ?? 'Server error. Please try again later.';
        }
        if (statusCode == 401 || statusCode == 403) {
          return l10n?.unauthorized ?? 'Unauthorized. Please log in again.';
        }
      }
    }

    return l10n?.errorGeneric(error.toString()) ?? 'Error: $error';
  }
}

/// Helper function to check if an error is a connection error (exported for use elsewhere)
bool isConnectionError(Object error) {
  return AdminErrorScreen._isConnectionError(error);
}

/// Helper function to get error message (exported for use elsewhere)
String getAdminErrorMessage(Object error, AppLocalizations? l10n) {
  return AdminErrorScreen._getErrorMessage(error, l10n);
}
