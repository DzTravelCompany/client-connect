import 'dart:io';
import 'package:client_connect/constants.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/database.dart';
import 'sending_engine.dart';


class IsolateSendingService {
  late AppDatabase _db;
  final _storage = const FlutterSecureStorage();
  final _dio = Dio();

  Future<void> initialize() async {
    // Initialize database connection in isolate
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'client_connect.db'));
    _db = AppDatabase(NativeDatabase(file));
  }

  Future<void> processCampaign(
    int campaignId,
    Function(CampaignProgress) onProgress,
  ) async {
    try {
      // Get campaign details
      final campaign = await _getCampaign(campaignId);
      if (campaign == null) {
        throw Exception('Campaign not found');
      }

      // Get template
      final template = await _getTemplate(campaign.templateId);
      if (template == null) {
        throw Exception('Template not found');
      }

      // Get pending messages
      final pendingMessages = await _getPendingMessages(campaignId);
      if (pendingMessages.isEmpty) {
        onProgress(CampaignProgress(
          campaignId: campaignId,
          processed: 0,
          total: 0,
          successful: 0,
          failed: 0,
          currentStatus: 'No messages to send',
        ));
        return;
      }

      int processed = 0;
      int successful = 0;
      int failed = 0;
      final total = pendingMessages.length;

      // Load API credentials
      final smtpSettings = await _loadSmtpSettings();
      final whatsappSettings = await _loadWhatsAppSettings();

      // Process each message
      for (final message in pendingMessages) {
        try {
          onProgress(CampaignProgress(
            campaignId: campaignId,
            processed: processed,
            total: total,
            successful: successful,
            failed: failed,
            currentStatus: 'Processing message ${processed + 1} of $total',
          ));

          // Get client details
          final client = await _getClient(message.clientId);
          if (client == null) {
            await _updateMessageStatus(message.id, 'failed', 'Client not found');
            failed++;
            continue;
          }

          // Send message based on type
          if (message.type == 'email') {
            await _sendEmail(client, template, smtpSettings);
          } else if (message.type == 'whatsapp') {
            await _sendWhatsApp(client, template, whatsappSettings);
          }

          // Update message status to sent
          await _updateMessageStatus(message.id, 'sent');
          successful++;

          // Small delay to prevent overwhelming APIs
          await Future.delayed(const Duration(milliseconds: 500));

        } catch (e) {
          // Log the specific error
          await _updateMessageStatus(message.id, 'failed', e.toString());
          failed++;
          logger.e('Failed to send message ${message.id}: $e');
        }

        processed++;
      }

      // Send final progress
      onProgress(CampaignProgress(
        campaignId: campaignId,
        processed: processed,
        total: total,
        successful: successful,
        failed: failed,
        currentStatus: 'Campaign completed',
      ));

    } catch (e) {
      logger.e('Campaign processing error: $e');
      rethrow;
    }
  }

  // Email sending implementation
  Future<void> _sendEmail(
    Client client,
    Template template,
    SmtpSettings smtpSettings,
  ) async {
    if (client.email == null || client.email!.isEmpty) {
      throw Exception('Client has no email address');
    }

    // Personalize the message
    final personalizedSubject = _personalizeMessage(template.subject ?? '', client);
    final personalizedBody = _personalizeMessage(template.body, client);

    // Create SMTP server configuration
    final smtpServer = SmtpServer(
      smtpSettings.host,
      port: smtpSettings.port,
      username: smtpSettings.username,
      password: smtpSettings.password,
      ssl: smtpSettings.ssl,
    );

    // Create message
    final message = Message()
      ..from = Address(smtpSettings.username, smtpSettings.fromName)
      ..recipients.add(client.email!)
      ..subject = personalizedSubject
      ..text = personalizedBody;

    // Send email
    await send(message, smtpServer);
  }

  // WhatsApp sending implementation (placeholder for API integration)
  Future<void> _sendWhatsApp(
    Client client,
    Template template,
    WhatsAppSettings whatsappSettings,
  ) async {
    if (client.phone == null || client.phone!.isEmpty) {
      throw Exception('Client has no phone number');
    }

    // Personalize the message
    final personalizedMessage = _personalizeMessage(template.body, client);

    // WhatsApp API call (example using a generic WhatsApp Business API)
    final response = await _dio.post(
      whatsappSettings.apiUrl,
      options: Options(
        headers: {
          'Authorization': 'Bearer ${whatsappSettings.apiKey}',
          'Content-Type': 'application/json',
        },
      ),
      data: {
        'messaging_product': 'whatsapp',
        'to': client.phone,
        'type': 'text',
        'text': {
          'body': personalizedMessage,
        },
      },
    );

    if (response.statusCode != 200) {
      throw Exception('WhatsApp API error: ${response.statusMessage}');
    }
  }

  // Message personalization
  String _personalizeMessage(String message, Client client) {
    return message
        .replaceAll('{{first_name}}', client.firstName)
        .replaceAll('{{last_name}}', client.lastName)
        .replaceAll('{{full_name}}', '${client.firstName} ${client.lastName}')
        .replaceAll('{{email}}', client.email ?? '[No Email]')
        .replaceAll('{{phone}}', client.phone ?? '[No Phone]')
        .replaceAll('{{company}}', client.company ?? '[No Company]')
        .replaceAll('{{job_title}}', client.jobTitle ?? '[No Job Title]');
  }

  // Database helper methods
  Future<Campaign?> _getCampaign(int id) async {
    final query = _db.select(_db.campaigns)..where((c) => c.id.equals(id));
    return await query.getSingleOrNull();
  }

  Future<Template?> _getTemplate(int id) async {
    final query = _db.select(_db.templates)..where((t) => t.id.equals(id));
    return await query.getSingleOrNull();
  }

  Future<Client?> _getClient(int id) async {
    final query = _db.select(_db.clients)..where((c) => c.id.equals(id));
    return await query.getSingleOrNull();
  }

  Future<List<MessageLog>> _getPendingMessages(int campaignId) async {
    final query = _db.select(_db.messageLogs)
      ..where((m) => m.campaignId.equals(campaignId) & m.status.equals('pending'));
    return await query.get();
  }

  Future<void> _updateMessageStatus(int messageId, String status, [String? errorMessage]) async {
    final query = _db.update(_db.messageLogs)..where((m) => m.id.equals(messageId));
    await query.write(MessageLogsCompanion(
      status: Value(status),
      errorMessage: Value(errorMessage),
      sentAt: Value(status == 'sent' ? DateTime.now() : null),
    ));
  }

  // Settings loading methods
  Future<SmtpSettings> _loadSmtpSettings() async {
    return SmtpSettings(
      host: await _storage.read(key: 'smtp_host') ?? '',
      port: int.tryParse(await _storage.read(key: 'smtp_port') ?? '587') ?? 587,
      username: await _storage.read(key: 'smtp_username') ?? '',
      password: await _storage.read(key: 'smtp_password') ?? '',
      fromName: await _storage.read(key: 'smtp_from_name') ?? 'Client Connect',
      ssl: (await _storage.read(key: 'smtp_ssl')) == 'true',
    );
  }

  Future<WhatsAppSettings> _loadWhatsAppSettings() async {
    return WhatsAppSettings(
      apiUrl: await _storage.read(key: 'whatsapp_api_url') ?? '',
      apiKey: await _storage.read(key: 'whatsapp_api_key') ?? '',
    );
  }
}

// Settings classes
class SmtpSettings {
  final String host;
  final int port;
  final String username;
  final String password;
  final String fromName;
  final bool ssl;

  SmtpSettings({
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    required this.fromName,
    required this.ssl,
  });
}

class WhatsAppSettings {
  final String apiUrl;
  final String apiKey;

  WhatsAppSettings({
    required this.apiUrl,
    required this.apiKey,
  });
}