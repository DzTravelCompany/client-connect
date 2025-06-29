import 'package:client_connect/src/features/clients/data/client_model.dart';
import 'package:client_connect/src/features/import_export/data/import_export_model.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../logic/import_export_providers.dart';
import '../../clients/logic/client_providers.dart';
import 'import_wizard_dialog.dart';
import 'export_wizard_dialog.dart';
import 'import_result_dialog.dart';
import 'export_result_dialog.dart';

class ImportExportScreen extends ConsumerStatefulWidget {
  const ImportExportScreen({super.key});

  @override
  ConsumerState<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends ConsumerState<ImportExportScreen> {
  @override
  Widget build(BuildContext context) {
    final importState = ref.watch(importStateProvider);
    final exportState = ref.watch(exportStateProvider);
    final clientsAsync = ref.watch(allClientsProvider);

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Import & Export'),
        commandBar: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.back),
              label: const Text('Back to Clients'),
              onPressed: () => context.go('/clients'),
            ),
          ],
        ),
      ),
      content: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Text(
                'Client Data Management',
                style: FluentTheme.of(context).typography.title,
              ),
              const SizedBox(height: 8),
              Text(
                'Import clients from external files or export your client database for backup and sharing.',
                style: FluentTheme.of(context).typography.body,
              ),
              
              const SizedBox(height: 32),
        
              // Import/Export cards
              Row(
                children: [
                  // Import card
                  Expanded(
                    child: _buildImportCard(context, importState),
                  ),
                  const SizedBox(width: 24),
                  // Export card
                  Expanded(
                    child: _buildExportCard(context, exportState, clientsAsync),
                  ),
                ],
              ),
        
              const SizedBox(height: 32),
        
              // Recent operations
              _buildRecentOperations(context, importState, exportState),
        
              const SizedBox(height: 32),
        
              // Help section
              _buildHelpSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImportCard(BuildContext context, ImportState importState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    FluentIcons.download,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import Clients',
                        style: FluentTheme.of(context).typography.subtitle,
                      ),
                      const SizedBox(height: 4),
                      const Text('Add clients from CSV, Excel, or JSON files'),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Import progress
            if (importState.isLoading && importState.progress != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: ProgressRing(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(importState.progress!.currentOperation),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ProgressBar(
                    value: importState.progress!.progressPercentage * 100,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${importState.progress!.processedRecords} of ${importState.progress!.totalRecords} records processed',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // Import result summary
            if (importState.result != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: importState.result!.hasErrors 
                      ? Colors.orange.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: importState.result!.hasErrors 
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
                          importState.result!.hasErrors 
                              ? FluentIcons.warning 
                              : FluentIcons.completed,
                          size: 16,
                          color: importState.result!.hasErrors ? Colors.orange : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Last Import: ${importState.result!.successfulImports} successful, ${importState.result!.failedImports} failed',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: importState.result!.hasErrors ? Colors.orange : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    if (importState.result!.hasErrors) ...[
                      const SizedBox(height: 8),
                      Button(
                        onPressed: () => _showImportResult(context, importState.result!),
                        child: const Text('View Error Details'),
                      ),
                    ],
                  ],
                ),
              ),

            // Error message
            if (importState.error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(FluentIcons.error, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Import failed: ${importState.error}',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            // Import actions
            Row(
              children: [
                FilledButton(
                  onPressed: importState.isLoading ? null : () => _showImportWizard(context),
                  child: const Text('Import Clients'),
                ),
                const SizedBox(width: 12),
                if (importState.result != null)
                  Button(
                    onPressed: () => _showImportResult(context, importState.result!),
                    child: const Text('View Last Result'),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Supported formats
            Text(
              'Supported formats: CSV, JSON, Excel (XLSX)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[100],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportCard(BuildContext context, ExportState exportState, AsyncValue clientsAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    FluentIcons.upload,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Export Clients',
                        style: FluentTheme.of(context).typography.subtitle,
                      ),
                      const SizedBox(height: 4),
                      const Text('Save your client database to CSV or JSON'),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Export progress
            if (exportState.isLoading && exportState.progress != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: ProgressRing(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(exportState.progress!.currentOperation),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ProgressBar(
                    value: exportState.progress!.progressPercentage * 100,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${exportState.progress!.processedRecords} of ${exportState.progress!.totalRecords} records processed',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // Export result summary
            if (exportState.result != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(FluentIcons.completed, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Last Export: ${exportState.result!.totalRecords} clients exported',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'File size: ${exportState.result!.fileSizeFormatted}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Button(
                      onPressed: () => _showExportResult(context, exportState.result!),
                      child: const Text('View Export Details'),
                    ),
                  ],
                ),
              ),

            // Error message
            if (exportState.error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(FluentIcons.error, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Export failed: ${exportState.error}',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            // Export actions
            clientsAsync.when(
              data: (clients) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FilledButton(
                        onPressed: (exportState.isLoading || clients.isEmpty) 
                            ? null 
                            : () => _showExportWizard(context, clients),
                        child: const Text('Export Clients'),
                      ),
                      const SizedBox(width: 12),
                      if (exportState.result != null)
                        Button(
                          onPressed: () => _showExportResult(context, exportState.result!),
                          child: const Text('View Last Result'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    clients.isEmpty 
                        ? 'No clients to export'
                        : '${clients.length} clients available for export',
                    style: TextStyle(
                      fontSize: 12,
                      color: clients.isEmpty ? Colors.red : Colors.grey[100],
                    ),
                  ),
                ],
              ),
              loading: () => const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: ProgressRing(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Loading clients...'),
                ],
              ),
              error: (error, stack) => Text(
                'Error loading clients: $error',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOperations(BuildContext context, ImportState importState, ExportState exportState) {
    final hasRecentOperations = importState.result != null || exportState.result != null;
    
    if (!hasRecentOperations) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Operations',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 16),
            
            if (importState.result != null)
              _buildOperationSummary(
                'Import',
                FluentIcons.download,
                Colors.blue,
                '${importState.result!.successfulImports} clients imported',
                'Processing time: ${importState.result!.processingTime.inSeconds}s',
                importState.result!.hasErrors ? 'With errors' : 'Successful',
                importState.result!.hasErrors ? Colors.orange : Colors.green,
                () => _showImportResult(context, importState.result!),
              ),
            
            if (importState.result != null && exportState.result != null)
              const SizedBox(height: 12),
            
            if (exportState.result != null)
              _buildOperationSummary(
                'Export',
                FluentIcons.upload,
                Colors.green,
                '${exportState.result!.totalRecords} clients exported',
                'File size: ${exportState.result!.fileSizeFormatted}',
                'Successful',
                Colors.green,
                () => _showExportResult(context, exportState.result!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationSummary(
    String operation,
    IconData icon,
    Color iconColor,
    String primaryText,
    String secondaryText,
    String status,
    Color statusColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[40]),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    primaryText,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    secondaryText,
                    style: TextStyle(fontSize: 12, color: Colors.grey[100]),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(FluentIcons.chevron_right, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(FluentIcons.info, size: 20, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  'Import & Export Guidelines',
                  style: FluentTheme.of(context).typography.subtitle,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildHelpItem(
              'CSV Format',
              'Use comma-separated values with headers: First Name, Last Name, Email, Phone, Company, Job Title, Address, Notes',
            ),
            _buildHelpItem(
              'Required Fields',
              'First Name and Last Name are required. Email is optional but recommended for campaigns.',
            ),
            _buildHelpItem(
              'Duplicate Handling',
              'By default, duplicates are detected by email address. You can choose to allow or skip duplicates.',
            ),
            _buildHelpItem(
              'Large Files',
              'Import/export operations run in the background. You can continue using the application while processing.',
            ),
            _buildHelpItem(
              'Data Validation',
              'Email addresses are automatically validated. Invalid entries will be reported in the import results.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[100],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showImportWizard(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ImportWizardDialog(),
    );
  }

  void _showExportWizard(BuildContext context, List<ClientModel> clients) {
    showDialog(
      context: context,
      builder: (context) => ExportWizardDialog(clients: clients),
    );
  }

  void _showImportResult(BuildContext context, ImportResult result) {
    showDialog(
      context: context,
      builder: (context) => ImportResultDialog(result: result),
    );
  }

  void _showExportResult(BuildContext context, ExportResult result) {
    showDialog(
      context: context,
      builder: (context) => ExportResultDialog(result: result),
    );
  }
}