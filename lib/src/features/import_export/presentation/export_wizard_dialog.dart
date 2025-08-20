import 'package:client_connect/src/features/import_export/data/import_export_model.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/design_tokens.dart';
import '../../../core/design_system/component_library.dart';
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
      constraints: const BoxConstraints(maxWidth: 700, maxHeight: 750),
      title: Text(
        'Export Clients',
        style: DesignTextStyles.titleLarge,
      ),
      content: Column(
        children: [
          DesignSystemComponents.standardCard(
            semanticLabel: 'Export wizard progress steps',
            padding: const EdgeInsets.all(DesignTokens.space4),
            child: Row(
              children: [
                _buildStepIndicator(0, 'Select Clients', _currentStep >= 0),
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: DesignTokens.space2),
                    decoration: BoxDecoration(
                      color: _currentStep >= 1 
                          ? DesignTokens.semanticSuccess 
                          : DesignTokens.borderSecondary,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                    ),
                  ),
                ),
                _buildStepIndicator(1, 'Configure', _currentStep >= 1),
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: DesignTokens.space2),
                    decoration: BoxDecoration(
                      color: _currentStep >= 2 
                          ? DesignTokens.semanticSuccess 
                          : DesignTokens.borderSecondary,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                    ),
                  ),
                ),
                _buildStepIndicator(2, 'Export', _currentStep >= 2),
              ],
            ),
          ),
          
          const SizedBox(height: DesignTokens.sectionSpacing),
          
          Expanded(
            child: _buildStepContent(settings, exportState),
          ),
        ],
      ),
      actions: [
        DesignSystemComponents.secondaryButton(
          text: 'Cancel',
          onPressed: () {
            ref.read(exportStateProvider.notifier).reset();
            Navigator.of(context).pop();
          },
          semanticLabel: 'Cancel export process',
        ),
        if (_currentStep > 0 && !exportState.isLoading)
          DesignSystemComponents.secondaryButton(
            text: 'Back',
            icon: FluentIcons.back,
            onPressed: () => setState(() => _currentStep--),
            semanticLabel: 'Go back to previous step',
          ),
        if (_currentStep < 2 && _canProceed())
          DesignSystemComponents.primaryButton(
            text: 'Next',
            icon: FluentIcons.forward,
            onPressed: () => setState(() => _currentStep++),
            semanticLabel: 'Continue to next step',
          ),
        if (_currentStep == 2 && !exportState.isLoading)
          DesignSystemComponents.primaryButton(
            text: 'Start Export',
            icon: FluentIcons.upload,
            onPressed: () => _startExport(settings),
            semanticLabel: 'Begin exporting clients',
          ),
      ],
    );
  }

  Widget _buildStepIndicator(int step, String title, bool isActive) {
    return Column(
      children: [
        Container(
          width: DesignTokens.iconSizeXLarge,
          height: DesignTokens.iconSizeXLarge,
          decoration: BoxDecoration(
            color: isActive 
                ? DesignTokens.semanticSuccess
                : DesignTokens.semanticInfo,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive 
                  ? DesignTokens.semanticSuccess
                  : DesignTokens.borderSecondary,
              width: 2,
            ),
          ),
          child: Center(
            child: isActive
                ? Icon(
                    FluentIcons.completed,
                    color: DesignTokens.textAccent,
                    size: DesignTokens.iconSizeSmall,
                  )
                : Text(
                    '${step + 1}',
                    style: DesignTextStyles.body.copyWith(
                      color: isActive ? DesignTokens.textAccent : DesignTokens.textSecondary,
                      fontWeight: DesignTokens.fontWeightMedium,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: DesignTokens.space2),
        Text(
          title,
          style: DesignTextStyles.caption.copyWith(
            fontWeight: isActive ? DesignTokens.fontWeightMedium : DesignTokens.fontWeightRegular,
            color: isActive ? DesignTokens.textPrimary : DesignTokens.textSecondary,
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
          style: DesignTextStyles.subtitle,
        ),
        const SizedBox(height: DesignTokens.space2),
        Text(
          'Choose which clients to include in the export file.',
          style: DesignTextStyles.body.copyWith(
            color: DesignTokens.textSecondary,
          ),
        ),
        
        const SizedBox(height: DesignTokens.space4),
        
        DesignSystemComponents.standardCard(
          semanticLabel: 'Client selection controls',
          padding: const EdgeInsets.all(DesignTokens.space3),
          child: Row(
            children: [
              DesignSystemComponents.statusBadge(
                text: '${_selectedClients.length} of ${widget.clients.length} selected',
                type: SemanticColorType.info,
                icon: FluentIcons.people,
              ),
              const Spacer(),
              DesignSystemComponents.secondaryButton(
                text: 'Select All',
                icon: FluentIcons.select_all,
                onPressed: () => setState(() => _selectedClients = List.from(widget.clients)),
                semanticLabel: 'Select all clients for export',
              ),
              const SizedBox(width: DesignTokens.space2),
              DesignSystemComponents.secondaryButton(
                text: 'Select None',
                icon: FluentIcons.clear_selection,
                onPressed: () => setState(() => _selectedClients.clear()),
                semanticLabel: 'Deselect all clients',
              ),
            ],
          ),
        ),
        
        const SizedBox(height: DesignTokens.space4),
        
        Expanded(
          child: DesignSystemComponents.standardCard(
            semanticLabel: 'Client selection list',
            padding: EdgeInsets.zero,
            child: ListView.builder(
              itemCount: widget.clients.length,
              itemBuilder: (context, index) {
                final client = widget.clients[index];
                final isSelected = _selectedClients.any((c) => c.id == client.id);

                return DesignSystemComponents.standardCard(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedClients.removeWhere((c) => c.id == client.id);
                      } else {
                        _selectedClients.add(client);
                      }
                    });
                  },
                  isHoverable: true,
                  semanticLabel: '${client.fullName} - ${isSelected ? "Selected" : "Not selected"}',
                  padding: const EdgeInsets.all(DesignTokens.space3),
                  child: Row(
                    children: [
                      Checkbox(
                        checked: isSelected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedClients.add(client);
                            } else {
                              _selectedClients.removeWhere((c) => c.id == client.id);
                            }
                          });
                        },
                      ),
                      const SizedBox(width: DesignTokens.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              client.fullName,
                              style: DesignTextStyles.body.copyWith(
                                fontWeight: DesignTokens.fontWeightMedium,
                              ),
                            ),
                            if (client.email != null) ...[
                              const SizedBox(height: DesignTokens.space1),
                              Text(
                                client.email!,
                                style: DesignTextStyles.caption.copyWith(
                                  color: DesignTokens.textSecondary,
                                ),
                              ),
                            ],
                            if (client.company != null) ...[
                              const SizedBox(height: DesignTokens.space1),
                              Text(
                                client.company!,
                                style: DesignTextStyles.caption.copyWith(
                                  color: DesignTokens.textTertiary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
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
              style: DesignTextStyles.subtitle,
            ),
            const SizedBox(height: DesignTokens.space2),
            Text(
              'Configure how your data should be exported.',
              style: DesignTextStyles.body.copyWith(
                color: DesignTokens.textSecondary,
              ),
            ),
            
            const SizedBox(height: DesignTokens.sectionSpacing),
            
            DesignSystemComponents.standardCard(
              semanticLabel: 'Export configuration options',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'File Name',
                    style: DesignTextStyles.body.copyWith(
                      fontWeight: DesignTokens.fontWeightMedium,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space2),
                  TextFormBox(
                    controller: _fileNameController,
                    placeholder: 'Enter file name (without extension)',
                  ),
                  
                  const SizedBox(height: DesignTokens.space4),
                  
                  Text(
                    'Export Format',
                    style: DesignTextStyles.body.copyWith(
                      fontWeight: DesignTokens.fontWeightMedium,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space2),
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
                  
                  const SizedBox(height: DesignTokens.space4),
                  
                  Row(
                    children: [
                      Checkbox(
                        checked: settings.includeHeaders,
                        onChanged: (value) {
                          ref.read(importExportSettingsProvider.notifier).updateIncludeHeaders(value ?? true);
                        },
                      ),
                      const SizedBox(width: DesignTokens.space2),
                      Text(
                        'Include column headers',
                        style: DesignTextStyles.body,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: DesignTokens.sectionSpacing),
            
            DesignSystemComponents.standardCard(
              semanticLabel: 'Export configuration preview',
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
                  _buildDetailRow('Clients to export', '${_selectedClients.length}'),
                  _buildDetailRow('Format', settings.format.name.toUpperCase()),
                  _buildDetailRow('Headers', settings.includeHeaders ? "Included" : "Not included"),
                  const SizedBox(height: DesignTokens.space3),
                  Text(
                    'Exported fields: First Name, Last Name, Email, Phone, Company, Job Title, Address, Notes, Created At, Updated At',
                    style: DesignTextStyles.caption.copyWith(
                      fontStyle: FontStyle.italic,
                      color: DesignTokens.textTertiary,
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space2),
      child: Row(
        children: [
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
              style: DesignTextStyles.body,
            ),
          ),
        ],
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
              style: DesignTextStyles.subtitle,
            ),
            const SizedBox(height: DesignTokens.space2),
            Text(
              'Review your export settings and start the export process.',
              style: DesignTextStyles.body.copyWith(
                color: DesignTokens.textSecondary,
              ),
            ),
            
            const SizedBox(height: DesignTokens.sectionSpacing),
            
            DesignSystemComponents.standardCard(
              semanticLabel: 'Export summary details',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Export Details',
                    style: DesignTextStyles.body.copyWith(
                      fontWeight: DesignTokens.fontWeightMedium,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space3),
                  _buildSummaryRow('File Name', _fileNameController.text.trim()),
                  _buildSummaryRow('Format', ref.read(importExportSettingsProvider).format.name.toUpperCase()),
                  _buildSummaryRow('Clients', '${_selectedClients.length}'),
                  _buildSummaryRow('Headers', ref.read(importExportSettingsProvider).includeHeaders ? 'Included' : 'Not included'),
                ],
              ),
            ),
            
            const SizedBox(height: DesignTokens.sectionSpacing),
            
            if (exportState.isLoading) ...[
              Text(
                'Export Progress',
                style: DesignTextStyles.body.copyWith(
                  fontWeight: DesignTokens.fontWeightMedium,
                ),
              ),
              const SizedBox(height: DesignTokens.space3),
              
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
                const SizedBox(height: DesignTokens.space2),
                ProgressBar(
                  value: exportState.progress!.progressPercentage * 100,
                ),
                const SizedBox(height: DesignTokens.space1),
                Text(
                  '${exportState.progress!.processedRecords} of ${exportState.progress!.totalRecords} records processed',
                  style: DesignTextStyles.caption,
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
            
            if (exportState.result != null) ...[
              DesignSystemComponents.standardCard(
                semanticLabel: 'Export result details',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          FluentIcons.completed,
                          size: DesignTokens.iconSizeSmall,
                          color: DesignTokens.semanticSuccess,
                        ),
                        const SizedBox(width: DesignTokens.space2),
                        Text(
                          'Export Completed',
                          style: DesignTextStyles.body.copyWith(
                            fontWeight: DesignTokens.fontWeightMedium,
                            color: DesignTokens.semanticSuccess,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.space3),
                    _buildDetailRow('Exported records', '${exportState.result!.totalRecords}'),
                    _buildDetailRow('File size', exportState.result!.fileSizeFormatted),
                    _buildDetailRow('Processing time', '${exportState.result!.processingTime.inSeconds}s'),
                    _buildDetailRow('File location', exportState.result!.filePath),
                  ],
                ),
              ),
            ],
            
            if (exportState.error != null)
              DesignSystemComponents.standardCard(
                semanticLabel: 'Export error details',
                child: Row(
                  children: [
                    Icon(
                      FluentIcons.error,
                      size: DesignTokens.iconSizeSmall,
                      color: DesignTokens.semanticError,
                    ),
                    const SizedBox(width: DesignTokens.space2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Export Failed',
                            style: DesignTextStyles.body.copyWith(
                              fontWeight: DesignTokens.fontWeightMedium,
                              color: DesignTokens.semanticError,
                            ),
                          ),
                          const SizedBox(height: DesignTokens.space1),
                          Text(
                            exportState.error!,
                            style: DesignTextStyles.caption.copyWith(
                              color: DesignTokens.semanticErrorDark,
                            ),
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
      padding: const EdgeInsets.only(bottom: DesignTokens.space2),
      child: Row(
        children: [
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
              style: DesignTextStyles.body,
            ),
          ),
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