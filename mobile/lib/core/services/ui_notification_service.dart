import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/components/app_snackbar.dart';

final uiNotificationServiceProvider = Provider<UiNotificationService>((ref) {
  return UiNotificationService();
});

enum UiNotificationLevel { info, success, warning, error }

class UiNotificationService {
  final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  void show({
    required String message,
    String? title,
    UiNotificationLevel level = UiNotificationLevel.info,
  }) {
    final messenger = messengerKey.currentState;
    if (messenger == null) return;

    final text = title == null || title.trim().isEmpty
        ? message
        : '$title: $message';
    final type = _typeFor(level);

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        AppSnackBar.build(
          messenger.context,
          message: text,
          type: type,
        ),
      );
  }

  AppSnackBarType _typeFor(UiNotificationLevel level) {
    switch (level) {
      case UiNotificationLevel.success:
        return AppSnackBarType.success;
      case UiNotificationLevel.warning:
        return AppSnackBarType.warning;
      case UiNotificationLevel.error:
        return AppSnackBarType.error;
      case UiNotificationLevel.info:
      default:
        return AppSnackBarType.info;
    }
  }
}
