import 'package:client_connect/constants.dart';
import 'package:client_connect/src/features/import_export/data/import_export_model.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'dart:io';

class ExportResultDialog extends StatelessWidget {
  final ExportResult result;
  
  const ExportResultDialog({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
      title: const Text('Export Results'),
      content: Column(
        children: [
          // Success indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Icon(
                  FluentIcons.completed,
                  size: 48,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                Text(
                  'Export Completed Successfully',
                  style: FluentTheme.of(context).typography.subtitle?.copyWith(
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text('${result.totalRecords} clients exported'),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Export details
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[10],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[40]),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export Details',
                  style: FluentTheme.of(context).typography.body?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDetailRow('Records Exported', '${result.totalRecords}'),
                _buildDetailRow('File Size', result.fileSizeFormatted),
                _buildDetailRow('Processing Time', '${result.processingTime.inSeconds} seconds'),
                _buildDetailRow('File Location', result.filePath),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // File actions
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => _openFileLocation(result.filePath),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(FluentIcons.folder_open, size: 16),
                      SizedBox(width: 8),
                      Text('Open File Location'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Button(
                  onPressed: () => _openFile(result.filePath),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(FluentIcons.open_file, size: 16),
                      SizedBox(width: 8),
                      Text('Open File'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Button(
          child: const Text('Close'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
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
