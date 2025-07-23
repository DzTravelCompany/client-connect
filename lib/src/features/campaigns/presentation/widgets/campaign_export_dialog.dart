import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/campaigns_model.dart';
import '../../logic/campaign_providers.dart';

class CampaignExportDialog extends ConsumerStatefulWidget {
  final CampaignModel campaign;

  const CampaignExportDialog({
    super.key,
    required this.campaign,
  });

  @override
  ConsumerState<CampaignExportDialog> createState() => _CampaignExportDialogState();
}

class _CampaignExportDialogState extends ConsumerState<CampaignExportDialog> {
  String _selectedFormat = 'csv';
  bool _includeMessageLogs = true;
  bool _includeStatistics = true;
  bool _includeRecipients = true;

  @override
  Widget build(BuildContext context) {
    final exportState = ref.watch(campaignExportProvider);

    return ContentDialog(
      title: const Text('Export Campaign Data'),
      content: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campaign info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(FluentIcons.download, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'Exporting Campaign',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.campaign.name,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Status: ${widget.campaign.statusDisplayName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[100],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Export format selection
            Text(
              'Export Format',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            _buildFormatOption('csv', 'CSV (Comma Separated Values)', 
                'Best for spreadsheet applications'),
            const SizedBox(height: 8),
            _buildFormatOption('json', 'JSON (JavaScript Object Notation)', 
                'Best for data processing and APIs'),
            const SizedBox(height: 8),
            _buildFormatOption('pdf', 'PDF (Portable Document Format)', 
                'Best for reports and documentation'),

            const SizedBox(height: 20),

            // Data inclusion options
            Text(
              'Include Data',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            Checkbox(
              checked: _includeRecipients,
              onChanged: (value) => setState(() => _includeRecipients = value ?? true),
              content: const Text('Recipients information'),
            ),
            
            Checkbox(
              checked: _includeMessageLogs,
              onChanged: (value) => setState(() => _includeMessageLogs = value ?? true),
              content: const Text('Message delivery logs'),
            ),
            
            Checkbox(
              checked: _includeStatistics,
              onChanged: (value) => setState(() => _includeStatistics = value ?? true),
              content: const Text('Campaign statistics'),
            ),

            const SizedBox(height: 20),

            // Export preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(FluentIcons.info, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        'Export Preview',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildPreviewRow('Format', _selectedFormat.toUpperCase()),
                  _buildPreviewRow('File name', '${_sanitizeFileName(widget.campaign.name)}.$_selectedFormat'),
                  _buildPreviewRow('Estimated size', _getEstimatedSize()),
                  _buildPreviewRow('Data sections', _getIncludedSections()),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        Button(
          onPressed: exportState.isLoading 
              ? null 
              : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: exportState.isLoading ? null : _export,
          child: exportState.isLoading
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressRing(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Exporting...'),
                  ],
                )
              : const Text('Export'),
        ),
      ],
    );
  }

  Widget _buildFormatOption(String format, String title, String description) {
    return SizedBox(
      width: double.infinity,
      child: RadioButton(
        checked: _selectedFormat == format,
        onChanged: (value) => setState(() => _selectedFormat = format),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[100],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[100],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
  }

  String _getEstimatedSize() {
    int baseSize = 1; // KB
    if (_includeRecipients) baseSize += widget.campaign.clientIds.length ~/ 100;
    if (_includeMessageLogs) baseSize += widget.campaign.clientIds.length ~/ 50;
    if (_includeStatistics) baseSize += 1;
    
    return '~${baseSize}KB';
  }

  String _getIncludedSections() {
    List<String> sections = [];
    if (_includeRecipients) sections.add('Recipients');
    if (_includeMessageLogs) sections.add('Message logs');
    if (_includeStatistics) sections.add('Statistics');
    
    return sections.join(', ');
  }

  void _export() async {
    await ref.read(campaignExportProvider.notifier).exportCampaignData(
      widget.campaign.id,
      format: _selectedFormat,
      includeMessageLogs: _includeMessageLogs,
      includeStatistics: _includeStatistics,
    );

    if (mounted) {
      final state = ref.read(campaignExportProvider);
      if (state.error == null) {
        Navigator.of(context).pop();
        _showSuccessMessage(state.exportFilePath);
      } else {
        _showErrorMessage(state.error!);
      }
    }
  }

  void _showSuccessMessage(String? filePath) {
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: const Text('Export Completed'),
        content: Text(
          filePath != null 
              ? 'Campaign data exported to: $filePath'
              : 'Campaign data has been exported successfully.',
        ),
        severity: InfoBarSeverity.success,
        onClose: close,
      ),
    );
  }

  void _showErrorMessage(String error) {
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: const Text('Export Failed'),
        content: Text(error),
        severity: InfoBarSeverity.error,
        onClose: close,
      ),
    );
  }
}