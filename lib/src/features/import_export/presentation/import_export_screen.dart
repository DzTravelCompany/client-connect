import 'package:client_connect/src/features/clients/data/client_model.dart';
import 'package:client_connect/src/features/import_export/data/import_export_model.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/design_tokens.dart';
import '../../../core/design_system/component_library.dart';
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
        title: Text(
          'Import & Export',
          style: DesignTextStyles.titleLarge,
        ),
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
          padding: const EdgeInsets.all(DesignTokens.pageMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(context),
              
              const SizedBox(height: DesignTokens.sectionSpacing),
        
              _buildActionCards(context, importState, exportState, clientsAsync),
        
              const SizedBox(height: DesignTokens.sectionSpacing),
        
              _buildRecentOperations(context, importState, exportState),
        
              const SizedBox(height: DesignTokens.sectionSpacing),
        
              _buildHelpSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Client Data Management',
          style: DesignTextStyles.display,
        ),
        const SizedBox(height: DesignTokens.space2),
        Text(
          'Import clients from external files or export your client database for backup and sharing.',
          style: DesignTextStyles.bodyLarge.copyWith(
            color: DesignTokens.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCards(BuildContext context, ImportState importState, ExportState exportState, AsyncValue clientsAsync) {
    return Row(
      children: [
        // Import card
        Expanded(
          child: _buildImportCard(context, importState),
        ),
        const SizedBox(width: DesignTokens.sectionSpacing),
        // Export card
        Expanded(
          child: _buildExportCard(context, exportState, clientsAsync),
        ),
      ],
    );
  }

  Widget _buildImportCard(BuildContext context, ImportState importState) {
    return DesignSystemComponents.glassmorphismCard(
      semanticLabel: 'Import clients from external files',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: DesignTokens.iconSizeXLarge + DesignTokens.space4,
                height: DesignTokens.iconSizeXLarge + DesignTokens.space4,
                decoration: BoxDecoration(
                  color: DesignTokens.withOpacity(DesignTokens.semanticInfo, 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                ),
                child: Icon(
                  FluentIcons.download,
                  color: DesignTokens.semanticInfo,
                  size: DesignTokens.iconSizeLarge,
                ),
              ),
              const SizedBox(width: DesignTokens.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Import Clients',
                      style: DesignTextStyles.subtitle,
                    ),
                    const SizedBox(height: DesignTokens.space1),
                    Text(
                      'Add clients from CSV, Excel, or JSON files',
                      style: DesignTextStyles.body.copyWith(
                        color: DesignTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.sectionSpacing),

          if (importState.isLoading && importState.progress != null)
            _buildProgressSection(importState.progress!),

          if (importState.result != null)
            _buildImportResultSummary(importState.result!),

          if (importState.error != null)
            _buildErrorMessage(importState.error!),

          Row(
            children: [
              DesignSystemComponents.primaryButton(
                text: 'Import Clients',
                icon: FluentIcons.download,
                onPressed: importState.isLoading ? null : () => _showImportWizard(context),
                isLoading: importState.isLoading,
                semanticLabel: 'Start client import process',
              ),
              const SizedBox(width: DesignTokens.space3),
              if (importState.result != null)
                DesignSystemComponents.secondaryButton(
                  text: 'View Last Result',
                  icon: FluentIcons.view,
                  onPressed: () => _showImportResult(context, importState.result!),
                  semanticLabel: 'View details of last import operation',
                ),
            ],
          ),

          const SizedBox(height: DesignTokens.space4),

          Text(
            'Supported formats: CSV, JSON, Excel (XLSX)',
            style: DesignTextStyles.caption.copyWith(
              color: DesignTokens.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportCard(BuildContext context, ExportState exportState, AsyncValue clientsAsync) {
    return DesignSystemComponents.glassmorphismCard(
      semanticLabel: 'Export client database to external files',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: DesignTokens.iconSizeXLarge + DesignTokens.space4,
                height: DesignTokens.iconSizeXLarge + DesignTokens.space4,
                decoration: BoxDecoration(
                  color: DesignTokens.withOpacity(DesignTokens.semanticSuccess, 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                ),
                child: Icon(
                  FluentIcons.upload,
                  color: DesignTokens.semanticSuccess,
                  size: DesignTokens.iconSizeLarge,
                ),
              ),
              const SizedBox(width: DesignTokens.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export Clients',
                      style: DesignTextStyles.subtitle,
                    ),
                    const SizedBox(height: DesignTokens.space1),
                    Text(
                      'Save your client database to CSV or JSON',
                      style: DesignTextStyles.body.copyWith(
                        color: DesignTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.sectionSpacing),

          if (exportState.isLoading && exportState.progress != null)
            _buildProgressSection(exportState.progress!),

          if (exportState.result != null)
            _buildExportResultSummary(exportState.result!),

          if (exportState.error != null)
            _buildErrorMessage(exportState.error!),

          clientsAsync.when(
            data: (clients) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DesignSystemComponents.primaryButton(
                      text: 'Export Clients',
                      icon: FluentIcons.upload,
                      onPressed: (exportState.isLoading || clients.isEmpty) 
                          ? null 
                          : () => _showExportWizard(context, clients),
                      isLoading: exportState.isLoading,
                      semanticLabel: 'Start client export process',
                    ),
                    const SizedBox(width: DesignTokens.space3),
                    if (exportState.result != null)
                      DesignSystemComponents.secondaryButton(
                        text: 'View Last Result',
                        icon: FluentIcons.view,
                        onPressed: () => _showExportResult(context, exportState.result!),
                        semanticLabel: 'View details of last export operation',
                      ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space4),
                DesignSystemComponents.statusBadge(
                  text: clients.isEmpty 
                      ? 'No clients to export'
                      : '${clients.length} clients available',
                  type: clients.isEmpty ? SemanticColorType.warning : SemanticColorType.info,
                  icon: FluentIcons.people,
                  semanticLabel: clients.isEmpty 
                      ? 'No clients available for export'
                      : '${clients.length} clients ready for export',
                ),
              ],
            ),
            loading: () => DesignSystemComponents.loadingIndicator(
              message: 'Loading clients...',
              size: DesignTokens.iconSizeMedium,
            ),
            error: (error, stack) => _buildErrorMessage('Error loading clients: $error'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(dynamic progress) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: DesignTokens.iconSizeSmall,
                height: DesignTokens.iconSizeSmall,
                child: const ProgressRing(strokeWidth: 2),
              ),
              const SizedBox(width: DesignTokens.space2),
              Text(
                progress.currentOperation,
                style: DesignTextStyles.body.copyWith(
                  fontWeight: DesignTokens.fontWeightMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space2),
          ProgressBar(
            value: progress.progressPercentage * 100,
          ),
          const SizedBox(height: DesignTokens.space1),
          Text(
            '${progress.processedRecords} of ${progress.totalRecords} records processed',
            style: DesignTextStyles.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildImportResultSummary(ImportResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DesignSystemComponents.statusBadge(
                text: result.hasErrors ? 'Completed with errors' : 'Import successful',
                type: result.hasErrors ? SemanticColorType.warning : SemanticColorType.success,
                icon: result.hasErrors ? FluentIcons.warning : FluentIcons.completed,
              ),
              const Spacer(),
              Text(
                '${result.successfulImports} successful, ${result.failedImports} failed',
                style: DesignTextStyles.caption.copyWith(
                  fontWeight: DesignTokens.fontWeightMedium,
                ),
              ),
            ],
          ),
          if (result.hasErrors) ...[
            const SizedBox(height: DesignTokens.space3),
            DesignSystemComponents.secondaryButton(
              text: 'View Error Details',
              icon: FluentIcons.error,
              onPressed: () => _showImportResult(context, result),
              semanticLabel: 'View detailed error information',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExportResultSummary(ExportResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DesignSystemComponents.statusBadge(
                text: 'Export successful',
                type: SemanticColorType.success,
                icon: FluentIcons.completed,
              ),
              const Spacer(),
              Text(
                '${result.totalRecords} clients',
                style: DesignTextStyles.caption.copyWith(
                  fontWeight: DesignTokens.fontWeightMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space2),
          Text(
            'File size: ${result.fileSizeFormatted}',
            style: DesignTextStyles.caption,
          ),
          const SizedBox(height: DesignTokens.space3),
          DesignSystemComponents.secondaryButton(
            text: 'View Export Details',
            icon: FluentIcons.view,
            onPressed: () => _showExportResult(context, result),
            semanticLabel: 'View detailed export information',
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.space3),
      margin: const EdgeInsets.only(bottom: DesignTokens.space4),
      decoration: BoxDecoration(
        color: DesignTokens.withOpacity(DesignTokens.semanticError, 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.withOpacity(DesignTokens.semanticError, 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            FluentIcons.error,
            size: DesignTokens.iconSizeSmall,
            color: DesignTokens.semanticError,
          ),
          const SizedBox(width: DesignTokens.space2),
          Expanded(
            child: Text(
              error,
              style: DesignTextStyles.body.copyWith(
                color: DesignTokens.semanticError,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOperations(BuildContext context, ImportState importState, ExportState exportState) {
    final hasRecentOperations = importState.result != null || exportState.result != null;
    
    if (!hasRecentOperations) {
      return const SizedBox.shrink();
    }

    return DesignSystemComponents.standardCard(
      semanticLabel: 'Recent import and export operations',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Operations',
            style: DesignTextStyles.subtitle,
          ),
          const SizedBox(height: DesignTokens.space4),
          
          if (importState.result != null)
            _buildOperationSummary(
              'Import',
              FluentIcons.download,
              DesignTokens.semanticInfo,
              '${importState.result!.successfulImports} clients imported',
              'Processing time: ${importState.result!.processingTime.inSeconds}s',
              importState.result!.hasErrors ? 'With errors' : 'Successful',
              importState.result!.hasErrors ? DesignTokens.semanticWarning : DesignTokens.semanticSuccess,
              () => _showImportResult(context, importState.result!),
            ),
          
          if (importState.result != null && exportState.result != null)
            const SizedBox(height: DesignTokens.space3),
          
          if (exportState.result != null)
            _buildOperationSummary(
              'Export',
              FluentIcons.upload,
              DesignTokens.semanticSuccess,
              '${exportState.result!.totalRecords} clients exported',
              'File size: ${exportState.result!.fileSizeFormatted}',
              'Successful',
              DesignTokens.semanticSuccess,
              () => _showExportResult(context, exportState.result!),
            ),
        ],
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
    return DesignSystemComponents.standardCard(
      onTap: onTap,
      isHoverable: true,
      semanticLabel: '$operation operation: $primaryText, $status',
      padding: const EdgeInsets.all(DesignTokens.space3),
      child: Row(
        children: [
          Icon(icon, size: DesignTokens.iconSizeMedium, color: iconColor),
          const SizedBox(width: DesignTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primaryText,
                  style: DesignTextStyles.body.copyWith(
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
                ),
                const SizedBox(height: DesignTokens.space1),
                Text(
                  secondaryText,
                  style: DesignTextStyles.caption,
                ),
              ],
            ),
          ),
          DesignSystemComponents.statusBadge(
            text: status,
            type: statusColor == DesignTokens.semanticSuccess 
                ? SemanticColorType.success 
                : statusColor == DesignTokens.semanticWarning 
                    ? SemanticColorType.warning 
                    : SemanticColorType.info,
          ),
          const SizedBox(width: DesignTokens.space2),
          Icon(
            FluentIcons.chevron_right,
            size: DesignTokens.iconSizeSmall,
            color: DesignTokens.textTertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(BuildContext context) {
    return DesignSystemComponents.standardCard(
      semanticLabel: 'Import and export guidelines and help information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FluentIcons.info,
                size: DesignTokens.iconSizeMedium,
                color: DesignTokens.semanticInfo,
              ),
              const SizedBox(width: DesignTokens.space3),
              Text(
                'Import & Export Guidelines',
                style: DesignTextStyles.subtitle,
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space4),
          
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
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: DesignTokens.semanticInfo,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: DesignTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DesignTextStyles.body.copyWith(
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
                ),
                const SizedBox(height: DesignTokens.space1),
                Text(
                  description,
                  style: DesignTextStyles.caption.copyWith(
                    color: DesignTokens.textSecondary,
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