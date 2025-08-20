import 'package:client_connect/src/features/import_export/data/import_export_model.dart';
import 'package:fluent_ui/fluent_ui.dart';
import '../../../core/design_system/design_tokens.dart';
import '../../../core/design_system/component_library.dart';

class ImportResultDialog extends StatelessWidget {
  final ImportResult result;
  
  const ImportResultDialog({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 750, maxHeight: 650),
      title: Text(
        'Import Results',
        style: DesignTextStyles.titleLarge,
      ),
      content: Column(
        children: [
          DesignSystemComponents.standardCard(
            semanticLabel: 'Import results summary',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      result.hasErrors ? FluentIcons.warning : FluentIcons.completed,
                      size: DesignTokens.iconSizeLarge,
                      color: result.hasErrors ? DesignTokens.semanticWarning : DesignTokens.semanticSuccess,
                    ),
                    const SizedBox(width: DesignTokens.space3),
                    Text(
                      'Import ${result.hasErrors ? "Completed with Warnings" : "Successful"}',
                      style: DesignTextStyles.subtitle.copyWith(
                        color: result.hasErrors ? DesignTokens.semanticWarning : DesignTokens.semanticSuccess,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space4),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Records',
                        result.totalRecords.toString(),
                        DesignTokens.semanticInfo,
                        FluentIcons.number_field,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.space3),
                    Expanded(
                      child: _buildStatCard(
                        'Successful',
                        result.successfulImports.toString(),
                        DesignTokens.semanticSuccess,
                        FluentIcons.completed,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.space3),
                    Expanded(
                      child: _buildStatCard(
                        'Failed',
                        result.failedImports.toString(),
                        DesignTokens.semanticError,
                        FluentIcons.error,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.space3),
                    Expanded(
                      child: _buildStatCard(
                        'Success Rate',
                        '${(result.successRate * 100).toInt()}%',
                        result.successRate > 0.8 ? DesignTokens.semanticSuccess : DesignTokens.semanticWarning,
                        FluentIcons.chart,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: DesignTokens.space3),
                Text(
                  'Processing time: ${result.processingTime.inSeconds} seconds',
                  style: DesignTextStyles.body.copyWith(
                    color: DesignTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: DesignTokens.sectionSpacing),
          
          if (result.hasErrors) ...[
            Row(
              children: [
                Icon(
                  FluentIcons.error,
                  size: DesignTokens.iconSizeMedium,
                  color: DesignTokens.semanticError,
                ),
                const SizedBox(width: DesignTokens.space2),
                Text(
                  'Import Errors (${result.errors.length})',
                  style: DesignTextStyles.subtitle,
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.space3),
            
            Expanded(
              child: DesignSystemComponents.standardCard(
                semanticLabel: 'Import error details list',
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(DesignTokens.space3),
                      decoration: BoxDecoration(
                        color: DesignTokens.textSecondary,
                        border: Border(
                          bottom: BorderSide(
                            color: DesignTokens.borderSecondary,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 60,
                            child: Text(
                              'Row',
                              style: DesignTextStyles.caption.copyWith(
                                fontWeight: DesignTokens.fontWeightMedium,
                                color: DesignTokens.textSecondary,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Text(
                              'Field',
                              style: DesignTextStyles.caption.copyWith(
                                fontWeight: DesignTokens.fontWeightMedium,
                                color: DesignTokens.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Value',
                              style: DesignTextStyles.caption.copyWith(
                                fontWeight: DesignTokens.fontWeightMedium,
                                color: DesignTokens.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Error Message',
                              style: DesignTextStyles.caption.copyWith(
                                fontWeight: DesignTokens.fontWeightMedium,
                                color: DesignTokens.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: result.errors.length,
                        itemBuilder: (context, index) {
                          final error = result.errors[index];
                          return _buildErrorItem(error);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: DesignSystemComponents.standardCard(
                semanticLabel: 'Import success confirmation',
                child: Center(
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
                        'All records imported successfully!',
                        style: DesignTextStyles.subtitle.copyWith(
                          color: DesignTokens.semanticSuccess,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.space2),
                      Text(
                        'No errors occurred during the import process.',
                        style: DesignTextStyles.body.copyWith(
                          color: DesignTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        DesignSystemComponents.secondaryButton(
          text: 'Close',
          onPressed: () => Navigator.of(context).pop(),
          semanticLabel: 'Close import results dialog',
        ),
        if (result.hasErrors)
          DesignSystemComponents.primaryButton(
            text: 'Export Error Report',
            icon: FluentIcons.download,
            onPressed: () => _exportErrorReport(context, result),
            semanticLabel: 'Export detailed error report',
          ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return DesignSystemComponents.standardCard(
      semanticLabel: '$label: $value',
      padding: const EdgeInsets.all(DesignTokens.space3),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: DesignTokens.iconSizeSmall,
                color: color,
              ),
              const SizedBox(width: DesignTokens.space1),
              Text(
                value,
                style: DesignTextStyles.title.copyWith(
                  color: color,
                  fontWeight: DesignTokens.fontWeightBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space2),
          Text(
            label,
            style: DesignTextStyles.caption.copyWith(
              color: DesignTokens.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorItem(ImportError error) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space3),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: DesignTokens.borderSecondary,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: DesignSystemComponents.statusBadge(
              text: '${error.rowNumber}',
              type: SemanticColorType.info,
            ),
          ),
          const SizedBox(width: DesignTokens.space3),
          SizedBox(
            width: 80,
            child: Text(
              error.field,
              style: DesignTextStyles.caption.copyWith(
                fontWeight: DesignTokens.fontWeightMedium,
                color: DesignTokens.semanticInfo,
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.space3),
          Expanded(
            flex: 2,
            child: Text(
              error.value.isEmpty ? '[Empty]' : error.value,
              style: DesignTextStyles.caption.copyWith(
                color: error.value.isEmpty ? DesignTokens.textTertiary : DesignTokens.textSecondary,
                fontStyle: error.value.isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.space3),
          Expanded(
            flex: 3,
            child: Text(
              error.errorMessage,
              style: DesignTextStyles.caption.copyWith(
                color: DesignTokens.semanticError,
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