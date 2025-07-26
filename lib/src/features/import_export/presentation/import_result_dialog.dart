import 'package:client_connect/src/features/import_export/data/import_export_model.dart';
import 'package:fluent_ui/fluent_ui.dart';


class ImportResultDialog extends StatelessWidget {
  final ImportResult result;
  
  const ImportResultDialog({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
      title: const Text('Import Results'),
      content: Column(
        children: [
          // Summary section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: result.hasErrors 
                  ? Colors.orange.withValues(alpha: 0.1)
                  : Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: result.hasErrors 
                    ? Colors.orange.withValues(alpha: 0.3)
                    : Colors.green.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      result.hasErrors ? FluentIcons.warning : FluentIcons.completed,
                      size: 24,
                      color: result.hasErrors ? Colors.orange : Colors.green,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Import ${result.hasErrors ? "Completed with Warnings" : "Successful"}',
                      style: FluentTheme.of(context).typography.subtitle?.copyWith(
                        color: result.hasErrors ? Colors.orange : Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Records',
                        result.totalRecords.toString(),
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Successful',
                        result.successfulImports.toString(),
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Failed',
                        result.failedImports.toString(),
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Success Rate',
                        '${(result.successRate * 100).toInt()}%',
                        result.successRate > 0.8 ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                Text('Processing time: ${result.processingTime.inSeconds} seconds'),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Errors section
          if (result.hasErrors) ...[
            Row(
              children: [
                Icon(FluentIcons.error, size: 20, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Import Errors (${result.errors.length})',
                  style: FluentTheme.of(context).typography.subtitle,
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[60]),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  itemCount: result.errors.length,
                  itemBuilder: (context, index) {
                    final error = result.errors[index];
                    return _buildErrorItem(error);
                  },
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      FluentIcons.completed,
                      size: 64,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'All records imported successfully!',
                      style: FluentTheme.of(context).typography.subtitle?.copyWith(
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('No errors occurred during the import process.'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        Button(
          child: const Text('Close'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        if (result.hasErrors)
          FilledButton(
            child: const Text('Export Error Report'),
            onPressed: () => _exportErrorReport(context, result),
          ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorItem(ImportError error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[40]),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              'Row ${error.rowNumber}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              error.field,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              error.value.isEmpty ? '[Empty]' : error.value,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[100],
                fontStyle: error.value.isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              error.errorMessage,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _exportErrorReport(BuildContext context, ImportResult result) {
    // TODO: Implement error report export
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: const Text('Feature Coming Soon'),
        content: const Text('Error report export will be available in a future update.'),
        severity: InfoBarSeverity.info,
        onClose: close,
      ),
    );
  }
}