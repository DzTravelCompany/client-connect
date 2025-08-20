import 'package:client_connect/constants.dart';
import 'package:client_connect/src/features/import_export/data/import_export_model.dart';
import 'package:fluent_ui/fluent_ui.dart';
import '../../../core/design_system/design_tokens.dart';
import '../../../core/design_system/component_library.dart';
import 'dart:io';

class ExportResultDialog extends StatelessWidget {
  final ExportResult result;
  
  const ExportResultDialog({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 650, maxHeight: 550),
      title: Text(
        'Export Results',
        style: DesignTextStyles.titleLarge,
      ),
      content: Column(
        children: [
          DesignSystemComponents.standardCard(
            semanticLabel: 'Export completion confirmation',
            child: Column(
              children: [
                Icon(
                  FluentIcons.completed,
                  size: DesignTokens.iconSizeXLarge,
                  color: DesignTokens.semanticSuccess,
                ),
                const SizedBox(height: DesignTokens.space4),
                Text(
                  'Export Completed Successfully',
                  style: DesignTextStyles.subtitle.copyWith(
                    color: DesignTokens.semanticSuccess,
                  ),
                ),
                const SizedBox(height: DesignTokens.space2),
                DesignSystemComponents.statusBadge(
                  text: '${result.totalRecords} clients exported',
                  type: SemanticColorType.success,
                  icon: FluentIcons.people,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: DesignTokens.sectionSpacing),
          
          DesignSystemComponents.standardCard(
            semanticLabel: 'Export operation details',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      FluentIcons.info,
                      size: DesignTokens.iconSizeSmall,
                      color: DesignTokens.semanticInfo,
                    ),
                    const SizedBox(width: DesignTokens.space2),
                    Text(
                      'Export Details',
                      style: DesignTextStyles.body.copyWith(
                        fontWeight: DesignTokens.fontWeightMedium,
                        color: DesignTokens.semanticInfo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space3),
                _buildDetailRow('Records Exported', '${result.totalRecords}', FluentIcons.number_field),
                _buildDetailRow('File Size', result.fileSizeFormatted, FluentIcons.hard_drive),
                _buildDetailRow('Processing Time', '${result.processingTime.inSeconds} seconds', FluentIcons.timer),
                _buildDetailRow('File Location', result.filePath, FluentIcons.folder, isPath: true),
              ],
            ),
          ),
          
          const SizedBox(height: DesignTokens.sectionSpacing),
          
          Row(
            children: [
              Expanded(
                child: DesignSystemComponents.primaryButton(
                  text: 'Open File Location',
                  icon: FluentIcons.folder_open,
                  onPressed: () => _openFileLocation(result.filePath),
                  semanticLabel: 'Open file location in explorer',
                ),
              ),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: DesignSystemComponents.secondaryButton(
                  text: 'Open File',
                  icon: FluentIcons.open_file,
                  onPressed: () => _openFile(result.filePath),
                  semanticLabel: 'Open exported file',
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        DesignSystemComponents.secondaryButton(
          text: 'Close',
          onPressed: () => Navigator.of(context).pop(),
          semanticLabel: 'Close export results dialog',
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {bool isPath = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: DesignTokens.iconSizeSmall,
            color: DesignTokens.textSecondary,
          ),
          const SizedBox(width: DesignTokens.space2),
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: DesignTextStyles.body.copyWith(
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: DesignTextStyles.body.copyWith(
                color: isPath ? DesignTokens.textSecondary : DesignTokens.textPrimary,
                fontFamily: isPath ? 'monospace' : null,
              ),
              maxLines: isPath ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _openFileLocation(String filePath) {
    try {
      final file = File(filePath);
      final directory = file.parent;
      
      // Open the directory in Windows Explorer
      Process.run('explorer', [directory.path]);
    } catch (e) {
      logger.e('Error opening file location: $e');
    }
  }

  void _openFile(String filePath) {
    try {
      // Open the file with the default application
      Process.run('cmd', ['/c', 'start', '', filePath]);
    } catch (e) {
      logger.e('Error opening file: $e');
    }
  }
}