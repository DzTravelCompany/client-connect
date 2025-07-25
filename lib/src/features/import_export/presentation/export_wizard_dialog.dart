import 'package:client_connect/src/features/import_export/data/import_export_model.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/import_export_providers.dart';
import '../../clients/data/client_model.dart';


class ExportWizardDialog extends ConsumerStatefulWidget {
  final List<ClientModel> clients;
  
  const ExportWizardDialog({super.key, required this.clients});

  @override
  ConsumerState<ExportWizardDialog> createState() => _ExportWizardDialogState();
}

class _ExportWizardDialogState extends ConsumerState<ExportWizardDialog> {
  int _currentStep = 0;
  final _fileNameController = TextEditingController(text: 'clients_export');
  List<ClientModel> _selectedClients = [];

  @override
  void initState() {
    super.initState();
    _selectedClients = List.from(widget.clients);
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(importExportSettingsProvider);
    final exportState = ref.watch(exportStateProvider);

    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
      title: const Text('Export Clients'),
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
                _buildStepIndicator(0, 'Select Clients', _currentStep >= 0),
                const Expanded(child: Divider()),
                _buildStepIndicator(1, 'Configure', _currentStep >= 1),
                const Expanded(child: Divider()),
                _buildStepIndicator(2, 'Export', _currentStep >= 2),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Step content
          Expanded(
            child: _buildStepContent(settings, exportState),
          ),
        ],
      ),
      actions: [
        Button(
          child: const Text('Cancel'),
          onPressed: () {
            ref.read(exportStateProvider.notifier).reset();
            Navigator.of(context).pop();
          },
        ),
        if (_currentStep > 0 && !exportState.isLoading)
          Button(
            child: const Text('Back'),
            onPressed: () => setState(() => _currentStep--),
          ),
        if (_currentStep < 2 && _canProceed())
          FilledButton(
            child: const Text('Next'),
            onPressed: () => setState(() => _currentStep++),
          ),
        if (_currentStep == 2 && !exportState.isLoading)
          FilledButton(
            child: const Text('Start Export'),
            onPressed: () => _startExport(settings),
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

  Widget _buildStepContent(ImportExportSettings settings, ExportState exportState) {
    switch (_currentStep) {
      case 0:
        return _buildClientSelectionStep();
      case 1:
        return _buildConfigurationStep(settings);
      case 2:
        return _buildExportStep(exportState);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildClientSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Clients to Export',
          style: FluentTheme.of(context).typography.subtitle,
        ),
        const SizedBox(height: 8),
        Text('Choose which clients to include in the export file.'),
        
        const SizedBox(height: 16),
        
        // Selection controls
        Row(
          children: [
            Text('${_selectedClients.length} of ${widget.clients.length} clients selected'),
            const Spacer(),
            Button(
              onPressed: () => setState(() => _selectedClients = List.from(widget.clients)),
              child: const Text('Select All'),
            ),
            const SizedBox(width: 8),
            Button(
              onPressed: () => setState(() => _selectedClients.clear()),
              child: const Text('Select None'),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Client list
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[60]),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ListView.builder(
              itemCount: widget.clients.length,
              itemBuilder: (context, index) {
                final client = widget.clients[index];
                final isSelected = _selectedClients.any((c) => c.id == client.id);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected){
                        _selectedClients.removeWhere((c) => c.id == client.id);
                      }
                      else{
                        _selectedClients.add(client);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1) Fluent UI checkbox
                        Checkbox(
                          checked: isSelected,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true){
                                _selectedClients.add(client);
                              }
                              else{
                                _selectedClients.removeWhere((c) => c.id == client.id);
                              }
                            });
                          },
                        ),

                        const SizedBox(width: 12),

                        // 2) Title + subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                client.fullName,
                                style: const TextStyle(fontSize: 14),
                              ),

                              const SizedBox(height: 4),

                              // Subtitle lines
                              if (client.email != null)
                                Text(
                                  client.email!,
                                  style: const TextStyle(fontSize: 12),
                                ),

                              if (client.company != null)
                                Text(
                                  client.company!,
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
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
              'Export Configuration',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 8),
            const Text('Configure how your data should be exported.'),
            
            const SizedBox(height: 24),
            
            // File name
            Text('File Name', style: FluentTheme.of(context).typography.body),
            const SizedBox(height: 8),
            TextFormBox(
              controller: _fileNameController,
              placeholder: 'Enter file name (without extension)',
            ),
            
            const SizedBox(height: 16),
            
            // Format selection
            Text('Export Format', style: FluentTheme.of(context).typography.body),
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
            
            // Include headers
            Row(
              children: [
                Checkbox(
                  checked: settings.includeHeaders,
                  onChanged: (value) {
                    ref.read(importExportSettingsProvider.notifier).updateIncludeHeaders(value ?? true);
                  },
                ),
                const SizedBox(width: 8),
                const Text('Include column headers'),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Export preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(FluentIcons.info, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Export Details',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Clients to export: ${_selectedClients.length}'),
                  Text('Format: ${settings.format.name.toUpperCase()}'),
                  Text('Headers: ${settings.includeHeaders ? "Included" : "Not included"}'),
                  const SizedBox(height: 8),
                  const Text(
                    'Exported fields: First Name, Last Name, Email, Phone, Company, Job Title, Address, Notes, Created At, Updated At',
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

  Widget _buildExportStep(ExportState exportState) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Summary',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 8),
            const Text('Review your export settings and start the export process.'),
            
            const SizedBox(height: 24),
            
            // Export summary
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
                    'Export Details',
                    style: FluentTheme.of(context).typography.body?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow('File Name', _fileNameController.text.trim()),
                  _buildSummaryRow('Format', ref.read(importExportSettingsProvider).format.name.toUpperCase()),
                  _buildSummaryRow('Clients', '${_selectedClients.length}'),
                  _buildSummaryRow('Headers', ref.read(importExportSettingsProvider).includeHeaders ? 'Included' : 'Not included'),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Export progress
            if (exportState.isLoading) ...[
              Text(
                'Export Progress',
                style: FluentTheme.of(context).typography.body?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              if (exportState.progress != null) ...[
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
              ] else ...[
                const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressRing(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Preparing export...'),
                  ],
                ),
              ],
            ],
            
            // Export result
            if (exportState.result != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(FluentIcons.completed, size: 20, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Export Completed',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Exported records: ${exportState.result!.totalRecords}'),
                    Text('File size: ${exportState.result!.fileSizeFormatted}'),
                    Text('Processing time: ${exportState.result!.processingTime.inSeconds}s'),
                    Text('File location: ${exportState.result!.filePath}'),
                  ],
                ),
              ),
            ],
            
            // Error message
            if (exportState.error != null)
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
                            'Export Failed',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            exportState.error!,
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
        return _selectedClients.isNotEmpty;
      case 1:
        return _fileNameController.text.trim().isNotEmpty;
      default:
        return false;
    }
  }

  void _startExport(ImportExportSettings settings) async {
    final fileName = _fileNameController.text.trim();
    if (fileName.isEmpty || _selectedClients.isEmpty) return;
    
    await ref.read(exportStateProvider.notifier).exportClients(
      clients: _selectedClients,
      fileName: fileName,
      settings: settings,
    );
  }
}
