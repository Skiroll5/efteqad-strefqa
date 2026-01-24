import 'package:flutter/material.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../l10n/app_localizations.dart';

class MessageHandler {
  static String getErrorMessage(BuildContext context, dynamic error) {
    final l10n = AppLocalizations.of(context)!;

    if (error is AuthError) {
      switch (error.code) {
        case 'INVALID_CREDENTIALS':
          return l10n.invalidCredentials;
        case 'TIMEOUT':
          return l10n.serverTimeout;
        case 'EMAIL_EXISTS':
          return l10n.emailAlreadyExists;
        case 'PHONE_EXISTS':
          return l10n.phoneAlreadyExists;
        case 'EMAIL_NOT_CONFIRMED':
          return l10n.emailNotConfirmed;
        case 'ACCOUNT_DISABLED':
          return l10n.accountDisabled;
        case 'INVALID_TOKEN':
          return l10n.invalidToken;
        case 'EXPIRED_TOKEN':
          return l10n.expiredToken;
        case 'PENDING_ACTIVATION':
          return l10n.accountPendingActivation;
        case 'ACTIVATION_DENIED':
          return l10n.accountDenied;
        case 'UNKNOWN':
        default:
          return error.message.isNotEmpty ? error.message : l10n.serverError;
      }
    }

    return l10n.errorGeneric(error.toString());
  }
}
