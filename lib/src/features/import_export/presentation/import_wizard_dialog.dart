import 'package:client_connect/src/features/clients/logic/client_providers.dart';
import 'package:client_connect/src/features/import_export/data/import_export_model.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/design_tokens.dart';
import '../../../core/design_system/component_library.dart';
import '../logic/import_export_providers.dart';
import '../data/import_export_service.dart';
import 'dart:io';

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
      constraints: const BoxConstraints(maxWidth: 700, maxHeight: 750),
      title: Text(
        'Import Clients',
        style: DesignTextStyles.titleLarge,
      ),
      content: Column(
        children: [
          DesignSystemComponents.standardCard(
            semanticLabel: 'Import wizard progress steps',
            padding: const EdgeInsets.all(DesignTokens.space4),
            child: Row(
              children: [
                _buildStepIndicator(0, 'Select File', _currentStep >= 0),
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
                _buildStepIndicator(2, 'Import', _currentStep >= 2),
              ],
            ),
          ),
          
          const SizedBox(height: DesignTokens.sectionSpacing),
          
          // Step content
          Expanded(
            child: _buildStepContent(settings, importState),
          ),
        ],
      ),
      actions: [
        DesignSystemComponents.secondaryButton(
          text: 'Cancel',
          onPressed: () {
            ref.read(importStateProvider.notifier).reset();
            Navigator.of(context).pop();
          },
          semanticLabel: 'Cancel import process',
        ),
        if (_currentStep > 0 && !importState.isLoading)
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
        if (_currentStep == 2 && _selectedFilePath != null && !importState.isLoading)
          DesignSystemComponents.primaryButton(
            text: 'Start Import',
            icon: FluentIcons.download,
            onPressed: () => _startImport(settings),
            semanticLabel: 'Begin importing clients',
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
              style: DesignTextStyles.subtitle,
            ),
            const SizedBox(height: DesignTokens.space2),
            Text(
              'Choose a CSV, JSON, or Excel file containing your client data.',
              style: DesignTextStyles.body.copyWith(
                color: DesignTokens.textSecondary,
              ),
            ),
            
            const SizedBox(height: DesignTokens.sectionSpacing),
            
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedFilePath != null 
                      ? DesignTokens.semanticSuccess 
                      : DesignTokens.borderSecondary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                color: _selectedFilePath != null 
                    ? DesignTokens.withOpacity(DesignTokens.semanticSuccess, 0.05)
                    : DesignTokens.withOpacity(DesignTokens.semanticInfo, 0.05),
              ),
              child: _selectedFilePath != null
                  ? _buildSelectedFileInfo()
                  : _buildFileDropArea(),
            ),
            
            const SizedBox(height: DesignTokens.space4),
            
            Row(
              children: [
                DesignSystemComponents.primaryButton(
                  text: 'Browse Files',
                  icon: FluentIcons.folder_open,
                  onPressed: _selectFile,
                  semanticLabel: 'Browse and select import file',
                ),
                const SizedBox(width: DesignTokens.space3),
                if (_selectedFilePath != null)
                  DesignSystemComponents.secondaryButton(
                    text: 'Clear Selection',
                    icon: FluentIcons.clear,
                    onPressed: () => setState(() {
                      _selectedFilePath = null;
                      _selectedFileName = null;
                    }),
                    semanticLabel: 'Clear selected file',
                  ),
              ],
            ),
            
            const SizedBox(height: DesignTokens.sectionSpacing),
            
            DesignSystemComponents.standardCard(
              semanticLabel: 'Supported file formats information',
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
                        'Supported File Formats',
                        style: DesignTextStyles.body.copyWith(
                          fontWeight: DesignTokens.fontWeightMedium,
                          color: DesignTokens.semanticInfo,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.space3),
                  _buildFormatItem('CSV (.csv)', 'Comma-separated values'),
                  _buildFormatItem('JSON (.json)', 'JavaScript Object Notation'),
                  _buildFormatItem('Excel (.xlsx)', 'Microsoft Excel format'),
                  const SizedBox(height: DesignTokens.space3),
                  Text(
                    'Maximum file size: 50MB',
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

  Widget _buildFormatItem(String format, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space2),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: DesignTokens.semanticInfo,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: DesignTokens.space2),
          Text(
            format,
            style: DesignTextStyles.body.copyWith(
              fontWeight: DesignTokens.fontWeightMedium,
            ),
          ),
          const SizedBox(width: DesignTokens.space2),
          Text(
            '- $description',
            style: DesignTextStyles.body.copyWith(
              color: DesignTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedFileInfo() {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.space4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.completed,
            size: DesignTokens.iconSizeXLarge,
            color: DesignTokens.semanticSuccess,
          ),
          const SizedBox(height: DesignTokens.space4),
          Text(
            'File Selected',
            style: DesignTextStyles.subtitle.copyWith(
              color: DesignTokens.semanticSuccess,
            ),
          ),
          const SizedBox(height: DesignTokens.space2),
          Text(
            _selectedFileName ?? 'Unknown file',
            style: DesignTextStyles.body.copyWith(
              fontWeight: DesignTokens.fontWeightMedium,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.space1),
          Text(
            _selectedFilePath ?? '',
            style: DesignTextStyles.caption.copyWith(
              color: DesignTokens.textSecondary,
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
          size: DesignTokens.iconSizeXLarge,
          color: DesignTokens.textTertiary,
        ),
        const SizedBox(height: DesignTokens.space4),
        Text(
          'Select a file to import',
          style: DesignTextStyles.subtitle,
        ),
        const SizedBox(height: DesignTokens.space2),
        Text(
          'Click "Browse Files" to select your import file',
          style: DesignTextStyles.body.copyWith(
            color: DesignTokens.textSecondary,
          ),
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
              style: DesignTextStyles.subtitle,
            ),
            const SizedBox(height: DesignTokens.space2),
            Text(
              'Configure how your data should be imported.',
              style: DesignTextStyles.body.copyWith(
                color: DesignTokens.textSecondary,
              ),
            ),
            
            const SizedBox(height: DesignTokens.sectionSpacing),
            
            DesignSystemComponents.standardCard(
              semanticLabel: 'Import configuration options',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'File Format',
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
                  
                  if (settings.format == ImportExportFormat.csv) ...[
                    const SizedBox(height: DesignTokens.space4),
                    Text(
                      'CSV Delimiter',
                      style: DesignTextStyles.body.copyWith(
                        fontWeight: DesignTokens.fontWeightMedium,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space2),
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
                  ],
                  
                  const SizedBox(height: DesignTokens.sectionSpacing),
                  
                  _buildCheckboxOption(
                    'File includes header row',
                    settings.includeHeaders,
                    (value) => ref.read(importExportSettingsProvider.notifier).updateIncludeHeaders(value ?? true),
                  ),
                  _buildCheckboxOption(
                    'Skip empty rows',
                    settings.skipEmptyRows,
                    (value) => ref.read(importExportSettingsProvider.notifier).updateSkipEmptyRows(value ?? true),
                  ),
                  _buildCheckboxOption(
                    'Validate email addresses',
                    settings.validateEmails,
                    (value) => ref.read(importExportSettingsProvider.notifier).updateValidateEmails(value ?? true),
                  ),
                  _buildCheckboxOption(
                    'Allow duplicate clients',
                    settings.allowDuplicates,
                    (value) => ref.read(importExportSettingsProvider.notifier).updateAllowDuplicates(value ?? false),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: DesignTokens.sectionSpacing),
            
            DesignSystemComponents.standardCard(
              semanticLabel: 'Expected column headers information',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        FluentIcons.info,
                        size: DesignTokens.iconSizeSmall,
                        color: DesignTokens.semanticWarning,
                      ),
                      const SizedBox(width: DesignTokens.space2),
                      Text(
                        'Expected Column Headers',
                        style: DesignTextStyles.body.copyWith(
                          fontWeight: DesignTokens.fontWeightMedium,
                          color: DesignTokens.semanticWarning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.space3),
                  Text(
                    'Required: First Name, Last Name',
                    style: DesignTextStyles.body.copyWith(
                      fontWeight: DesignTokens.fontWeightMedium,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space1),
                  Text(
                    'Optional: Email, Phone, Company, Job Title, Address, Notes',
                    style: DesignTextStyles.body,
                  ),
                  const SizedBox(height: DesignTokens.space3),
                  Text(
                    'Column names are case-insensitive and spaces/underscores are ignored.',
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

  Widget _buildCheckboxOption(String label, bool value, Function(bool?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space3),
      child: Row(
        children: [
          Checkbox(
            checked: value,
            onChanged: onChanged,
          ),
          const SizedBox(width: DesignTokens.space2),
          Expanded(
            child: Text(
              label,
              style: DesignTextStyles.body,
            ),
          ),
        ],
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
              style: DesignTextStyles.subtitle,
            ),
            const SizedBox(height: DesignTokens.space2),
            Text(
              'Review your import settings and start the import process.',
              style: DesignTextStyles.body.copyWith(
                color: DesignTokens.textSecondary,
              ),
            ),
            
            const SizedBox(height: DesignTokens.sectionSpacing),
            
            DesignSystemComponents.standardCard(
              semanticLabel: 'Import configuration summary',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Import Details',
                    style: DesignTextStyles.body.copyWith(
                      fontWeight: DesignTokens.fontWeightMedium,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space3),
                  _buildSummaryRow('File', _selectedFileName ?? 'Unknown'),
                  _buildSummaryRow('Format', ref.read(importExportSettingsProvider).format.name.toUpperCase()),
                  _buildSummaryRow('Headers', ref.read(importExportSettingsProvider).includeHeaders ? 'Included' : 'Not included'),
                  _buildSummaryRow('Validation', ref.read(importExportSettingsProvider).validateEmails ? 'Enabled' : 'Disabled'),
                  _buildSummaryRow('Duplicates', ref.read(importExportSettingsProvider).allowDuplicates ? 'Allowed' : 'Skip'),
                ],
              ),
            ),
            
            const SizedBox(height: DesignTokens.sectionSpacing),
            
            if (importState.isLoading) ...[
              DesignSystemComponents.standardCard(
                semanticLabel: 'Import progress information',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Import Progress',
                      style: DesignTextStyles.body.copyWith(
                        fontWeight: DesignTokens.fontWeightMedium,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space3),
                    
                    if (importState.progress != null) ...[
                      Row(
                        children: [
                          SizedBox(
                            width: DesignTokens.iconSizeSmall,
                            height: DesignTokens.iconSizeSmall,
                            child: const ProgressRing(strokeWidth: 2),
                          ),
                          const SizedBox(width: DesignTokens.space2),
                          Text(
                            importState.progress!.currentOperation,
                            style: DesignTextStyles.body,
                          ),
                        ],
                      ),
                      const SizedBox(height: DesignTokens.space2),
                      ProgressBar(
                        value: importState.progress!.progressPercentage * 100,
                      ),
                      const SizedBox(height: DesignTokens.space1),
                      Text(
                        '${importState.progress!.processedRecords} of ${importState.progress!.totalRecords} records processed',
                        style: DesignTextStyles.caption,
                      ),
                    ] else ...[
                      DesignSystemComponents.loadingIndicator(
                        message: 'Preparing import...',
                        size: DesignTokens.iconSizeSmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
            
            if (importState.result != null) ...[
              DesignSystemComponents.standardCard(
                semanticLabel: 'Import completion results',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          importState.result!.hasErrors 
                              ? FluentIcons.warning 
                              : FluentIcons.completed,
                          size: DesignTokens.iconSizeMedium,
                          color: importState.result!.hasErrors 
                              ? DesignTokens.semanticWarning 
                              : DesignTokens.semanticSuccess,
                        ),
                        const SizedBox(width: DesignTokens.space2),
                        Text(
                          'Import Completed',
                          style: DesignTextStyles.body.copyWith(
                            fontWeight: DesignTokens.fontWeightMedium,
                            color: importState.result!.hasErrors 
                                ? DesignTokens.semanticWarning 
                                : DesignTokens.semanticSuccess,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.space3),
                    _buildSummaryRow('Total records', '${importState.result!.totalRecords}'),
                    _buildSummaryRow('Successful', '${importState.result!.successfulImports}'),
                    _buildSummaryRow('Failed', '${importState.result!.failedImports}'),
                    _buildSummaryRow('Processing time', '${importState.result!.processingTime.inSeconds}s'),
                    if (importState.result!.hasErrors) ...[
                      const SizedBox(height: DesignTokens.space2),
                      Text(
                        '${importState.result!.errors.length} errors occurred during import.',
                        style: DesignTextStyles.body.copyWith(
                          color: DesignTokens.semanticWarning,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            
            if (importState.error != null)
              DesignSystemComponents.standardCard(
                semanticLabel: 'Import error information',
                child: Row(
                  children: [
                    Icon(
                      FluentIcons.error,
                      size: DesignTokens.iconSizeMedium,
                      color: DesignTokens.semanticError,
                    ),
                    const SizedBox(width: DesignTokens.space2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Import Failed',
                            style: DesignTextStyles.body.copyWith(
                              fontWeight: DesignTokens.fontWeightMedium,
                              color: DesignTokens.semanticError,
                            ),
                          ),
                          const SizedBox(height: DesignTokens.space1),
                          Text(
                            importState.error!,
                            style: DesignTextStyles.body.copyWith(
                              color: DesignTokens.semanticError,
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
            width: 100,
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
        return _selectedFilePath != null;
      case 1:
        return true; // Configuration is always valid
      default:
        return false;
    }
  }

  void _selectFile() async {
    try {
      final filePath = await ImportExportService.instance.pickImportFile();
      if (filePath != null) {
        // Validate file size (max 50MB)
        final file = File(filePath);
        final fileSize = await file.length();
        const maxSize = 50 * 1024 * 1024; // 50MB
        
        if (fileSize > maxSize) {
          if (mounted) {
            displayInfoBar(
              context,
              builder: (context, close) => InfoBar(
                title: const Text('File Too Large'),
                content: Text('Selected file is ${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB. Maximum allowed size is 50MB.'),
                severity: InfoBarSeverity.error,
                onClose: close,
              ),
            );
          }
          return;
        }
        
        // Validate file extension
        final extension = filePath.split('.').last.toLowerCase();
        if (!['csv', 'json', 'xlsx'].contains(extension)) {
          if (mounted) {
            displayInfoBar(
              context,
              builder: (context, close) => InfoBar(
                title: const Text('Unsupported File Type'),
                content: Text('File type ".$extension" is not supported. Please select a CSV, JSON, or Excel file.'),
                severity: InfoBarSeverity.error,
                onClose: close,
              ),
            );
          }
          return;
        }
        
        setState(() {
          _selectedFilePath = filePath;
          _selectedFileName = filePath.split('/').last;
        });
        
        // Show success message
        if (mounted) {
          displayInfoBar(
            context,
            builder: (context, close) => InfoBar(
              title: const Text('File Selected'),
              content: Text('Selected: $_selectedFileName'),
              severity: InfoBarSeverity.success,
              onClose: close,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('File Selection Error'),
            content: Text('Failed to select file: $e'),
            severity: InfoBarSeverity.error,
            onClose: close,
          ),
        );
      }
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