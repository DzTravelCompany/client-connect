import 'dart:convert';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
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
import 'whatsapp_media_cache_manager.dart';
import 'whatsapp_error_handler.dart';
import '../utils/algerian_phone_validator.dart';


class WhatsAppMessageContent {
  final List<String> textMessages;
  final List<WhatsAppMediaMessage> mediaMessages;

  WhatsAppMessageContent({
    required this.textMessages,
    required this.mediaMessages,
  });

  bool get hasContent => textMessages.isNotEmpty || mediaMessages.isNotEmpty;
  bool get hasMedia => mediaMessages.isNotEmpty;
}

class WhatsAppMediaMessage {
  final String mediaId;
  final String mediaType; // 'image', 'document', 'video', 'audio'
  final String? caption;
  final String originalPath;

  WhatsAppMediaMessage({
    required this.mediaId,
    required this.mediaType,
    this.caption,
    required this.originalPath,
  });
}

class IsolateSendingService {

  final _uuid = Uuid();
  late AppDatabase _db;
  final _storage = const FlutterSecureStorage();
  final _dio = Dio();
  final _mediaCacheManager = WhatsAppMediaCacheManager();
  final _errorHandler = WhatsAppErrorHandler();

  Future<void> initialize() async {
    try {
      // Initialize database connection in isolate
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'client_connect.db'));
      _db = AppDatabase(NativeDatabase(file));
      
      // Test database connection
      _db.select(_db.campaigns).limit(1);

      // Initialize supporting services
      await _mediaCacheManager.initialize();
      await _errorHandler.initialize();
      
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

      logger.i('Starting campaign $campaignId with $total messages');

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

          logger.d('Processing message ${message.id} for client ${client.firstName} ${client.lastName}');

          // Send message based on type
          if (message.type == 'email') {
            await _sendEmail(client, template, smtpSettings);
          } else if (message.type == 'whatsapp') {
            await _sendWhatsAppWithErrorHandling(client, template, whatsappSettings, message.id);
          }

          // Update message status to sent
          await _updateMessageStatus(message.id, 'sent');
          successful++;

          logger.d('Message ${message.id} sent successfully');

          // Small delay to prevent overwhelming APIs
          await Future.delayed(const Duration(milliseconds: 500));

        } catch (e) {
          // Enhanced error logging with context
          final errorMessage = e.toString();
          logger.e('Failed to send message ${message.id}: $errorMessage');
           // Update message status with detailed error
          await _updateMessageStatus(message.id, 'failed', errorMessage);
          failed++;
          // Log error to error handler if it's a WhatsApp error
          if (message.type == 'whatsapp') {
            try {
              final client = await _getClient(message.clientId);
              await _errorHandler.handleError(
                Exception(errorMessage),
                phoneNumber: client?.phone,
                context: 'Campaign message sending',
              );
            } catch (handlerError) {
              logger.w('Failed to log error to error handler: $handlerError');
            }
          }
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

      logger.i('Campaign $campaignId completed: $successful successful, $failed failed out of $total total');

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

  Future<void> _sendWhatsAppWithErrorHandling(
    Client client,
    Template template,
    WhatsAppSettings whatsappSettings,
    int messageId,
  ) async {
    try {
      await _sendWhatsApp(client, template, whatsappSettings);
    } catch (e) {
      // Handle and categorize the error
      final whatsappError = await _errorHandler.handleError(
        e is Exception ? e : Exception(e.toString()),
        phoneNumber: client.phone,
        context: 'Message sending for ${client.firstName} ${client.lastName}',
      );
      
      // Get user-friendly error message
      final userMessage = _errorHandler.getUserFriendlyMessage(whatsappError);
      
      // Log with appropriate severity
      if (whatsappError.severity == WhatsAppErrorSeverity.critical) {
        logger.e('CRITICAL WhatsApp error for message $messageId: $userMessage');
      } else {
        logger.w('WhatsApp error for message $messageId: $userMessage');
      }
      
      // Re-throw with user-friendly message
      throw Exception(userMessage);
    }
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

    // Validate phone number format
    final phoneValidation = AlgerianPhoneValidator.validateAndFormat(client.phone);
    if (!phoneValidation.isValid) {
      final hint = AlgerianPhoneValidator.getFormattingHint(client.phone);
      throw Exception('${phoneValidation.errorMessage}. $hint');
    }
    
    final formattedPhoneNumber = phoneValidation.formattedNumber!;
    logger.i('Phone number validated and formatted: ${client.phone} -> $formattedPhoneNumber');

    // Validate WhatsApp settings
    _validateWhatsAppSettings(whatsappSettings);

    // Convert database template to TemplateModel for advanced rendering
    final templateModel = TemplateModel.fromDatabase(template);
    
    if (templateModel.hasBlocks) {
      // Split template content into text and media messages
      final messageContent = await _splitWhatsAppContent(templateModel, client, whatsappSettings);
      
      if (!messageContent.hasContent) {
        throw Exception('No content to send');
      }

      logger.i('Sending ${messageContent.textMessages.length} text messages and ${messageContent.mediaMessages.length} media messages to $formattedPhoneNumber');

      // Send text messages first with retry logic
      for (int i = 0; i < messageContent.textMessages.length; i++) {
        final textMessage = messageContent.textMessages[i];
        if (textMessage.trim().isNotEmpty) {
          await _sendWhatsAppTextMessageWithRetry(formattedPhoneNumber, textMessage, whatsappSettings, i + 1, messageContent.textMessages.length);
          // Progressive delay between messages to avoid rate limiting
          await Future.delayed(Duration(milliseconds: _calculateMessageDelay(i, messageContent.textMessages.length)));
        }
      }

      // Send media messages with retry logic
      for (int i = 0; i < messageContent.mediaMessages.length; i++) {
        final mediaMessage = messageContent.mediaMessages[i];
        await _sendWhatsAppMediaMessageWithRetry(formattedPhoneNumber, mediaMessage, whatsappSettings, i + 1, messageContent.mediaMessages.length);
        // Longer delay for media messages
        await Future.delayed(Duration(milliseconds: _calculateMediaDelay(i, messageContent.mediaMessages.length)));
      }
    } else {
      // Fallback to legacy text-only rendering
      final personalizedMessage = _personalizeMessage(template.body, client);
      await _sendWhatsAppTextMessageWithRetry(formattedPhoneNumber, personalizedMessage, whatsappSettings, 1, 1);
    }
    logger.i('WhatsApp message(s) sent successfully to $formattedPhoneNumber');
  }

  void _validateWhatsAppSettings(WhatsAppSettings settings) {
    if (settings.apiUrl.isEmpty) {
      throw Exception('WhatsApp API URL is not configured');
    }
    if (settings.apiKey.isEmpty) {
      throw Exception('WhatsApp API key is not configured');
    }
    if (settings.phoneNumberId.isEmpty) {
      throw Exception('WhatsApp phone number ID is not configured');
    }
  }

  Future<String?> _uploadMediaToWhatsApp(File file, WhatsAppSettings whatsappSettings) async {
    const maxRetries = 2;
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        logger.i('Uploading media to WhatsApp: ${file.path} (attempt $attempt/$maxRetries)');

        // Validate file exists and is readable
        if (!await file.exists()) {
          throw FileSystemException('File does not exist', file.path);
        }

        final fileStat = await file.stat();
        final fileSizeBytes = fileStat.size;
        final fileSizeMB = fileSizeBytes / (1024 * 1024);
        
        logger.i('File size: ${fileSizeMB.toStringAsFixed(2)} MB');

        // Determine media type and validate file size
        final extension = p.extension(file.path).toLowerCase();
        String mediaType;
        int maxSizeMB;
        
        switch (extension) {
          case '.jpg':
          case '.jpeg':
            mediaType = 'image/jpeg'; // force jpeg for both
            maxSizeMB = 5;
            break;
          case '.png':
            mediaType = 'image/png';
            maxSizeMB = 5;
            break;
          case '.webp':
            mediaType = 'image/webp';
            maxSizeMB = 5;
            break;
          case '.mp4':
          case '.3gp':
            mediaType = 'video/mp4'; // WhatsApp expects MIME type, not just "video"
            maxSizeMB = 16;
            break;
          case '.aac':
            mediaType = 'audio/aac';
            maxSizeMB = 16;
            break;
          case '.mp3':
            mediaType = 'audio/mpeg';
            maxSizeMB = 16;
            break;
          case '.amr':
            mediaType = 'audio/amr';
            maxSizeMB = 16;
            break;
          case '.ogg':
            mediaType = 'audio/ogg';
            maxSizeMB = 16;
            break;
          case '.pdf':
            mediaType = 'application/pdf';
            maxSizeMB = 100;
            break;
          case '.doc':
            mediaType = 'application/msword';
            maxSizeMB = 100;
            break;
          case '.docx':
            mediaType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
            maxSizeMB = 100;
            break;
          case '.txt':
            mediaType = 'text/plain';
            maxSizeMB = 100;
            break;
          case '.xls':
            mediaType = 'application/vnd.ms-excel';
            maxSizeMB = 100;
            break;
          case '.xlsx':
            mediaType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
            maxSizeMB = 100;
            break;
          case '.ppt':
            mediaType = 'application/vnd.ms-powerpoint';
            maxSizeMB = 100;
            break;
          case '.pptx':
            mediaType = 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
            maxSizeMB = 100;
            break;
          default:
            mediaType = 'application/octet-stream'; // safe fallback
            maxSizeMB = 100;
        }

        if (fileSizeMB > maxSizeMB) {
          throw Exception('File too large: ${fileSizeMB.toStringAsFixed(2)} MB (max $maxSizeMB MB for $mediaType)');
        }
        logger.i('medai type: $mediaType');
        // Create form data for upload
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            file.path,
            filename: p.basename(file.path),
            contentType: MediaType.parse(mediaType),
          ),
          'type': mediaType,
          'messaging_product': 'whatsapp',
        });

        // Upload to WhatsApp Media API with progress tracking
        final response = await _dio.post(
          '${whatsappSettings.apiUrl}/v23.0/${whatsappSettings.phoneNumberId}/media',
          options: Options(
            responseType: ResponseType.json,
            headers: {
              'Authorization': 'Bearer ${whatsappSettings.apiKey}',
              'Content-Type': 'multipart/form-data',
            },
            sendTimeout: const Duration(minutes: 5), // Longer timeout for large files
            receiveTimeout: const Duration(minutes: 5),
          ),
          data: formData,
          onSendProgress: (sent, total) {
            if (total > 0) {
              final progress = (sent / total * 100).toStringAsFixed(1);
              logger.d('Upload progress: $progress% ($sent/$total bytes)');
            }
          },
        );

        final rawData = response.data;
        final data = rawData is String ? jsonDecode(rawData) : rawData;

        logger.i('response status code: ${response.statusCode}, data: $data');

        if (response.statusCode == 200 && data['id'] != null) {
          
          final mediaId = data['id'] as String;
          logger.i('Media uploaded successfully. Media ID: $mediaId');
          return mediaId;
        } else {
          logger.e('Failed to upload media. Status: ${response.statusCode}, Response: $data');
          if (attempt == maxRetries) {
            throw Exception('Media upload failed after $maxRetries attempts');
          }
        }
      
      } on DioException catch (e) {
        logger.e('WhatsApp API response: ${e.response?.data}');
        logger.e('WhatsApp API error: ${e.message}');
      } catch (e) {
        final isLastAttempt = attempt == maxRetries;
        // Handle error through error handler
        final whatsappError = await _errorHandler.handleError(
          e is Exception ? e : Exception(e.toString()),
          mediaPath: file.path,
          context: 'Media upload attempt $attempt/$maxRetries',
        );
        
        if (isLastAttempt || !_errorHandler.shouldRetryError(whatsappError, attempt)) {
          throw Exception(_errorHandler.getUserFriendlyMessage(whatsappError));
        }
        
        // Use error handler's retry delay
        final delay = _errorHandler.getRetryDelay(whatsappError, attempt);
        logger.i('Retrying upload in ${delay.inMilliseconds}ms...');
        await Future.delayed(delay);
      }
    }
    
    return null;
  }
    
  Future<void> _sendWhatsAppTextMessageWithRetry(
    String phoneNumber,
    String message,
    WhatsAppSettings whatsappSettings,
    int messageIndex,
    int totalMessages,
  ) async {
    const maxRetries = 3;
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        logger.i('Sending WhatsApp text message $messageIndex/$totalMessages to $phoneNumber (attempt $attempt/$maxRetries)');
        
        // Validate message content
        if (message.trim().isEmpty) {
          throw Exception('Empty message content');
        }
        
        if (message.length > 4096) {
          throw Exception('Message too long (${message.length} characters, max 4096)');
        }

        await _dio.post(
          '${whatsappSettings.apiUrl}/v23.0/${whatsappSettings.phoneNumberId}/messages',
          options: Options(
            headers: {
              'Authorization': 'Bearer ${whatsappSettings.apiKey}',
              'Content-Type': 'application/json',
            },
          ),
          data: {
            'messaging_product': 'whatsapp',
            'to': phoneNumber,
            'type': 'text',
            'text': {
              "preview_url": true,
              'body': message,
            },
          },
        );
        logger.i('Text message $messageIndex/$totalMessages sent successfully');
        return; // Success, exit retry loop
        
      } catch (e) {
        final isLastAttempt = attempt == maxRetries;
        
        // Handle error through error handler
        final whatsappError = await _errorHandler.handleError(
          e is Exception ? e : Exception(e.toString()),
          phoneNumber: phoneNumber,
          context: 'Text message sending attempt $attempt/$maxRetries',
        );
        
        if (isLastAttempt || !_errorHandler.shouldRetryError(whatsappError, attempt)) {
          throw Exception(_errorHandler.getUserFriendlyMessage(whatsappError));
        }
        
        // Use error handler's retry delay
        final delay = _errorHandler.getRetryDelay(whatsappError, attempt);
        logger.i('Retrying in ${delay.inMilliseconds}ms...');
        await Future.delayed(delay);
      }
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

  Future<void> _sendWhatsAppMediaMessageWithRetry(
    String phoneNumber,
    WhatsAppMediaMessage mediaMessage,
    WhatsAppSettings whatsappSettings,
    int messageIndex,
    int totalMessages,
  ) async {
    const maxRetries = 3;
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        logger.i('Sending WhatsApp media message $messageIndex/$totalMessages to $phoneNumber (attempt $attempt/$maxRetries)');
        
        Map<String, dynamic> mediaData;
        
        // Check if it's a URL or media ID
        if (mediaMessage.mediaId.startsWith('http://') || mediaMessage.mediaId.startsWith('https://')) {
          // Validate URL format
          if (!_isValidUrl(mediaMessage.mediaId)) {
            throw Exception('Invalid media URL: ${mediaMessage.mediaId}');
          }
          mediaData = {'link': mediaMessage.mediaId};
        } else {
          // Validate media ID format
          if (mediaMessage.mediaId.isEmpty) {
            throw Exception('Empty media ID');
          }
          mediaData = {'id': mediaMessage.mediaId};
        }

        // Add caption if provided (with length validation)
        if (mediaMessage.caption != null && mediaMessage.caption!.isNotEmpty) {
          if (mediaMessage.caption!.length > 1024) {
            logger.w('Caption too long (${mediaMessage.caption!.length} chars), truncating to 1024');
            mediaData['caption'] = mediaMessage.caption!.substring(0, 1024);
          } else {
            mediaData['caption'] = mediaMessage.caption;
          }
        }

        await _dio.post(
          '${whatsappSettings.apiUrl}/v23.0/${whatsappSettings.phoneNumberId}/messages',
          options: Options(
            headers: {
              'Authorization': 'Bearer ${whatsappSettings.apiKey}',
              'Content-Type': 'application/json',
            },
            sendTimeout: const Duration(seconds: 60), // Longer timeout for media
            receiveTimeout: const Duration(seconds: 60),
          ),
          data: {
            'messaging_product': 'whatsapp',
            'to': phoneNumber,
            'type': mediaMessage.mediaType,
            mediaMessage.mediaType: mediaData,
          },
        );
        
        logger.i('Media message $messageIndex/$totalMessages sent successfully');
        return; // Success, exit retry loop
        
      } catch (e) {
        final isLastAttempt = attempt == maxRetries;
        
        // Handle error through error handler
        final whatsappError = await _errorHandler.handleError(
          e is Exception ? e : Exception(e.toString()),
          phoneNumber: phoneNumber,
          mediaPath: mediaMessage.originalPath,
          context: 'Media message sending attempt $attempt/$maxRetries',
        );
        
        if (isLastAttempt || !_errorHandler.shouldRetryError(whatsappError, attempt)) {
          throw Exception(_errorHandler.getUserFriendlyMessage(whatsappError));
        }
        
        // Use error handler's retry delay
        final delay = _errorHandler.getRetryDelay(whatsappError, attempt);
        logger.i('Retrying in ${delay.inMilliseconds}ms...');
        await Future.delayed(delay);
      }
    }
  }

  int _calculateMessageDelay(int messageIndex, int totalMessages) {
    // Base delay of 300ms, with additional delay for multiple messages
    int baseDelay = 300;
    
    if (totalMessages > 5) {
      // Add extra delay for bulk messages to avoid rate limiting
      baseDelay += (messageIndex * 100);
    }
    
    return baseDelay.clamp(300, 2000); // Min 300ms, max 2s
  }

  int _calculateMediaDelay(int messageIndex, int totalMessages) {
    // Longer delay for media messages
    int baseDelay = 500;
    
    if (totalMessages > 3) {
      baseDelay += (messageIndex * 200);
    }
    
    return baseDelay.clamp(500, 3000); // Min 500ms, max 3s
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
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
      phoneNumberId: await _storage.read(key: 'whatsapp_phone_number_id') ?? '',
    );
  }

  Future<WhatsAppMessageContent> _splitWhatsAppContent(
    TemplateModel templateModel,
    Client client,
    WhatsAppSettings whatsappSettings,
  ) async {
    final textMessages = <String>[];
    final mediaMessages = <WhatsAppMediaMessage>[];
    
    final allTextBlocks = <String>[];
    final imageBlocks = <ImageBlock>[];
    
    // First pass: separate text and image blocks
    for (final block in templateModel.blocks) {
      if (block.type == TemplateBlockType.text) {
        final textBlock = block as TextBlock;
        final personalizedText = _personalizeMessage(textBlock.text, client);
        if (personalizedText.trim().isNotEmpty) {
          allTextBlocks.add(personalizedText.trim());
        }
      } else if (block.type == TemplateBlockType.image) {
        imageBlocks.add(block as ImageBlock);
      }
    }
    
    logger.i('WhatsApp template has ${imageBlocks.length} images and ${allTextBlocks.length} text blocks');
    
    final combinedCaption = allTextBlocks.isNotEmpty ? allTextBlocks.join('\n\n') : null;
    
    if (imageBlocks.isEmpty && combinedCaption != null) {
      // No images, just send the combined text as a regular text message
      textMessages.add(combinedCaption);
      return WhatsAppMessageContent(
        textMessages: textMessages,
        mediaMessages: mediaMessages,
      );
    }
    
    // Process images and attach caption to the last one
    for (int i = 0; i < imageBlocks.length; i++) {
      final imageBlock = imageBlocks[i];
      final isLastImage = i == imageBlocks.length - 1;
      
      try {
        String mediaId;
        String mediaType = 'image';
        
        if (imageBlock.imageUrl.startsWith('http://') || 
            imageBlock.imageUrl.startsWith('https://')) {
          // Remote URL - use directly
          mediaId = imageBlock.imageUrl;
          logger.i('Using remote image URL: $mediaId');
        } else {
          // Local file - check cache first, then upload
          final file = File(imageBlock.imageUrl);
          if (!await file.exists()) {
            logger.w('Image file not found: ${imageBlock.imageUrl}');
            continue;
          }
          
          // Check cache first
          final cachedEntry = await _mediaCacheManager.getCachedMedia(file.path);
          if (cachedEntry != null) {
            mediaId = cachedEntry.mediaId;
            logger.i('Using cached media ID for ${imageBlock.imageUrl}');
          } else {
            // Upload and cache
            final uploadedMediaId = await _uploadMediaToWhatsApp(file, whatsappSettings);
            if (uploadedMediaId == null) {
              logger.e('Failed to upload image: ${imageBlock.imageUrl}');
              continue;
            }
            mediaId = uploadedMediaId;
            await _mediaCacheManager.cacheMedia(file.path, mediaId);
            logger.i('Uploaded and cached media ID for ${imageBlock.imageUrl}');
          }
        }
        
        mediaMessages.add(WhatsAppMediaMessage(
          mediaId: mediaId,
          mediaType: mediaType,
          caption: isLastImage ? combinedCaption : null,
          originalPath: imageBlock.imageUrl,
        ));
        
      } catch (e) {
        logger.e('Error processing image ${imageBlock.imageUrl}: $e');
        // Continue with other blocks even if one image fails
      }
    }
    
    logger.i('WhatsApp messages: ${textMessages.length} text, ${mediaMessages.length} media');
    logger.i('Combined caption: $combinedCaption');
    return WhatsAppMessageContent(
      textMessages: textMessages,
      mediaMessages: mediaMessages,
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
  final String phoneNumberId;

  WhatsAppSettings({
    required this.apiUrl,
    required this.apiKey,
    required this.phoneNumberId,
  });
}