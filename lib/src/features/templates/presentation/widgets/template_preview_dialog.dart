import 'dart:io';
import 'package:client_connect/constants.dart';
import 'package:client_connect/src/features/templates/data/template_block_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Scrollbar;
import 'package:flutter/material.dart' show Material, InkWell, Scrollbar;
import 'package:flutter/services.dart';

class TemplatePreviewDialog extends StatefulWidget {
  final String templateName;
  final String templateSubject;
  final TemplateType templateType;
  final List<TemplateBlock> blocks;

  const TemplatePreviewDialog({
    super.key,
    required this.templateName,
    required this.templateSubject,
    required this.templateType,
    required this.blocks,
  });

  @override
  State<TemplatePreviewDialog> createState() => _TemplatePreviewDialogState();
}

class _TemplatePreviewDialogState extends State<TemplatePreviewDialog> {
  String _selectedDevice = 'desktop';
  bool _showMetadata = true;
  double _previewScale = 1.0;
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  
  // Realistic fake client data for preview
  final Map<String, String> _fakeClientData = {
    'first_name': 'Sarah',
    'last_name': 'Johnson',
    'full_name': 'Sarah Johnson',
    'email': 'sarah.johnson@email.com',
    'phone': '+1 (555) 123-4567',
    'company': 'TechCorp Solutions',
    'position': 'Marketing Director',
    'website': 'https://techcorp-solutions.com',
    'address': '123 Business Ave, Suite 100',
    'city': 'San Francisco',
    'state': 'CA',
    'zip': '94105',
    'country': 'United States',
    'appointment_date': 'March 15, 2024',
    'appointment_time': '2:00 PM',
    'service': 'Digital Marketing Consultation',
    'price': '\$299.00',
    'discount': '15%',
    'total': '\$254.15',
    'invoice_number': 'INV-2024-001',
    'due_date': 'March 30, 2024',
    'project_name': 'Website Redesign Project',
    'deadline': 'April 15, 2024',
    'meeting_link': 'https://meet.techcorp.com/sarah-consultation',
    'support_email': 'support@techcorp-solutions.com',
    'unsubscribe_link': 'https://techcorp-solutions.com/unsubscribe',
  };

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return ContentDialog(
      constraints: BoxConstraints(
        maxWidth: widget.templateType == TemplateType.whatsapp ? 800 : 900,
        maxHeight: 800,
      ),
      title: _buildDialogTitle(theme),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPreviewControls(theme),
          const SizedBox(height: 16),
          Expanded(
            child: _buildPreviewContainer(theme),
          ),
        ],
      ),
      actions: _buildDialogActions(context),
    );
  }

  Widget _buildDialogTitle(FluentThemeData theme) {
    return Row(
      children: [
        Icon(
          widget.templateType == TemplateType.email 
              ? FluentIcons.mail 
              : FluentIcons.chat,
          size: 20,
          color: theme.accentColor,
        ),
        const SizedBox(width: 8),
        Text('${widget.templateType == TemplateType.email ? 'Email' : 'WhatsApp'} Preview'),
        const Spacer(),
        if (widget.templateType == TemplateType.email)
          _buildEmailPreviewModeSelector(theme),
        if (widget.templateType == TemplateType.whatsapp)
          _buildWhatsAppPreviewModeSelector(theme),
      ],
    );
  }

  Widget _buildEmailPreviewModeSelector(FluentThemeData theme) {
    return ComboBox<String>(
      value: _selectedDevice,
      items: const [
        ComboBoxItem(value: 'desktop', child: Text('Desktop Client')),
        ComboBoxItem(value: 'mobile', child: Text('Mobile Client')),
        ComboBoxItem(value: 'webmail', child: Text('Webmail')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedDevice = value;
          });
        }
      },
    );
  }

  Widget _buildWhatsAppPreviewModeSelector(FluentThemeData theme) {
    return ComboBox<String>(
      value: _selectedDevice,
      items: const [
        ComboBoxItem(value: 'android', child: Text('Android')),
        ComboBoxItem(value: 'ios', child: Text('iOS')),
        ComboBoxItem(value: 'web', child: Text('WhatsApp Web')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedDevice = value;
          });
        }
      },
    );
  }

  Widget _buildPreviewControls(FluentThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.accentColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Template metadata toggle
          Checkbox(
            checked: _showMetadata,
            onChanged: (value) {
              setState(() {
                _showMetadata = value ?? true;
              });
            },
            content: const Text('Show metadata'),
          ),
          const SizedBox(width: 16),
          
          // Scale controls with zoom buttons
          const Text('Zoom:'),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(FluentIcons.circle_plus, size: 16),
            onPressed: _previewScale > 0.5 ? () {
              setState(() {
                _previewScale = (_previewScale - 0.25).clamp(0.5, 2.0);
              });
            } : null,
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 120,
            child: Slider(
              value: _previewScale,
              min: 0.5,
              max: 2.0,
              divisions: 6,
              onChanged: (value) {
                setState(() {
                  _previewScale = value;
                });
              },
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(FluentIcons.skype_circle_minus, size: 16),
            onPressed: _previewScale < 2.0 ? () {
              setState(() {
                _previewScale = (_previewScale + 0.25).clamp(0.5, 2.0);
              });
            } : null,
          ),
          const SizedBox(width: 8),
          Text('${(_previewScale * 100).round()}%'),
          
          const Spacer(),
          
          // Platform-specific controls
          if (widget.templateType == TemplateType.email)
            _buildEmailSpecificControls(theme),
          if (widget.templateType == TemplateType.whatsapp)
            _buildWhatsAppSpecificControls(theme),
        ],
      ),
    );
  }

  Widget _buildEmailSpecificControls(FluentThemeData theme) {
    return Row(
      children: [
        Button(
          child: const Text('Test Send'),
          onPressed: () => _showTestSendDialog(),
        ),
        const SizedBox(width: 8),
        Button(
          child: const Text('Spam Check'),
          onPressed: () => _performSpamCheck(),
        ),
      ],
    );
  }

  Widget _buildWhatsAppSpecificControls(FluentThemeData theme) {
    return Row(
      children: [
        Button(
          child: const Text('Character Count'),
          onPressed: () => _showCharacterCount(),
        ),
        const SizedBox(width: 8),
        Button(
          child: const Text('Media Check'),
          onPressed: () => _validateMediaContent(),
        ),
      ],
    );
  }

  Widget _buildPreviewContainer(FluentThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: widget.templateType == TemplateType.whatsapp 
            ? const Color(0xFF0B141A) // WhatsApp dark background
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.accentColor),
      ),
      child: widget.blocks.isEmpty
          ? _buildEmptyPreview(theme)
          : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildScaledPreview(),
            ),
    );
  }

  Widget _buildScaledPreview() {
    // Calculate the container size based on scale
    final baseWidth = widget.templateType == TemplateType.email 
        ? _getEmailPreviewWidth() 
        : _getWhatsAppPreviewWidth();
    final baseHeight = widget.templateType == TemplateType.whatsapp ? 600.0 : 500.0;
    
    // Calculate scaled dimensions
    final scaledWidth = baseWidth * _previewScale;
    final scaledHeight = baseHeight * _previewScale;
    
    // Get available container size (approximate)
    final availableWidth = widget.templateType == TemplateType.whatsapp ? 650.0 : 850.0;
    final availableHeight = 500.0; // Approximate available height
    
    // Determine if scrollbars are needed
    final needsHorizontalScroll = scaledWidth > availableWidth;
    final needsVerticalScroll = scaledHeight > availableHeight;

    return Scrollbar(
      controller: _horizontalScrollController,
      thumbVisibility: needsHorizontalScroll,
      trackVisibility: needsHorizontalScroll,
      child: Scrollbar(
        controller: _verticalScrollController,
        thumbVisibility: needsVerticalScroll,
        trackVisibility: needsVerticalScroll,
        child: SingleChildScrollView(
          controller: _horizontalScrollController,
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            controller: _verticalScrollController,
            scrollDirection: Axis.vertical,
            child: SizedBox(
              width: scaledWidth,
              height: scaledHeight,
              child: Transform.scale(
                scale: _previewScale,
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: baseWidth,
                  height: baseHeight,
                  child: widget.templateType == TemplateType.email
                      ? _buildEmailPreview()
                      : _buildWhatsAppPreview(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailPreview() {
    return SizedBox(
      width: _getEmailPreviewWidth(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_showMetadata) _buildEmailHeader(),
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: widget.blocks.map((block) => _buildEmailBlock(block)).toList(),
                ),
              ),
            ),
          ),
          if (_showMetadata) _buildEmailFooter(),
        ],
      ),
    );
  }

  Widget _buildWhatsAppPreview() {
    return SizedBox(
      width: _getWhatsAppPreviewWidth(),
      height: 600,
      child: Column(
        children: [
          if (_showMetadata) _buildWhatsAppHeader(),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFE5DDD5), // WhatsApp chat background
              ),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildWhatsAppMessageBubble(),
                ],
              ),
            ),
          ),
          _buildWhatsAppInputArea(),
        ],
      ),
    );
  }

  Widget _buildWhatsAppMessageBubble() {
    return Container(
      margin: const EdgeInsets.only(left: 50, bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFDCF8C6), // WhatsApp green
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...widget.blocks.map((block) => _buildWhatsAppBlock(block)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF667781),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  FluentIcons.check_mark,
                  size: 12,
                  color: Color(0xFF4FC3F7),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('From: ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF333333))),
              Text(_fakeClientData['support_email']!, style: const TextStyle(color: Color(0xFF333333))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text('To: ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF333333))),
              Text(_fakeClientData['email']!, style: const TextStyle(color: Color(0xFF333333))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text('Subject: ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF333333))),
              Expanded(child: Text(_renderTextWithData(widget.templateSubject), style: const TextStyle(color: Color(0xFF333333)))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsAppHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF075E54), // WhatsApp header color
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey,
            child: Icon(FluentIcons.contact, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fakeClientData['full_name']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'last seen today at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(FluentIcons.video, color: Colors.white),
          const SizedBox(width: 16),
          const Icon(FluentIcons.phone, color: Colors.white),
          const SizedBox(width: 16),
          const Icon(FluentIcons.more, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildEmailFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Text(
        'This email was sent by ${_fakeClientData['company']} using Template Builder',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildWhatsAppInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: Color(0xFFF0F0F0),
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Row(
        children: [
          const Icon(FluentIcons.emoji2, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Type a message',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(FluentIcons.attach, color: Colors.grey),
          const SizedBox(width: 8),
          const Icon(FluentIcons.microphone, color: Colors.grey),
        ],
      ),
    );
  }

  double _getEmailPreviewWidth() {
    switch (_selectedDevice) {
      case 'mobile':
        return 375;
      case 'webmail':
        return 800;
      default:
        return 600;
    }
  }

  double _getWhatsAppPreviewWidth() {
    switch (_selectedDevice) {
      case 'ios':
        return 375;
      case 'web':
        return 400;
      default:
        return 360;
    }
  }

  Widget _buildEmailBlock(TemplateBlock block) {
    // Enhanced email-specific block rendering with fake data
    switch (block.type) {
      case TemplateBlockType.text:
        return _buildEmailTextBlock(block as TextBlock);
      case TemplateBlockType.button:
        return _buildEmailButtonBlock(block as ButtonBlock);
      case TemplateBlockType.image:
        return _buildEmailImageBlock(block as ImageBlock);
      case TemplateBlockType.list:
        return _buildEmailListBlock(block as ListBlock);
      case TemplateBlockType.spacer:
        return _buildEmailSpacerBlock(block as SpacerBlock);
      case TemplateBlockType.divider:
        return _buildEmailDividerBlock(block as DividerBlock);
      case TemplateBlockType.richText:
        return _buildEmailRichTextBlock(block as RichTextBlock);
      case TemplateBlockType.qrCode:
        return _buildEmailQRBlock(block as QRCodeBlock);
      default:
        return _buildGenericEmailBlock(block);
    }
  }

  Widget _buildWhatsAppBlock(TemplateBlock block) {
    // Enhanced WhatsApp-specific block rendering with fake data
    switch (block.type) {
      case TemplateBlockType.text:
        return _buildWhatsAppTextBlock(block as TextBlock);
      case TemplateBlockType.image:
        return _buildWhatsAppImageBlock(block as ImageBlock);
      case TemplateBlockType.qrCode:
        return _buildWhatsAppQRBlock(block as QRCodeBlock);
      case TemplateBlockType.list:
        return _buildWhatsAppListBlock(block as ListBlock);
      case TemplateBlockType.spacer:
        return _buildWhatsAppSpacerBlock(block as SpacerBlock);
      case TemplateBlockType.divider:
        return _buildWhatsAppDividerBlock(block as DividerBlock);
      case TemplateBlockType.button:
        return _buildWhatsAppButtonBlock(block as ButtonBlock);
      case TemplateBlockType.richText:
        return _buildWhatsAppRichTextBlock(block as RichTextBlock);
      default:
        return _buildGenericWhatsAppBlock(block);
    }
  }

  Widget _buildEmailTextBlock(TextBlock block) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        _renderTextWithData(block.text),
        style: TextStyle(
          fontSize: block.fontSize,
          fontWeight: block.fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal,
          color: _parseColor(block.color),
          fontStyle: block.italic ? FontStyle.italic : FontStyle.normal,
          decoration: block.underline ? TextDecoration.underline : TextDecoration.none,
          height: block.lineHeight,
          letterSpacing: block.letterSpacing,
        ),
        textAlign: _parseAlignment(block.alignment),
      ),
    );
  }

  Widget _buildWhatsAppTextBlock(TextBlock block) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        _renderTextWithData(block.text),
        style: TextStyle(
          fontSize: block.fontSize.clamp(12.0, 18.0), // WhatsApp font size limits
          fontWeight: block.fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal,
          color: Colors.black.withValues(alpha: 0.87),
        ),
      ),
    );
  }

  Widget _buildEmailButtonBlock(ButtonBlock block) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: _parseButtonAlignment(block.alignment),
      child: Container(
        decoration: BoxDecoration(
          color: _parseColor(block.backgroundColor),
          borderRadius: BorderRadius.circular(block.borderRadius),
          border: block.borderWidth > 0
              ? Border.all(
                  color: _parseColor(block.borderColor),
                  width: block.borderWidth,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(block.borderRadius),
            onTap: () {}, // Preview only
            child: Container(
              padding: _getButtonPadding(block.size),
              child: Text(
                _renderTextWithData(block.text),
                style: TextStyle(
                  color: _parseColor(block.textColor),
                  fontSize: _getButtonFontSize(block.size),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWhatsAppButtonBlock(ButtonBlock block) {
    // WhatsApp doesn't support buttons in the same way as email
    // Convert button to text with action URL
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '🔗 ${_renderTextWithData(block.text)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1976D2), // Link blue
              ),
            ),
            if (block.action.isNotEmpty) ...[
              const TextSpan(text: '\n'),
              TextSpan(
                text: _renderTextWithData(block.action),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmailListBlock(ListBlock block) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: block.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          
          return Container(
            margin: EdgeInsets.only(bottom: block.spacing),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    block.listType == 'numbered' 
                        ? '${index + 1}.' 
                        : block.bulletStyle,
                    style: TextStyle(
                      fontSize: block.fontSize,
                      color: _parseColor(block.color),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _renderTextWithData(item),
                    style: TextStyle(
                      fontSize: block.fontSize,
                      color: _parseColor(block.color),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWhatsAppListBlock(ListBlock block) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: block.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.listType == 'numbered' 
                      ? '${index + 1}. ' 
                      : '${block.bulletStyle} ',
                  style: TextStyle(
                    fontSize: block.fontSize.clamp(12.0, 18.0),
                    color: Colors.black.withValues(alpha: 0.87),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: Text(
                    _renderTextWithData(item),
                    style: TextStyle(
                      fontSize: block.fontSize.clamp(12.0, 18.0),
                      color: Colors.black.withValues(alpha: 0.87),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmailSpacerBlock(SpacerBlock block) {
    return SizedBox(height: block.height);
  }

  Widget _buildWhatsAppSpacerBlock(SpacerBlock block) {
    // WhatsApp spacers are more subtle - use smaller heights
    return SizedBox(height: (block.height / 2).clamp(4.0, 20.0));
  }

  Widget _buildEmailDividerBlock(DividerBlock block) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        width: double.infinity,
        height: block.thickness,
        decoration: BoxDecoration(
          color: _parseColor(block.color),
          borderRadius: BorderRadius.circular(block.thickness / 2),
        ),
      ),
    );
  }

  Widget _buildWhatsAppDividerBlock(DividerBlock block) {
    // WhatsApp dividers are represented as text separators
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: Colors.black.withValues(alpha: 0.2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '• • •',
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.black.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailRichTextBlock(RichTextBlock block) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        _renderTextWithData(block.htmlContent.replaceAll(RegExp(r'<[^>]*>'), '')), // Strip HTML for preview
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildWhatsAppRichTextBlock(RichTextBlock block) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        _renderTextWithData(block.htmlContent.replaceAll(RegExp(r'<[^>]*>'), '')), // Strip HTML for WhatsApp
        style: TextStyle(
          fontSize: 14,
          color: Colors.black.withValues(alpha: 0.87),
        ),
      ),
    );
  }

  Widget _buildEmailQRBlock(QRCodeBlock block) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: block.size,
            height: block.size,
            decoration: BoxDecoration(
              color: _parseColor(block.backgroundColor),
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'QR',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (block.data.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _renderTextWithData(block.data),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmailImageBlock(ImageBlock block) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: _parseImageAlignment(block.alignment),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(block.borderRadius),
        child: Container(
          decoration: block.borderWidth > 0
              ? BoxDecoration(
                  border: Border.all(
                    color: _parseColor(block.borderColor),
                    width: block.borderWidth,
                  ),
                  borderRadius: BorderRadius.circular(block.borderRadius),
                )
              : null,
          child: _buildImageWidget(block),
        ),
      ),
    );
  }

  Widget _buildWhatsAppImageBlock(ImageBlock block) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildImageWidget(block, maxWidth: double.infinity, maxHeight: 200),
      ),
    );
  }

  Widget _buildImageWidget(ImageBlock block, {double? maxWidth, double? maxHeight}) {
    final width = maxWidth ?? (block.isResponsive ? null : block.width);
    final height = maxHeight ?? block.height;

    // Handle local file paths (uploaded images)
    if (block.imageUrl.isNotEmpty && !block.imageUrl.startsWith('http')) {
      final file = File(block.imageUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: width,
          height: height,
          fit: _parseBoxFit(block.fit),
          errorBuilder: (context, error, stackTrace) => _buildImageErrorWidget(width, height),
        );
      }
    }
    
    // Handle network URLs
    if (block.imageUrl.startsWith('http://') || block.imageUrl.startsWith('https://')) {
      return Image.network(
        block.imageUrl,
        width: width,
        height: height,
        fit: _parseBoxFit(block.fit),
        errorBuilder: (context, error, stackTrace) => _buildImageErrorWidget(width, height),
      );
    }

    // Fallback for empty or invalid URLs
    return _buildImagePlaceholder(width, height);
  }

  Widget _buildImageErrorWidget(double? width, double? height) {
    return Container(
      width: width ?? 200,
      height: height ?? 150,
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FluentIcons.error, color: Colors.red, size: 32),
            SizedBox(height: 8),
            Text('Failed to load image', style: TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(double? width, double? height) {
    return Container(
      width: width ?? 200,
      height: height ?? 150,
      color: Colors.grey[200],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FluentIcons.file_image, size: 32, color: Colors.grey),
            SizedBox(height: 8),
            Text('No image', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsAppQRBlock(QRCodeBlock block) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            width: block.size.clamp(100.0, 200.0),
            height: block.size.clamp(100.0, 200.0),
            decoration: BoxDecoration(
              color: _parseColor(block.backgroundColor),
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Center(
              child: Text(
                'QR',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (block.data.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _renderTextWithData(block.data),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGenericEmailBlock(TemplateBlock block) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text('Email Block: ${block.type.name}'),
    );
  }

  Widget _buildGenericWhatsAppBlock(TemplateBlock block) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text('WhatsApp Block: ${block.type.name}'),
    );
  }

  Widget _buildEmptyPreview(FluentThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.preview,
            size: 48,
            color: theme.inactiveColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No content to preview',
            style: theme.typography.subtitle?.copyWith(
              color: theme.inactiveColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some blocks to see the preview',
            style: theme.typography.body?.copyWith(
              color: theme.inactiveColor,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDialogActions(BuildContext context) {
    return [
      Button(
        child: const Text('Close'),
        onPressed: () => Navigator.of(context).pop(),
      ),
      if (widget.templateType == TemplateType.email)
        FilledButton(
          child: const Text('Export HTML'),
          onPressed: () => _exportHtml(context),
        ),
      if (widget.templateType == TemplateType.whatsapp)
        FilledButton(
          child: const Text('Copy Text'),
          onPressed: () => _copyWhatsAppText(context),
        ),
    ];
  }

  // Platform-specific helper methods
  void _showTestSendDialog() {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Test Email Send'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextBox(
              placeholder: 'Test email address',
              controller: TextEditingController(text: _fakeClientData['email']),
            ),
            const SizedBox(height: 16),
            const Text('This will send a test email to the specified address.'),
          ],
        ),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            child: const Text('Send Test'),
            onPressed: () {
              Navigator.of(context).pop();
              displayInfoBar(
                context,
                builder: (context, close) => InfoBar(
                  title: const Text('Test Email Sent'),
                  content: Text('Test email sent to ${_fakeClientData['email']}'),
                  severity: InfoBarSeverity.success,
                  onClose: close,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Enhanced spam detection system
  void _performSpamCheck() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ContentDialog(
        title: const Text('Analyzing Content'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ProgressRing(),
            const SizedBox(height: 16),
            const Text('Performing comprehensive spam analysis...'),
          ],
        ),
      ),
    );

    // Simulate analysis delay for realistic UX
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    Navigator.of(context).pop(); // Close loading dialog

    // Perform comprehensive spam analysis
    final spamAnalysis = await _analyzeSpamContent();
    
    // Show detailed results
    _showSpamAnalysisResults(spamAnalysis);
  }

  Future<SpamAnalysisResult> _analyzeSpamContent() async {
    final analysis = SpamAnalysisResult();
    
    // Analyze subject line
    analysis.subjectAnalysis = _analyzeSubjectLine(widget.templateSubject);
    
    // Analyze content blocks
    analysis.contentAnalysis = _analyzeContentBlocks(widget.blocks);
    
    // Analyze HTML structure (for email templates)
    if (widget.templateType == TemplateType.email) {
      analysis.htmlAnalysis = _analyzeHtmlStructure();
    }
    
    // Analyze links and URLs
    analysis.linkAnalysis = _analyzeLinkContent();
    
    // Analyze image-to-text ratio
    analysis.imageAnalysis = _analyzeImageContent();
    
    // Calculate overall spam score
    analysis.calculateOverallScore();
    
    return analysis;
  }

  SubjectAnalysis _analyzeSubjectLine(String subject) {
    final analysis = SubjectAnalysis();
    final subjectWithData = _renderTextWithData(subject).toLowerCase();
    
    // Check for spam trigger words
    final spamWords = [
      'free', 'urgent', 'act now', 'limited time', 'click here', 'buy now',
      'guaranteed', 'no risk', 'winner', 'congratulations', 'cash', 'money',
      'earn', 'income', 'investment', 'loan', 'credit', 'debt', 'refinance',
      'viagra', 'pharmacy', 'pills', 'weight loss', 'diet', 'casino',
      'gambling', 'lottery', 'prize', 'gift', 'offer expires', 'act fast',
      'don\'t delete', 'important information', 'requires immediate',
      'time sensitive', 'final notice', 'last chance', 'expires today'
    ];
    
    for (final word in spamWords) {
      if (subjectWithData.contains(word)) {
        analysis.spamWords.add(word);
        analysis.score += 15; // High penalty for spam words
      }
    }
    
    // Check for excessive capitalization
    final upperCaseCount = subject.replaceAll(RegExp(r'[^A-Z]'), '').length;
    final totalLetters = subject.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
    if (totalLetters > 0) {
      final capsRatio = upperCaseCount / totalLetters;
      if (capsRatio > 0.5) {
        analysis.issues.add('Excessive capitalization (${(capsRatio * 100).round()}%)');
        analysis.score += (capsRatio * 30).round();
      }
    }
    
    // Check for excessive punctuation
    final punctuationCount = subject.replaceAll(RegExp(r'[^!?.]'), '').length;
    if (punctuationCount > 3) {
      analysis.issues.add('Excessive punctuation ($punctuationCount marks)');
      analysis.score += punctuationCount * 5;
    }
    
    // Check for numbers and special characters
    if (RegExp(r'\$\d+').hasMatch(subjectWithData)) {
      analysis.issues.add('Contains monetary amounts');
      analysis.score += 10;
    }
    
    // Check subject length
    if (subject.length > 50) {
      analysis.issues.add('Subject line too long (${subject.length} characters)');
      analysis.score += 5;
    } else if (subject.length < 10) {
      analysis.issues.add('Subject line too short (${subject.length} characters)');
      analysis.score += 5;
    }
    
    // Check for empty subject
    if (subject.trim().isEmpty) {
      analysis.issues.add('Empty subject line');
      analysis.score += 25;
    }
    
    return analysis;
  }

  ContentAnalysis _analyzeContentBlocks(List<TemplateBlock> blocks) {
    final analysis = ContentAnalysis();
    
    int totalTextLength = 0;
    int imageCount = 0;
    int linkCount = 0;
    int buttonCount = 0;
    
    final allText = StringBuffer();
    
    for (final block in blocks) {
      switch (block.type) {
        case TemplateBlockType.text:
          final textBlock = block as TextBlock;
          final renderedText = _renderTextWithData(textBlock.text);
          allText.writeln(renderedText);
          totalTextLength += renderedText.length;
          break;
          
        case TemplateBlockType.richText:
          final richTextBlock = block as RichTextBlock;
          final plainText = richTextBlock.htmlContent.replaceAll(RegExp(r'<[^>]*>'), '');
          final renderedText = _renderTextWithData(plainText);
          allText.writeln(renderedText);
          totalTextLength += renderedText.length;
          break;
          
        case TemplateBlockType.button:
          final buttonBlock = block as ButtonBlock;
          buttonCount++;
          if (buttonBlock.action.isNotEmpty) {
            linkCount++;
            analysis.links.add(buttonBlock.action);
          }
          break;
          
        case TemplateBlockType.image:
          imageCount++;
          break;
          
        case TemplateBlockType.list:
          final listBlock = block as ListBlock;
          for (final item in listBlock.items) {
            final renderedText = _renderTextWithData(item);
            allText.writeln(renderedText);
            totalTextLength += renderedText.length;
          }
          break;
        default:
          logger.i('block type not supported: ${block.type}');
          break;
      }
    }
    
    final contentText = allText.toString().toLowerCase();
    
    // Analyze content for spam indicators
    final spamPhrases = [
      'click here', 'act now', 'limited time offer', 'buy now', 'order now',
      'call now', 'don\'t wait', 'hurry up', 'last chance', 'final notice',
      'urgent response required', 'immediate action required', 'expires soon',
      'while supplies last', 'limited quantity', 'exclusive offer',
      'special promotion', 'once in a lifetime', 'guaranteed results',
      'no questions asked', 'risk free', '100% free', 'absolutely free',
      'no cost', 'no fees', 'no obligation', 'no strings attached',
      'make money fast', 'earn extra income', 'work from home',
      'financial freedom', 'get rich quick', 'easy money'
    ];
    
    for (final phrase in spamPhrases) {
      if (contentText.contains(phrase)) {
        analysis.spamPhrases.add(phrase);
        analysis.score += 10;
      }
    }
    
    // Check for excessive capitalization in content
    final upperCaseCount = allText.toString().replaceAll(RegExp(r'[^A-Z]'), '').length;
    if (totalTextLength > 0) {
      final capsRatio = upperCaseCount / totalTextLength;
      if (capsRatio > 0.3) {
        analysis.issues.add('Excessive capitalization in content (${(capsRatio * 100).round()}%)');
        analysis.score += (capsRatio * 20).round();
      }
    }
    
    // Check for excessive exclamation marks
    final exclamationCount = allText.toString().split('!').length - 1;
    if (exclamationCount > 5) {
      analysis.issues.add('Excessive exclamation marks ($exclamationCount)');
      analysis.score += exclamationCount * 2;
    }
    
    // Check content length
    if (totalTextLength < 50) {
      analysis.issues.add('Content too short ($totalTextLength characters)');
      analysis.score += 15;
    } else if (totalTextLength > 5000) {
      analysis.issues.add('Content too long ($totalTextLength characters)');
      analysis.score += 10;
    }
    
    // Check button-to-content ratio
    if (buttonCount > 0 && totalTextLength > 0) {
      final buttonRatio = buttonCount / (totalTextLength / 100);
      if (buttonRatio > 2) {
        analysis.issues.add('Too many buttons relative to content');
        analysis.score += 15;
      }
    }
    
    analysis.textLength = totalTextLength;
    analysis.imageCount = imageCount;
    analysis.linkCount = linkCount;
    analysis.buttonCount = buttonCount;
    
    return analysis;
  }

  HtmlAnalysis _analyzeHtmlStructure() {
    final analysis = HtmlAnalysis();
    final htmlContent = _generateHtmlContent();
    
    // Check for inline styles vs CSS
    final inlineStyleCount = RegExp(r'style\s*=').allMatches(htmlContent).length;
    if (inlineStyleCount > 10) {
      analysis.issues.add('Excessive inline styles ($inlineStyleCount)');
      analysis.score += 5;
    }
    
    // Check for proper HTML structure
    if (!htmlContent.contains('<!DOCTYPE html>')) {
      analysis.issues.add('Missing DOCTYPE declaration');
      analysis.score += 5;
    }
    
    // Check for meta tags
    if (!htmlContent.contains('<meta charset=')) {
      analysis.issues.add('Missing charset meta tag');
      analysis.score += 3;
    }
    
    if (!htmlContent.contains('<meta name="viewport"')) {
      analysis.issues.add('Missing viewport meta tag');
      analysis.score += 3;
    }
    
    // Check for suspicious HTML patterns
    if (htmlContent.contains('<script')) {
      analysis.issues.add('Contains JavaScript (may be blocked)');
      analysis.score += 20;
    }
    
    if (htmlContent.contains('<iframe')) {
      analysis.issues.add('Contains iframes (may be blocked)');
      analysis.score += 15;
    }
    
    // Check for proper alt text on images
    final imgTags = RegExp(r'<img[^>]*>').allMatches(htmlContent);
    int imagesWithoutAlt = 0;
    for (final match in imgTags) {
      if (!match.group(0)!.contains('alt=')) {
        imagesWithoutAlt++;
      }
    }
    
    if (imagesWithoutAlt > 0) {
      analysis.issues.add('$imagesWithoutAlt images missing alt text');
      analysis.score += imagesWithoutAlt * 2;
    }
    
    return analysis;
  }

  LinkAnalysis _analyzeLinkContent() {
    final analysis = LinkAnalysis();
    final allLinks = <String>[];
    
    // Collect all links from blocks
    for (final block in widget.blocks) {
      if (block.type == TemplateBlockType.button) {
        final buttonBlock = block as ButtonBlock;
        if (buttonBlock.action.isNotEmpty) {
          allLinks.add(_renderTextWithData(buttonBlock.action));
        }
      }
    }
    
    for (final link in allLinks) {
      // Check for suspicious domains
      final suspiciousDomains = [
        'bit.ly', 'tinyurl.com', 'goo.gl', 't.co', 'ow.ly',
        'short.link', 'tiny.cc', 'is.gd', 'buff.ly'
      ];
      
      for (final domain in suspiciousDomains) {
        if (link.contains(domain)) {
          analysis.suspiciousLinks.add(link);
          analysis.issues.add('Shortened URL detected: $domain');
          analysis.score += 10;
          break;
        }
      }
      
      // Check for HTTP vs HTTPS
      if (link.startsWith('http://')) {
        analysis.issues.add('Non-secure HTTP link: $link');
        analysis.score += 5;
      }
      
      // Check for suspicious TLDs
      final suspiciousTlds = ['.tk', '.ml', '.ga', '.cf', '.click', '.download'];
      for (final tld in suspiciousTlds) {
        if (link.contains(tld)) {
          analysis.suspiciousLinks.add(link);
          analysis.issues.add('Suspicious TLD detected: $tld');
          analysis.score += 15;
          break;
        }
      }
      
      // Check for IP addresses instead of domains
      if (RegExp(r'\d+\.\d+\.\d+\.\d+').hasMatch(link)) {
        analysis.suspiciousLinks.add(link);
        analysis.issues.add('IP address used instead of domain');
        analysis.score += 20;
      }
    }
    
    analysis.totalLinks = allLinks.length;
    return analysis;
  }

  ImageAnalysis _analyzeImageContent() {
    final analysis = ImageAnalysis();
    
    int imageCount = 0;
    int totalTextLength = 0;
    
    // Count images and text
    for (final block in widget.blocks) {
      switch (block.type) {
        case TemplateBlockType.image:
          imageCount++;
          break;
        case TemplateBlockType.text:
          final textBlock = block as TextBlock;
          totalTextLength += _renderTextWithData(textBlock.text).length;
          break;
        case TemplateBlockType.richText:
          final richTextBlock = block as RichTextBlock;
          final plainText = richTextBlock.htmlContent.replaceAll(RegExp(r'<[^>]*>'), '');
          totalTextLength += _renderTextWithData(plainText).length;
          break;
        case TemplateBlockType.list:
          final listBlock = block as ListBlock;
          for (final item in listBlock.items) {
            totalTextLength += _renderTextWithData(item).length;
          }
          break;
        case TemplateBlockType.button:
          final buttonBlock = block as ButtonBlock;
          totalTextLength += _renderTextWithData(buttonBlock.text).length;
          break;
        default:
          logger.i('block type not supported: ${block.type}');
          break;
      }
    }
    
    analysis.imageCount = imageCount;
    analysis.textLength = totalTextLength;
    
    // Calculate image-to-text ratio
    if (totalTextLength > 0 && imageCount > 0) {
      analysis.imageToTextRatio = imageCount / (totalTextLength / 100);
      
      // Flag if too many images relative to text
      if (analysis.imageToTextRatio > 3) {
        analysis.issues.add('High image-to-text ratio (${analysis.imageToTextRatio.toStringAsFixed(1)})');
        analysis.score += 15;
      }
    }
    
    // Check for image-only emails
    if (imageCount > 0 && totalTextLength < 50) {
      analysis.issues.add('Mostly images with little text content');
      analysis.score += 25;
    }
    
    return analysis;
  }

  void _showSpamAnalysisResults(SpamAnalysisResult analysis) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        title: Row(
          children: [
            Icon(
              analysis.overallScore < 30 
                  ? FluentIcons.completed_solid
                  : analysis.overallScore < 60
                      ? FluentIcons.bug_warning
                      : FluentIcons.error_badge,
              color: analysis.overallScore < 30 
                  ? Colors.green
                  : analysis.overallScore < 60
                      ? Colors.orange
                      : Colors.red,
            ),
            const SizedBox(width: 8),
            Text('Spam Analysis Results'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall Score
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: analysis.overallScore < 30 
                      ? Colors.green.withValues(alpha: 0.1)
                      : analysis.overallScore < 60
                          ? Colors.orange.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: analysis.overallScore < 30 
                        ? Colors.green
                        : analysis.overallScore < 60
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Spam Score: ${analysis.overallScore}/100',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      analysis.overallScore < 30 
                          ? 'Low Risk - Email should pass most spam filters'
                          : analysis.overallScore < 60
                              ? 'Medium Risk - May be flagged by some spam filters'
                              : 'High Risk - Likely to be flagged as spam',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Subject Analysis
              if (analysis.subjectAnalysis.score > 0) ...[
                _buildAnalysisSection(
                  'Subject Line Issues',
                  analysis.subjectAnalysis.issues,
                  analysis.subjectAnalysis.spamWords.isNotEmpty 
                      ? 'Spam words found: ${analysis.subjectAnalysis.spamWords.join(', ')}'
                      : null,
                  analysis.subjectAnalysis.score,
                ),
                const SizedBox(height: 16),
              ],
              
              // Content Analysis
              if (analysis.contentAnalysis.score > 0) ...[
                _buildAnalysisSection(
                  'Content Issues',
                  analysis.contentAnalysis.issues,
                  analysis.contentAnalysis.spamPhrases.isNotEmpty 
                      ? 'Spam phrases found: ${analysis.contentAnalysis.spamPhrases.join(', ')}'
                      : null,
                  analysis.contentAnalysis.score,
                ),
                const SizedBox(height: 16),
              ],
              
              // HTML Analysis
              if (analysis.htmlAnalysis != null && analysis.htmlAnalysis!.score > 0) ...[
                _buildAnalysisSection(
                  'HTML Structure Issues',
                  analysis.htmlAnalysis!.issues,
                  null,
                  analysis.htmlAnalysis!.score,
                ),
                const SizedBox(height: 16),
              ],
              
              // Link Analysis
              if (analysis.linkAnalysis.score > 0) ...[
                _buildAnalysisSection(
                  'Link Issues',
                  analysis.linkAnalysis.issues,
                  analysis.linkAnalysis.suspiciousLinks.isNotEmpty 
                      ? 'Suspicious links: ${analysis.linkAnalysis.suspiciousLinks.join(', ')}'
                      : null,
                  analysis.linkAnalysis.score,
                ),
                const SizedBox(height: 16),
              ],
              
              // Image Analysis
              if (analysis.imageAnalysis.score > 0) ...[
                _buildAnalysisSection(
                  'Image Issues',
                  analysis.imageAnalysis.issues,
                  null,
                  analysis.imageAnalysis.score,
                ),
                const SizedBox(height: 16),
              ],
              
              // Recommendations
              if (analysis.overallScore > 0) ...[
                const Text(
                  'Recommendations:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...analysis.getRecommendations().map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text(rec)),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          Button(
            child: const Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          if (analysis.overallScore > 30)
            FilledButton(
              child: const Text('View Suggestions'),
              onPressed: () {
                Navigator.of(context).pop();
                _showSpamFixSuggestions(analysis);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection(String title, List<String> issues, String? additionalInfo, int score) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '+$score points',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...issues.map((issue) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: Colors.red)),
                Expanded(child: Text(issue)),
              ],
            ),
          )),
          if (additionalInfo != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                additionalInfo,
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSpamFixSuggestions(SpamAnalysisResult analysis) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        title: const Text('Spam Fix Suggestions'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Here are specific suggestions to improve your spam score:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              
              ...analysis.getDetailedSuggestions().map((suggestion) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(suggestion.description),
                    if (suggestion.example != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Example: ${suggestion.example}',
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          Button(
            child: const Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showCharacterCount() {
    final totalChars = widget.blocks
        .where((block) => block.type == TemplateBlockType.text)
        .map((block) => _renderTextWithData((block as TextBlock).text).length)
        .fold(0, (sum, length) => sum + length);

    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: const Text('Character Count'),
        content: Text('Total characters: $totalChars (WhatsApp limit: 4096)'),
        severity: totalChars > 4096 ? InfoBarSeverity.warning : InfoBarSeverity.info,
        onClose: close,
      ),
    );
  }

  void _validateMediaContent() {
    final imageBlocks = widget.blocks.where((block) => block.type == TemplateBlockType.image);
    
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: const Text('Media Validation'),
        content: Text('Found ${imageBlocks.length} media blocks. All formats supported.'),
        severity: InfoBarSeverity.success,
        onClose: close,
      ),
    );
  }

  void _copyWhatsAppText(BuildContext context) async {
    try {
      final textContent = await _generateWhatsAppText();
      
      // Copy to clipboard using Flutter's clipboard service
      await Clipboard.setData(ClipboardData(text: textContent));
      
      if (context.mounted) {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Text Copied'),
            content: Text('WhatsApp message content copied to clipboard (${textContent.length} characters)'),
            severity: InfoBarSeverity.success,
            onClose: close,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Copy Failed'),
            content: Text('Failed to copy content to clipboard: $e'),
            severity: InfoBarSeverity.error,
            onClose: close,
          ),
        );
      }
    }
  }

  Future<String> _generateWhatsAppText() async {
    final buffer = StringBuffer();
    
    for (final block in widget.blocks) {
      switch (block.type) {
        case TemplateBlockType.text:
          final textBlock = block as TextBlock;
          buffer.writeln(_renderTextWithData(textBlock.text));
          break;
          
        case TemplateBlockType.list:
          final listBlock = block as ListBlock;
          for (int i = 0; i < listBlock.items.length; i++) {
            final prefix = listBlock.listType == 'numbered' 
                ? '${i + 1}. ' 
                : '${listBlock.bulletStyle} ';
            buffer.writeln('$prefix${_renderTextWithData(listBlock.items[i])}');
          }
          break;
          
        case TemplateBlockType.button:
          final buttonBlock = block as ButtonBlock;
          buffer.writeln('🔗 ${_renderTextWithData(buttonBlock.text)}');
          if (buttonBlock.action.isNotEmpty) {
            buffer.writeln(_renderTextWithData(buttonBlock.action));
          }
          break;
          
        case TemplateBlockType.qrCode:
          final qrBlock = block as QRCodeBlock;
          buffer.writeln('📱 QR Code');
          if (qrBlock.data.isNotEmpty) {
            buffer.writeln(_renderTextWithData(qrBlock.data));
          }
          break;
          
        case TemplateBlockType.richText:
          final richTextBlock = block as RichTextBlock;
          // Strip HTML tags for WhatsApp
          final plainText = richTextBlock.htmlContent.replaceAll(RegExp(r'<[^>]*>'), '');
          buffer.writeln(_renderTextWithData(plainText));
          break;
          
        case TemplateBlockType.spacer:
          // Add line breaks for spacers
          buffer.writeln();
          break;
          
        case TemplateBlockType.divider:
          // Add separator for dividers
          buffer.writeln('─────────────');
          break;
          
        case TemplateBlockType.image:
          final imageBlock = block as ImageBlock;
          final imageData = await _processImageBlockForWhatsApp(imageBlock);
          buffer.writeln(imageData);
          break;
          
        default:
          // Skip other block types that don't translate to text
          break;
      }
    }
    
    return buffer.toString().trim();
  }

  Future<String> _processImageBlockForWhatsApp(ImageBlock block) async {
    try {
      // Handle local file paths (uploaded images)
      if (block.imageUrl.isNotEmpty && !block.imageUrl.startsWith('http')) {
        final file = File(block.imageUrl);
        if (file.existsSync()) {
          final fileName = file.path.split('/').last;
          final fileSize = await file.length();
          
          // Return user-friendly image representation for WhatsApp
          return '📷 Image: $fileName (${_formatFileSize(fileSize)})\n'
                 '${block.altText.isNotEmpty ? block.altText : 'Image attachment'}\n'
                 'File: ${file.path}';
        }
      }
      
      // Handle network URLs - these can be shared directly
      if (block.imageUrl.startsWith('http://') || block.imageUrl.startsWith('https://')) {
        return '📷 Image: ${block.imageUrl}\n'
               '${block.altText.isNotEmpty ? block.altText : 'Shared image'}';
      }
      
      // Fallback for empty or invalid URLs
      return '📷 [Image placeholder]${block.altText.isNotEmpty ? ' - ${block.altText}' : ''}';
      
    } catch (e) {
      return '📷 [Image - Error: $e]';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Helper method to render text with fake data
  String _renderTextWithData(String text) {
    String result = text;
    final regex = RegExp(r'\{\{([^}]+)\}\}');
    
    for (final match in regex.allMatches(text)) {
      final placeholder = match.group(1);
      if (placeholder != null && _fakeClientData.containsKey(placeholder)) {
        result = result.replaceAll(match.group(0)!, _fakeClientData[placeholder]!);
      }
    }
    
    return result;
  }

  // Helper methods (keeping existing ones)
  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.black;
    }
  }

  TextAlign _parseAlignment(String alignment) {
    switch (alignment) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.left;
    }
  }

  Alignment _parseImageAlignment(String alignment) {
    switch (alignment) {
      case 'left':
        return Alignment.centerLeft;
      case 'right':
        return Alignment.centerRight;
      default:
        return Alignment.center;
    }
  }

  Alignment _parseButtonAlignment(String alignment) {
    switch (alignment) {
      case 'left':
        return Alignment.centerLeft;
      case 'right':
        return Alignment.centerRight;
      default:
        return Alignment.center;
    }
  }

  BoxFit _parseBoxFit(String fit) {
    switch (fit) {
      case 'contain':
        return BoxFit.contain;
      case 'fill':
        return BoxFit.fill;
      case 'fitWidth':
        return BoxFit.fitWidth;
      case 'fitHeight':
        return BoxFit.fitHeight;
      default:
        return BoxFit.cover;
    }
  }

  EdgeInsets _getButtonPadding(String size) {
    switch (size) {
      case 'small':
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case 'large':
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      default:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    }
  }

  double _getButtonFontSize(String size) {
    switch (size) {
      case 'small':
        return 12.0;
      case 'large':
        return 16.0;
      default:
        return 14.0;
    }
  }

  String _generateHtmlContent() {
    // Enhanced HTML generation for email templates
    StringBuffer html = StringBuffer();
    html.writeln('<!DOCTYPE html>');
    html.writeln('<html lang="en">');
    html.writeln('<head>');
    html.writeln('  <meta charset="UTF-8">');
    html.writeln('  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    html.writeln('  <title>${widget.templateName.isNotEmpty ? widget.templateName : "Template Preview"}</title>');
    html.writeln('  <style>');
    html.writeln(_generateEmailCSS());
    html.writeln('  </style>');
    html.writeln('</head>');
    html.writeln('<body>');
    html.writeln('  <div class="email-container">');
    
    if (widget.templateSubject.isNotEmpty && widget.templateType == TemplateType.email) {
      html.writeln('    <div class="email-header">');
      html.writeln('      <h1>${_renderTextWithData(widget.templateSubject)}</h1>');
      html.writeln('    </div>');
    }

    html.writeln('    <div class="email-body">');
    for (var block in widget.blocks) {
      html.writeln(_convertBlockToHtml(block));
    }
    html.writeln('    </div>');

    html.writeln('    <div class="email-footer">');
    html.writeln('      <p>This email was sent by ${_fakeClientData['company']} using Template Builder</p>');
    html.writeln('    </div>');
    html.writeln('  </div>');
    html.writeln('</body>');
    html.writeln('</html>');
    return html.toString();
  }

  String _generateEmailCSS() {
    return '''
    body { 
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
      margin: 0; 
      padding: 20px; 
      background-color: #f4f4f4; 
      line-height: 1.6;
    }
    .email-container { 
      background-color: #ffffff; 
      padding: 0; 
      border-radius: 8px; 
      box-shadow: 0 0 10px rgba(0,0,0,0.1); 
      max-width: 600px; 
      margin: auto; 
      overflow: hidden;
    }
    .email-header {
      background-color: #f8f9fa;
      padding: 20px;
      border-bottom: 1px solid #e9ecef;
    }
    .email-header h1 {
      margin: 0;
      font-size: 24px;
      color: #333;
    }
    .email-body {
      padding: 20px;
    }
    .email-footer {
      background-color: #f8f9fa;
      padding: 15px 20px;
      border-top: 1px solid #e9ecef;
      text-align: center;
    }
    .email-footer p {
      margin: 0;
      font-size: 12px;
      color: #6c757d;
    }
    .button {
      display: inline-block;
      padding: 12px 24px;
      text-decoration: none;
      border-radius: 4px;
      font-weight: 500;
      text-align: center;
      transition: all 0.2s ease;
    }
    .button:hover {
      transform: translateY(-1px);
      box-shadow: 0 4px 8px rgba(0,0,0,0.15);
    }
    @media only screen and (max-width: 600px) {
      .email-container {
        margin: 10px;
        border-radius: 0;
      }
      .email-body {
        padding: 15px;
      }
    }
    ''';
  }

  String _convertBlockToHtml(TemplateBlock block) {
    switch (block.type) {
      case TemplateBlockType.text:
        final tb = block as TextBlock;
        String style = 'font-size: ${tb.fontSize}px; color: ${tb.color}; line-height: ${tb.lineHeight}; letter-spacing: ${tb.letterSpacing}px; text-align: ${tb.alignment}; margin: 16px 0;';
        if (tb.fontWeight == 'bold') style += ' font-weight: bold;';
        if (tb.italic) style += ' font-style: italic;';
        if (tb.underline) style += ' text-decoration: underline;';
        return '<div style="$style">${_renderTextWithData(tb.text)}</div>';
        
      case TemplateBlockType.image:
        final ib = block as ImageBlock;
        String imgStyle = 'max-width: 100%; height: auto; border-radius: ${ib.borderRadius}px;';
        if (ib.borderWidth > 0) {
          imgStyle += ' border: ${ib.borderWidth}px solid ${ib.borderColor};';
        }
        String containerStyle = 'text-align: ${ib.alignment}; margin: 16px 0;';
        return '<div style="$containerStyle"><img src="${ib.imageUrl}" alt="${ib.altText}" style="$imgStyle"></div>';
        
      case TemplateBlockType.button:
        final bb = block as ButtonBlock;
        String btnStyle = 'background-color: ${bb.backgroundColor}; color: ${bb.textColor}; padding: ${_getButtonPaddingHtml(bb.size)}; border-radius: ${bb.borderRadius}px; text-decoration: none; display: inline-block; text-align: center; font-weight: 500;';
        if (bb.borderWidth > 0) {
          btnStyle += ' border: ${bb.borderWidth}px solid ${bb.borderColor};';
        }
        if (bb.fullWidth) btnStyle += ' width: 100%; box-sizing: border-box;';
        final actionUrl = _renderTextWithData(bb.action);
        return '<div style="text-align: ${bb.alignment}; margin: 20px 0;"><a href="${actionUrl.isNotEmpty ? actionUrl : '#'}" class="button" style="$btnStyle">${_renderTextWithData(bb.text)}</a></div>';
        
      case TemplateBlockType.spacer:
        return '<div style="height: ${(block as SpacerBlock).height}px;"></div>';
        
      case TemplateBlockType.divider:
        final db = block as DividerBlock;
        return '<hr style="border: none; border-top: ${db.thickness}px solid ${db.color}; margin: 20px 0; width: ${db.width}%;">';
        
      case TemplateBlockType.richText:
        return '<div style="margin: 16px 0;">${_renderTextWithData((block as RichTextBlock).htmlContent)}</div>';

      case TemplateBlockType.list:
        final lb = block as ListBlock;
        final listTag = lb.listType == 'numbered' ? 'ol' : 'ul';
        final listItems = lb.items.map((item) => '<li>${_renderTextWithData(item)}</li>').join('\n');
        return '<$listTag style="color: ${lb.color}; font-size: ${lb.fontSize}px; margin: 16px 0;">$listItems</$listTag>';
     
      default:
        return '<div style="margin: 16px 0;">Unsupported block: ${block.type.name}</div>';
    }
  }

  String _getButtonPaddingHtml(String size) {
    switch (size) {
      case 'small': return '8px 16px';
      case 'large': return '16px 32px';
      default: return '12px 24px';
    }
  }

  void _exportHtml(BuildContext context) async {
    final String htmlContent = _generateHtmlContent();

    try {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Please select an output file:',
        fileName: '${widget.templateName.isNotEmpty ? widget.templateName.replaceAll(' ', '_') : "template"}.html',
        allowedExtensions: ['html'],
        type: FileType.custom,
      );

      if (outputFile != null) {
        if (!outputFile.toLowerCase().endsWith('.html')) {
          outputFile += '.html';
        }
        final file = File(outputFile);
        await file.writeAsString(htmlContent);
        
        if (context.mounted) {
          displayInfoBar(
            context,
            builder: (context, close) => InfoBar(
              title: const Text('HTML Exported Successfully'),
              content: Text('Template saved to: $outputFile'),
              severity: InfoBarSeverity.success,
              onClose: close,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Error Exporting HTML'),
            content: Text('Failed to save HTML file: $e'),
            severity: InfoBarSeverity.error,
            onClose: close,
          ),
        );
      }
    }
  }
}

// Spam Analysis Data Classes
class SpamAnalysisResult {
  late SubjectAnalysis subjectAnalysis;
  late ContentAnalysis contentAnalysis;
  HtmlAnalysis? htmlAnalysis;
  late LinkAnalysis linkAnalysis;
  late ImageAnalysis imageAnalysis;
  int overallScore = 0;

  void calculateOverallScore() {
    overallScore = subjectAnalysis.score +
                  contentAnalysis.score +
                  (htmlAnalysis?.score ?? 0) +
                  linkAnalysis.score +
                  imageAnalysis.score;
  }

  List<String> getRecommendations() {
    final recommendations = <String>[];
    
    if (subjectAnalysis.score > 0) {
      recommendations.add('Revise subject line to avoid spam trigger words');
      recommendations.add('Reduce excessive capitalization and punctuation');
    }
    
    if (contentAnalysis.score > 0) {
      recommendations.add('Remove or replace spam phrases in content');
      recommendations.add('Balance promotional language with informative content');
    }
    
    if (htmlAnalysis != null && htmlAnalysis!.score > 0) {
      recommendations.add('Improve HTML structure and add missing meta tags');
      recommendations.add('Add alt text to all images');
    }
    
    if (linkAnalysis.score > 0) {
      recommendations.add('Use HTTPS links and avoid URL shorteners');
      recommendations.add('Replace suspicious domains with trusted ones');
    }
    
    if (imageAnalysis.score > 0) {
      recommendations.add('Add more text content to balance image ratio');
      recommendations.add('Ensure images have descriptive alt text');
    }
    
    return recommendations;
  }

  List<SpamFixSuggestion> getDetailedSuggestions() {
    final suggestions = <SpamFixSuggestion>[];
    
    if (subjectAnalysis.spamWords.isNotEmpty) {
      suggestions.add(SpamFixSuggestion(
        title: 'Replace Spam Words in Subject',
        description: 'Replace trigger words with more neutral alternatives',
        example: 'Instead of "FREE URGENT OFFER", use "Special Invitation"',
      ));
    }
    
    if (contentAnalysis.spamPhrases.isNotEmpty) {
      suggestions.add(SpamFixSuggestion(
        title: 'Rephrase Marketing Content',
        description: 'Use softer, more professional language',
        example: 'Instead of "Act now!", use "We invite you to learn more"',
      ));
    }
    
    if (linkAnalysis.suspiciousLinks.isNotEmpty) {
      suggestions.add(SpamFixSuggestion(
        title: 'Use Trusted Domains',
        description: 'Replace shortened URLs with full, trusted domain links',
        example: 'Use https://yourcompany.com/offer instead of bit.ly/xyz123',
      ));
    }
    
    if (imageAnalysis.imageToTextRatio > 2) {
      suggestions.add(SpamFixSuggestion(
        title: 'Add More Text Content',
        description: 'Balance images with descriptive text content',
        example: 'Add product descriptions, benefits, or testimonials',
      ));
    }
    
    return suggestions;
  }
}

class SubjectAnalysis {
  int score = 0;
  List<String> issues = [];
  List<String> spamWords = [];
}

class ContentAnalysis {
  int score = 0;
  List<String> issues = [];
  List<String> spamPhrases = [];
  List<String> links = [];
  int textLength = 0;
  int imageCount = 0;
  int linkCount = 0;
  int buttonCount = 0;
}

class HtmlAnalysis {
  int score = 0;
  List<String> issues = [];
}

class LinkAnalysis {
  int score = 0;
  List<String> issues = [];
  List<String> suspiciousLinks = [];
  int totalLinks = 0;
}

class ImageAnalysis {
  int score = 0;
  List<String> issues = [];
  int imageCount = 0;
  int textLength = 0;
  double imageToTextRatio = 0.0;
}

class SpamFixSuggestion {
  final String title;
  final String description;
  final String? example;

  SpamFixSuggestion({
    required this.title,
    required this.description,
    this.example,
  });
}