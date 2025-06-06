// lib/config/app_config.dart
import 'package:flutter/foundation.dart' show kReleaseMode, kDebugMode;

class AppConfig {
  static const String _webAppDomain = String.fromEnvironment('WEB_APP_DOMAIN');
  static const String _toyyibpaySecretKey    = String.fromEnvironment('TOYYIB_PAY_SECRET_KEY');
  static const String _toyyibpayCategoryCode = String.fromEnvironment('TOYYIB_PAY_CATEGORY_CODE');

  static const String _smtpHost = String.fromEnvironment('SMTP_HOST');
  static const String _smtpPortStr = String.fromEnvironment('SMTP_PORT');
  static const String _smtpUsername = String.fromEnvironment('SMTP_USERNAME');
  static const String _smtpPassword = String.fromEnvironment('SMTP_PASSWORD');
  static const String _senderEmail = String.fromEnvironment('SENDER_EMAIL');
  static const String _geminiAPIKey = String.fromEnvironment('GEMINI_API_KEY');
  final String geminiApiKey;

  AppConfig({required this.geminiApiKey});

  static String _getMandatoryKey(String value, String keyName, {String? debugFallback}) {
    if (value.isNotEmpty) return value;

    final message = "CRITICAL CONFIG ERROR: '$keyName' is not defined. Provide it via --dart-define.";
    print(message);

    if (kReleaseMode) {
      throw Exception(message); // Fail hard in release
    } else if (debugFallback != null) {
      print("Using debug fallback for $keyName: $debugFallback");
      return debugFallback;
    } else {
      // For keys that MUST have a value even in debug for core functionality to be testable
      throw Exception("$message Provide a dev value via --dart-define or set a AppConfig debugFallback.");
    }
  }

  static String getWebAppDomain() {
    // WEB_APP_DOMAIN is critical for web redirects.
    return _getMandatoryKey(_webAppDomain, 'WEB_APP_DOMAIN', debugFallback: "http://localhost:5000");
  }

  static String getToyyibPaySecretKey() {
    return _getMandatoryKey(_toyyibpaySecretKey, 'TOYYIB_PAY_SECRET_KEY');
  }

  static String getGeminiAPIKey() {
    return _getMandatoryKey(_geminiAPIKey, 'GEMINI_API_KEY');
  }

  static String getToyyibPayCategoryCode() {
    return _getMandatoryKey(_toyyibpayCategoryCode, 'TOYYIB_PAY_CATEGORY_CODE');
  }

  // SMTP Getters - more lenient as email might be optional or handled differently
  static String getSmtpHost() {
    if (_smtpHost.isEmpty) print("INFO: SMTP_HOST not defined via --dart-define. Mobile email might fail.");
    return _smtpHost;
  }

  static int getSmtpPort() {
    if (_smtpPortStr.isEmpty) print("INFO: SMTP_PORT not defined via --dart-define. Mobile email might fail.");
    return int.tryParse(_smtpPortStr) ?? (kDebugMode ? 587 : 0); // Common dev default or 0
  }

  static String getSmtpUsername() {
    if (_smtpUsername.isEmpty) print("INFO: SMTP_USERNAME not defined via --dart-define. Mobile email might fail.");
    return _smtpUsername;
  }

  static String getSmtpPassword() {
    if (_smtpPassword.isEmpty) print("INFO: SMTP_PASSWORD not defined via --dart-define. Mobile email might fail.");
    return _smtpPassword;
  }

  static String getSenderEmail() {
    if (_senderEmail.isEmpty) print("INFO: SENDER_EMAIL not defined via --dart-define. Mobile email might fail.");
    return _senderEmail;
  }
}