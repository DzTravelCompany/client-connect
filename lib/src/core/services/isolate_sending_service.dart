import 'dart:io';
import 'package:client_connect/constants.dart';
import 'package:client_connect/src/features/templates/data/template_block_model.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/database.dart';
import '../../features/templates/data/template_model.dart';
import 'sending_engine.dart';


class IsolateSendingService {

  final _uuid = Uuid();
  late AppDatabase _db;
  final _storage = const FlutterSecureStorage();
  final _dio = Dio();

  Future<void> initialize() async {
    try {


      // Initialize database connection in isolate
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'client_connect.db'));
      _db = AppDatabase(NativeDatabase(file));
      
      // Test database connection
      _db.select(_db.campaigns).limit(1);
      
      logger.i('Isolate database connection established successfully');
    } catch (e, stackTrace) {
      logger.e('Failed to initialize isolate sending service: $e', 
             error: e, stackTrace: stackTrace);
      rethrow;
    }
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
      logger.e('Campaign processing error: $e', error: e);
      
      // Send error progress update
      onProgress(CampaignProgress(
        campaignId: campaignId,
        processed: 0,
        total: 0,
        successful: 0,
        failed: 0,
        currentStatus: 'Error: $e',
      ));
      rethrow;
    }
  }

  // Email sending implementation with template block rendering
  Future<void> _sendEmail(
    Client client,
    Template template,
    SmtpSettings smtpSettings,
  ) async {
    if (client.email == null || client.email!.isEmpty) {
      throw Exception('Client has no email address');
    }

    // Convert database template to TemplateModel for advanced rendering
    final templateModel = TemplateModel.fromDatabase(template);
    
    String personalizedSubject;
    String personalizedBody;
    List<Attachment> emailAttachments = [];
    Map<String, String> localImageCidMap = {};

    if (templateModel.hasBlocks) {
      personalizedSubject = _personalizeMessage(templateModel.subject ?? templateModel.name, client);

      // Prepare attachments and CIDs for local images
      for (var block in templateModel.blocks) {
        if (block.type == TemplateBlockType.image) {
          final imageBlock = block as ImageBlock;
          if (imageBlock.imageUrl.isNotEmpty && 
              !imageBlock.imageUrl.startsWith('http://') && 
              !imageBlock.imageUrl.startsWith('https://')) {
            // This is a local file path
            try {
              final file = File(imageBlock.imageUrl);
              if (await file.exists()) {
                String cid = _uuid.v4();
                localImageCidMap[imageBlock.imageUrl] = cid;
                emailAttachments.add(
                  FileAttachment(file)
                    ..cid = '<$cid>' // Mailer package expects CIDs with angle brackets
                    ..location = Location.inline,
                );
              } else {
                logger.w('Local image file not found: ${imageBlock.imageUrl}');
              }
            } catch (e) {
              logger.e('Error processing local image file ${imageBlock.imageUrl}: $e');
            }
          }
        }
      }

      // Define the image source resolver for email HTML generation
      String emailImageSrcResolver(String imageUrl) {
        if (localImageCidMap.containsKey(imageUrl)) {
          return 'cid:${localImageCidMap[imageUrl]}';
        }
        return imageUrl;
      }
      
      // Generate HTML email body from template blocks using the resolver
      personalizedBody = templateModel.generateBodyFromBlocks(
        templateModel.templateType,
        imageSrcResolver: emailImageSrcResolver,
      );
      
      // Apply personalization to the rendered HTML
      personalizedBody = _personalizeHtmlContent(personalizedBody, client);

    } else {
      // Fallback to legacy rendering for templates without blocks (no image handling here)
      personalizedSubject = _personalizeMessage(template.subject ?? '', client);
      personalizedBody = _personalizeMessage(template.body, client);
    }

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
      ..html = personalizedBody // Use HTML instead of text for rich content
      ..attachments = emailAttachments; // Add collected attachments

    // Send email
    await send(message, smtpServer);
  }

  // WhatsApp sending implementation with template block rendering
  Future<void> _sendWhatsApp(
    Client client,
    Template template,
    WhatsAppSettings whatsappSettings,
  ) async {
    if (client.phone == null || client.phone!.isEmpty) {
      throw Exception('Client has no phone number');
    }

    // Convert database template to TemplateModel for advanced rendering
    final templateModel = TemplateModel.fromDatabase(template);
    
    // Generate personalized content using template blocks
    String personalizedMessage;
    
    if (templateModel.hasBlocks) {
      // Use the template model's advanced rendering system for WhatsApp
      personalizedMessage = templateModel.generateBodyFromBlocks(templateModel.templateType);
      
      // Apply personalization to the rendered text
      personalizedMessage = _personalizeMessage(personalizedMessage, client);
    } else {
      // Fallback to legacy rendering for templates without blocks
      personalizedMessage = _personalizeMessage(template.body, client);
    }

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

  // Enhanced personalization for HTML content (preserves HTML structure)
  String _personalizeHtmlContent(String htmlContent, Client client) {
    return htmlContent
        .replaceAll('{{first_name}}', _escapeHtml(client.firstName))
        .replaceAll('{{last_name}}', _escapeHtml(client.lastName))
        .replaceAll('{{full_name}}', _escapeHtml('${client.firstName} ${client.lastName}'))
        .replaceAll('{{email}}', _escapeHtml(client.email ?? '[No Email]'))
        .replaceAll('{{phone}}', _escapeHtml(client.phone ?? '[No Phone]'))
        .replaceAll('{{company}}', _escapeHtml(client.company ?? '[No Company]'))
        .replaceAll('{{job_title}}', _escapeHtml(client.jobTitle ?? '[No Job Title]'));
  }

  // Helper method to escape HTML entities for safe insertion
  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  // Database helper methods
  Future<Campaign?> _getCampaign(int id) async {
    final query = _db.select(_db.campaigns)..where((c) => c.id.equals(id));
    return await query.getSingleOrNull();
  }

  Future<Template?> _getTemplate(int id) async {
    final query = _db.select(_db.templates)..where((t) => t.id.equals(id));
    final template = await query.getSingleOrNull();
    
    if (template != null) {
      // Log template info for debugging
      logger.i('Loaded template: ${template.name}, blocks: ${template.blocksJson?.isNotEmpty == true ? 'Yes' : 'No'}');
    }
    
    return template;
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