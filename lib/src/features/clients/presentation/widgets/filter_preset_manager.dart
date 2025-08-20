import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/client_filter_preset_model.dart';
import '../../logic/client_filter_preset_providers.dart';

class FilterPresetManager extends ConsumerStatefulWidget {
  final String? currentSearchTerm;
  final List<String> currentTags;
  final String? currentCompany;
  final String? currentJobTitle; // Added currentJobTitle parameter
  final DateTimeRange? currentDateRange;
  final String currentSortBy;
  final bool currentSortAscending;
  final Function(ClientFilterPreset) onPresetSelected;

  const FilterPresetManager({
    super.key,
    this.currentSearchTerm,
    this.currentTags = const [],
    this.currentCompany,
    this.currentJobTitle, // Added currentJobTitle parameter
    this.currentDateRange,
    this.currentSortBy = 'name',
    this.currentSortAscending = true,
    required this.onPresetSelected,
  });

  @override
  ConsumerState<FilterPresetManager> createState() => _FilterPresetManagerState();
}

class _FilterPresetManagerState extends ConsumerState<FilterPresetManager> {
  final TextEditingController _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final presetsAsync = ref.watch(clientFilterPresetsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with save current filters button
          Row(
            children: [
              Expanded(
                child: Text(
                  'Filter Presets',
                  style: theme.typography.bodyStrong,
                ),
              ),
              Button(
                onPressed: _hasCurrentFilters() ? () => _showSavePresetDialog() : null,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.save, size: 14),
                    SizedBox(width: 4),
                    Text('Save Current'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Presets list with constrained height
          SizedBox(
            height: 200, // Fixed height to avoid unbounded constraints
            child: presetsAsync.when(
              data: (presets) => _buildPresetsList(presets, theme),
              loading: () => const Center(child: ProgressRing()),
              error: (error, stack) => _buildErrorState(error.toString(), theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsList(List<ClientFilterPreset> presets, FluentThemeData theme) {
    if (presets.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: presets.length,
      itemBuilder: (context, index) {
        final preset = presets[index];
        return _buildPresetCard(preset, theme);
      },
    );
  }

  Widget _buildPresetCard(ClientFilterPreset preset, FluentThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preset name and actions
              Row(
                children: [
                  Expanded(
                    child: Text(
                      preset.name,
                      style: theme.typography.bodyStrong,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(FluentIcons.delete, size: 14),
                    onPressed: () => _deletePreset(preset.id),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Preset details
              _buildPresetDetails(preset, theme),
              const SizedBox(height: 8),

              // Apply button
              SizedBox(
                width: double.infinity,
                child: Button(
                  onPressed: () => widget.onPresetSelected(preset),
                  child: const Text('Apply Preset'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetDetails(ClientFilterPreset preset, FluentThemeData theme) {
    final details = <String>[];
    
    if (preset.searchTerm?.isNotEmpty == true) {
      details.add('Search: "${preset.searchTerm}"');
    }
    if (preset.tags.isNotEmpty) {
      details.add('Tags: ${preset.tags.length}');
    }
    if (preset.company?.isNotEmpty == true) {
      details.add('Company: ${preset.company}');
    }
    if (preset.jobTitle?.isNotEmpty == true) { // Added job title to preset details
      details.add('Job Title: ${preset.jobTitle}');
    }
    if (preset.dateRange != null) {
      details.add('Date Range');
    }
    details.add('Sort: ${preset.sortBy} ${preset.sortAscending ? '↑' : '↓'}');

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: details.map((detail) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: theme.resources.cardBackgroundFillColorSecondary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          detail,
          style: TextStyle(
            fontSize: 11,
            color: theme.resources.textFillColorSecondary,
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildEmptyState(FluentThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.filter,
            size: 48,
            color: theme.resources.textFillColorSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            'No saved presets',
            style: theme.typography.subtitle?.copyWith(
              color: theme.resources.textFillColorSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Save your current filters to create presets',
            style: theme.typography.body?.copyWith(
              color: theme.resources.textFillColorTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, FluentThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.error,
            size: 48,
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          Text(
            'Error loading presets',
            style: theme.typography.subtitle,
          ),
          const SizedBox(height: 4),
          Text(
            error,
            style: theme.typography.body?.copyWith(
              color: theme.resources.textFillColorSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showSavePresetDialog() {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Save Filter Preset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter a name for this filter preset:'),
            const SizedBox(height: 8),
            TextBox(
              controller: _nameController,
              placeholder: 'Preset name',
              autofocus: true,
            ),
          ],
        ),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () {
              _nameController.clear();
              Navigator.of(context).pop();
            },
          ),
          FilledButton(
            onPressed: _isSaving ? null : () => _saveCurrentPreset(),
            child: _isSaving 
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: ProgressRing(),
                    ),
                    SizedBox(width: 8),
                    Text('Saving...'),
                  ],
                )
              : const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCurrentPreset() async {
    if (_nameController.text.trim().isEmpty || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    final preset = ClientFilterPreset(
      id: 0, // New preset
      name: _nameController.text.trim(),
      searchTerm: widget.currentSearchTerm,
      tags: widget.currentTags,
      company: widget.currentCompany,
      jobTitle: widget.currentJobTitle, // Include current job title in preset
      dateRange: widget.currentDateRange,
      sortBy: widget.currentSortBy,
      sortAscending: widget.currentSortAscending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await ref.read(clientFilterPresetNotifierProvider.notifier).savePreset(preset);
      
      if (mounted) {
        // Clear the text field and reset saving state
        _nameController.clear();
        setState(() {
          _isSaving = false;
        });
        
        // Close dialog first and wait for it to complete
        Navigator.of(context).pop();
        
        // Refresh presets list
        ref.invalidate(clientFilterPresetsProvider);
        
        // Show success message using a post-frame callback to ensure dialog is fully closed
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            displayInfoBar(
              context,
              builder: (context, close) => InfoBar(
                title: const Text('Success'),
                content: const Text('Filter preset saved successfully'),
                severity: InfoBarSeverity.success,
                onClose: close,
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        
        // Close dialog first and wait for it to complete
        Navigator.of(context).pop();
        
        // Show error message using a post-frame callback
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            displayInfoBar(
              context,
              builder: (context, close) => InfoBar(
                title: const Text('Error'),
                content: Text('Failed to save preset: $e'),
                severity: InfoBarSeverity.error,
                onClose: close,
              ),
            );
          }
        });
      }
    }
  }

  Future<void> _deletePreset(int presetId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Delete Preset'),
        content: const Text('Are you sure you want to delete this filter preset?'),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          FilledButton(
            child: const Text('Delete'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(clientFilterPresetNotifierProvider.notifier).deletePreset(presetId);
        
        if (mounted) {
          // Refresh presets list
          ref.invalidate(clientFilterPresetsProvider);
          
          // Show success message using post-frame callback
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              displayInfoBar(
                context,
                builder: (context, close) => InfoBar(
                  title: const Text('Success'),
                  content: const Text('Filter preset deleted successfully'),
                  severity: InfoBarSeverity.success,
                  onClose: close,
                ),
              );
            }
          });
        }
      } catch (e) {
        if (mounted) {
          // Show error message using post-frame callback
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              displayInfoBar(
                context,
                builder: (context, close) => InfoBar(
                  title: const Text('Error'),
                  content: Text('Failed to delete preset: $e'),
                  severity: InfoBarSeverity.error,
                  onClose: close,
                ),
              );
            }
          });
        }
      }
    }
  }

  bool _hasCurrentFilters() {
    return widget.currentSearchTerm?.isNotEmpty == true ||
           widget.currentTags.isNotEmpty ||
           widget.currentCompany?.isNotEmpty == true ||
           widget.currentJobTitle?.isNotEmpty == true || // Include job title in filter check
           widget.currentDateRange != null;
  }
}