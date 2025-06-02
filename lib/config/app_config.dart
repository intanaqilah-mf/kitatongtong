// lib/config/app_config.dart
import 'package:flutter/foundation.dart' show kReleaseMode;

class AppConfig {
  // These consts will be populated by --dart-define at build time.
  // If a --dart-define flag is missing for a key, String.fromEnvironment returns an empty string.
  static const String _webAppDomain = String.fromEnvironment('WEB_APP_DOMAIN');
  static const String _toyyibPaySecretKey = String.fromEnvironment('TOYYIBPAY_SECRET_KEY');
  static const String _toyyibPayCategoryCode = String.fromEnvironment('TOYYIBPAY_CATEGORY_CODE');

  // SMTP Configuration (if you decide to use email sending)
  static const String _smtpHost = String.fromEnvironment('SMTP_HOST');
  static const String _smtpPortStr = String.fromEnvironment('SMTP_PORT');
  static const String _smtpUsername = String.fromEnvironment('SMTP_USERNAME');
  static const String _smtpPassword = String.fromEnvironment('SMTP_PASSWORD');
  static const String _senderEmail = String.fromEnvironment('SENDER_EMAIL');

  // --- Getters with runtime checks ---
  static String getWebAppDomain() {
    if (_webAppDomain.isEmpty) {
      final message = "CRITICAL: WEB_APP_DOMAIN is not defined via --dart-define.";
      print(message);
      if (kReleaseMode) throw Exception(message); // Fail hard in release
      return "http://localhost:5000"; // Fallback for non-release local run only
    }
    return _webAppDomain;
  }

  static String getToyyibPaySecretKey() {
    if (_toyyibPaySecretKey.isEmpty) {
      final message = "CRITICAL: TOYYIBPAY_SECRET_KEY is not defined via --dart-define.";
      print(message);
      if (kReleaseMode) throw Exception(message);
      return ""; // Will cause API error
    }
    return _toyyibPaySecretKey;
  }

  static String getToyyibPayCategoryCode() {
    if (_toyyibPayCategoryCode.isEmpty) {
      final message = "CRITICAL: TOYYIBPAY_CATEGORY_CODE is not defined via --dart-define.";
      print(message);
      if (kReleaseMode) throw Exception(message);
      return ""; // Will cause API error
    }
    return _toyyibPayCategoryCode;
  }

  // SMTP Getters
  static String getSmtpHost() {
    if (_smtpHost.isEmpty && kReleaseMode) print("WARNING: SMTP_HOST not defined (email may fail).");
    return _smtpHost;
  }

  static int getSmtpPort() {
    if (_smtpPortStr.isEmpty && kReleaseMode) print("WARNING: SMTP_PORT not defined (email may fail).");
    return int.tryParse(_smtpPortStr) ?? 0; // Default to 0 or common port like 587 if preferred
  }

  static String getSmtpUsername() {
    if (_smtpUsername.isEmpty && kReleaseMode) print("WARNING: SMTP_USERNAME not defined (email may fail).");
    return _smtpUsername;
  }

  static String getSmtpPassword() {
    if (_smtpPassword.isEmpty && kReleaseMode) print("WARNING: SMTP_PASSWORD not defined (email may fail).");
    return _smtpPassword;
  }

  static String getSenderEmail() {
    if (_senderEmail.isEmpty && kReleaseMode) print("WARNING: SENDER_EMAIL not defined (email may fail).");
    return _senderEmail;
  }
}