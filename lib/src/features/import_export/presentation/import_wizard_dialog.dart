import 'package:client_connect/src/features/clients/logic/client_providers.dart';
import 'package:client_connect/src/features/import_export/data/import_export_model.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/import_export_providers.dart';
import '../data/import_export_service.dart';


class ImportWizardDialog extends ConsumerStatefulWidget {
  const ImportWizardDialog({super.key});

  @override
  ConsumerState<ImportWizardDialog> createState() => _ImportWizardDialogState();
}

class _ImportWizardDialogState extends ConsumerState<ImportWizardDialog> {
  int _currentStep = 0;
  String? _selectedFilePath;
  String? _selectedFileName;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(importExportSettingsProvider);
    final importState = ref.watch(importStateProvider);

    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
      title: const Text('Import Clients'),
      content: Column(
        children: [
          // Progress indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildStepIndicator(0, 'Select File', _currentStep >= 0),
                const Expanded(child: Divider()),
                _buildStepIndicator(1, 'Configure', _currentStep >= 1),
                const Expanded(child: Divider()),
                _buildStepIndicator(2, 'Import', _currentStep >= 2),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Step content
          Expanded(
            child: _buildStepContent(settings, importState),
          ),
        ],
      ),
      actions: [
        Button(
          child: const Text('Cancel'),
          onPressed: () {
            ref.read(importStateProvider.notifier).reset();
            Navigator.of(context).pop();
          },
        ),
        if (_currentStep > 0 && !importState.isLoading)
          Button(
            child: const Text('Back'),
            onPressed: () => setState(() => _currentStep--),
          ),
        if (_currentStep < 2 && _canProceed())
          FilledButton(
            child: const Text('Next'),
            onPressed: () => setState(() => _currentStep++),
          ),
        if (_currentStep == 2 && _selectedFilePath != null && !importState.isLoading)
          FilledButton(
            child: const Text('Start Import'),
            onPressed: () => _startImport(settings),
          ),
      ],
    );
  }

  Widget _buildStepIndicator(int step, String title, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive 
                ? FluentTheme.of(context).accentColor 
                : Colors.grey[60],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent(ImportExportSettings settings, ImportState importState) {
    switch (_currentStep) {
      case 0:
        return _buildFileSelectionStep();
      case 1:
        return _buildConfigurationStep(settings);
      case 2:
        return _buildImportStep(importState);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFileSelectionStep() {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Import File',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 8),
            const Text('Choose a CSV, JSON, or Excel file containing your client data.'),
            
            const SizedBox(height: 24),
            
            // File selection area
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedFilePath != null ? Colors.green : Colors.grey,
                  style: BorderStyle.solid,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
                color: _selectedFilePath != null 
                    ? Colors.green.withValues(alpha: 0.05)
                    : Colors.grey,
              ),
              child: _selectedFilePath != null
                  ? _buildSelectedFileInfo()
                  : _buildFileDropArea(),
            ),
            
            const SizedBox(height: 16),
            
            // Browse button
            Row(
              children: [
                FilledButton(
                  onPressed: _selectFile,
                  child: const Text('Browse Files'),
                ),
                const SizedBox(width: 16),
                if (_selectedFilePath != null)
                  Button(
                    onPressed: () => setState(() {
                      _selectedFilePath = null;
                      _selectedFileName = null;
                    }),
                    child: const Text('Clear Selection'),
                  ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Supported formats
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(FluentIcons.info, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Supported File Formats',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('• CSV (.csv) - Comma-separated values'),
                  const Text('• JSON (.json) - JavaScript Object Notation'),
                  const Text('• Excel (.xlsx) - Microsoft Excel format'),
                  const SizedBox(height: 8),
                  const Text(
                    'Maximum file size: 50MB',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFileInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.completed,
            size: 48,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          Text(
            'File Selected',
            style: FluentTheme.of(context).typography.subtitle?.copyWith(
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFileName ?? 'Unknown file',
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _selectedFilePath ?? '',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[100],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFileDropArea() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          FluentIcons.cloud_upload,
          size: 48,
          color: Colors.grey[100],
        ),
        const SizedBox(height: 16),
        Text(
          'Select a file to import',
          style: FluentTheme.of(context).typography.subtitle,
        ),
        const SizedBox(height: 8),
        Text(
          'Click "Browse Files" to select your import file',
          style: TextStyle(color: Colors.grey[100]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildConfigurationStep(ImportExportSettings settings) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Import Configuration',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 8),
            const Text('Configure how your data should be imported.'),
            
            const SizedBox(height: 24),
            
            // Format selection
            Text('File Format', style: FluentTheme.of(context).typography.body),
            const SizedBox(height: 8),
            ComboBox<ImportExportFormat>(
              value: settings.format,
              items: const [
                ComboBoxItem(
                  value: ImportExportFormat.csv,
                  child: Text('CSV (Comma-Separated Values)'),
                ),
                ComboBoxItem(
                  value: ImportExportFormat.json,
                  child: Text('JSON (JavaScript Object Notation)'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(importExportSettingsProvider.notifier).updateFormat(value);
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            // CSV-specific settings
            if (settings.format == ImportExportFormat.csv) ...[
              Text('CSV Delimiter', style: FluentTheme.of(context).typography.body),
              const SizedBox(height: 8),
              ComboBox<String>(
                value: settings.delimiter,
                items: const [
                  ComboBoxItem(value: ',', child: Text('Comma (,)')),
                  ComboBoxItem(value: ';', child: Text('Semicolon (;)')),
                  ComboBoxItem(value: '\t', child: Text('Tab')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref.read(importExportSettingsProvider.notifier).updateDelimiter(value);
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
            
            // General settings
            Row(
              children: [
                Checkbox(
                  checked: settings.includeHeaders,
                  onChanged: (value) {
                    ref.read(importExportSettingsProvider.notifier).updateIncludeHeaders(value ?? true);
                  },
                ),
                const SizedBox(width: 8),
                const Text('File includes header row'),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Checkbox(
                  checked: settings.skipEmptyRows,
                  onChanged: (value) {
                    ref.read(importExportSettingsProvider.notifier).updateSkipEmptyRows(value ?? true);
                  },
                ),
                const SizedBox(width: 8),
                const Text('Skip empty rows'),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Checkbox(
                  checked: settings.validateEmails,
                  onChanged: (value) {
                    ref.read(importExportSettingsProvider.notifier).updateValidateEmails(value ?? true);
                  },
                ),
                const SizedBox(width: 8),
                const Text('Validate email addresses'),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Checkbox(
                  checked: settings.allowDuplicates,
                  onChanged: (value) {
                    ref.read(importExportSettingsProvider.notifier).updateAllowDuplicates(value ?? false);
                  },
                ),
                const SizedBox(width: 8),
                const Text('Allow duplicate clients'),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Expected columns info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(FluentIcons.info, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Expected Column Headers',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Required: First Name, Last Name'),
                  const Text('Optional: Email, Phone, Company, Job Title, Address, Notes'),
                  const SizedBox(height: 8),
                  const Text(
                    'Column names are case-insensitive and spaces/underscores are ignored.',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportStep(ImportState importState) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Import Summary',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 8),
            const Text('Review your import settings and start the import process.'),
            
            const SizedBox(height: 24),
            
            // Import summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Import Details',
                    style: FluentTheme.of(context).typography.body?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow('File', _selectedFileName ?? 'Unknown'),
                  _buildSummaryRow('Format', ref.read(importExportSettingsProvider).format.name.toUpperCase()),
                  _buildSummaryRow('Headers', ref.read(importExportSettingsProvider).includeHeaders ? 'Included' : 'Not included'),
                  _buildSummaryRow('Validation', ref.read(importExportSettingsProvider).validateEmails ? 'Enabled' : 'Disabled'),
                  _buildSummaryRow('Duplicates', ref.read(importExportSettingsProvider).allowDuplicates ? 'Allowed' : 'Skip'),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Import progress
            if (importState.isLoading) ...[
              Text(
                'Import Progress',
                style: FluentTheme.of(context).typography.body?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              if (importState.progress != null) ...[
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
              ] else ...[
                const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressRing(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Preparing import...'),
                  ],
                ),
              ],
            ],
            
            // Import result
            if (importState.result != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: importState.result!.hasErrors 
                      ? Colors.orange.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
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
                          size: 20,
                          color: importState.result!.hasErrors ? Colors.orange : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Import Completed',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: importState.result!.hasErrors ? Colors.orange : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Total records: ${importState.result!.totalRecords}'),
                    Text('Successful: ${importState.result!.successfulImports}'),
                    Text('Failed: ${importState.result!.failedImports}'),
                    Text('Processing time: ${importState.result!.processingTime.inSeconds}s'),
                    if (importState.result!.hasErrors) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${importState.result!.errors.length} errors occurred during import.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            
            // Error message
            if (importState.error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(FluentIcons.error, size: 20, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Import Failed',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            importState.error!,
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedFilePath != null;
      case 1:
        return true; // Configuration is always valid
      default:
        return false;
    }
  }

  void _selectFile() async {
    final filePath = await ImportExportService.instance.pickImportFile();
    if (filePath != null) {
      setState(() {
        _selectedFilePath = filePath;
        _selectedFileName = filePath.split('/').last;
      });
    }
  }

  void _startImport(ImportExportSettings settings) async {
    if (_selectedFilePath == null) return;
    
    await ref.read(importStateProvider.notifier).importClients(
      filePath: _selectedFilePath!,
      settings: settings,
    );
    
    // Refresh clients list after import
    ref.invalidate(allClientsProvider);
  }
}