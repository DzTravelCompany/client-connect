import 'package:client_connect/constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:dio/dio.dart';
import 'settings_model.dart';

class SettingsService {
  static SettingsService? _instance;
  static SettingsService get instance => _instance ??= SettingsService._();
  SettingsService._();

  final _secureStorage = const FlutterSecureStorage();
  final _dio = Dio();

  // SMTP Settings Management
  Future<SmtpSettingsModel> getSmtpSettings() async {
    try {
      final data = await _secureStorage.readAll();
      return SmtpSettingsModel.fromSecureStorage(data);
    } catch (e) {
      return const SmtpSettingsModel(
        host: '',
        port: 587,
        username: '',
        password: '',
        fromName: 'Client Connect',
        ssl: true,
      );
    }
  }

  Future<void> saveSmtpSettings(SmtpSettingsModel settings) async {
    final data = settings.toSecureStorage();
    for (final entry in data.entries) {
      await _secureStorage.write(key: entry.key, value: entry.value);
    }
  }

  Future<bool> testSmtpConnection(SmtpSettingsModel settings) async {
    try {
      final smtpServer = SmtpServer(
        settings.host,
        port: settings.port,
        username: settings.username,
        password: settings.password,
        ssl: settings.ssl,
      );

      // Create a test message
      final message = Message()
        ..from = Address(settings.username, settings.fromName)
        ..recipients.add(settings.username) // Send to self for testing
        ..subject = 'Client Connect - Connection Test'
        ..text = 'This is a test message to verify SMTP configuration.';

      // Attempt to send the test message
      await send(message, smtpServer);
      return true;
    } catch (e) {
      logger.e('SMTP connection test failed: $e');
      return false;
    }
  }

  // WhatsApp Settings Management
  Future<WhatsAppSettingsModel> getWhatsAppSettings() async {
    try {
      final data = await _secureStorage.readAll();
      return WhatsAppSettingsModel.fromSecureStorage(data);
    } catch (e) {
      return const WhatsAppSettingsModel(
        apiUrl: '',
        apiKey: '',
        phoneNumberId: '',
      );
    }
  }

  Future<void> saveWhatsAppSettings(WhatsAppSettingsModel settings) async {
    final data = settings.toSecureStorage();
    for (final entry in data.entries) {
      await _secureStorage.write(key: entry.key, value: entry.value);
    }
  }

  Future<bool> testWhatsAppConnection(WhatsAppSettingsModel settings) async {
    try {
      // Test WhatsApp Business API connection
      final response = await _dio.get(
        '${settings.apiUrl}/v22.0/${settings.phoneNumberId}',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${settings.apiKey}',
          },
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      logger.e('WhatsApp connection test failed: $e');
      return false;
    }
  }

  // App Settings Management
  Future<AppSettingsModel> getAppSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return AppSettingsModel(
        theme: prefs.getString('theme') ?? 'system',
        enableNotifications: prefs.getBool('enable_notifications') ?? true,
        autoSaveEnabled: prefs.getBool('auto_save_enabled') ?? true,
        autoSaveInterval: prefs.getInt('auto_save_interval') ?? 2,
        language: prefs.getString('language') ?? 'en',
      );
    } catch (e) {
      return const AppSettingsModel();
    }
  }

  Future<void> saveAppSettings(AppSettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', settings.theme);
    await prefs.setBool('enable_notifications', settings.enableNotifications);
    await prefs.setBool('auto_save_enabled', settings.autoSaveEnabled);
    await prefs.setInt('auto_save_interval', settings.autoSaveInterval);
    await prefs.setString('language', settings.language);
  }

  // Clear all settings (for reset functionality)
  Future<void> clearAllSettings() async {
    await _secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}