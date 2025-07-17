import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../tags/logic/tag_providers.dart';
import '../../../tags/data/tag_model.dart';
import '../../logic/client_providers.dart';
import 'advanced_date_range_picker.dart';
import 'filter_preset_manager.dart';

class ClientFilterPanel extends ConsumerStatefulWidget {
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final List<String> selectedTags;
  final String? selectedCompany;
  final DateTimeRange? dateRange;
  final Function({
    List<String>? tags,
    String? company,
    DateTimeRange? dateRange,
  }) onFilterChanged;
  final VoidCallback onClearFilters;

  const ClientFilterPanel({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.selectedTags,
    required this.selectedCompany,
    required this.dateRange,
    required this.onFilterChanged,
    required this.onClearFilters,
  });

  @override
  ConsumerState<ClientFilterPanel> createState() => _ClientFilterPanelState();
}

class _ClientFilterPanelState extends ConsumerState<ClientFilterPanel> {
  bool _isTagsExpanded = true;
  bool _isCompanyExpanded = true;
  bool _isDateExpanded = false;
  bool _isPresetExpanded = false;
  

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final tagsAsync = ref.watch(allTagsProvider);
    final companiesAsync = ref.watch(clientCompaniesProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Filters',
                  style: theme.typography.subtitle?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_hasActiveFilters())
                Button(
                  onPressed: widget.onClearFilters,
                  child: const Text('Clear All'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Search
          TextBox(
            controller: widget.searchController,
            placeholder: 'Search clients...',
            prefix: const Icon(FluentIcons.search),
            onChanged: widget.onSearchChanged,
            suffix: widget.searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(FluentIcons.clear),
                    onPressed: () {
                      widget.searchController.clear();
                      widget.onSearchChanged('');
                    },
                  )
                : null,
          ),
          const SizedBox(height: 20),
          // Filter Sections
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Tags Filter
                    _buildFilterSection(
                      title: 'Tags',
                      isExpanded: _isTagsExpanded,
                      onToggle: () => setState(() => _isTagsExpanded = !_isTagsExpanded),
                      child: tagsAsync.when(
                        data: (tags) => _buildTagsFilter(tags),
                        loading: () => const ProgressRing(),
                        error: (_, __) => const Text('Error loading tags'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Company Filter
                    _buildFilterSection(
                      title: 'Company',
                      isExpanded: _isCompanyExpanded,
                      onToggle: () => setState(() => _isCompanyExpanded = !_isCompanyExpanded),
                      child: companiesAsync.when(
                        data: (companies) => _buildCompanyFilter(companies),
                        loading: () => const ProgressRing(),
                        error: (_, __) => const Text('Error loading companies'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Date Range Filter
                    _buildFilterSection(
                      title: 'Date Added',
                      isExpanded: _isDateExpanded,
                      onToggle: () => setState(() => _isDateExpanded = !_isDateExpanded),
                      child: _buildDateRangeFilter(),
                    ),
                    const SizedBox(height: 16),
                    // Filter Presets
                    _buildFilterPresetsSection(),
                  ],
                ),
              ),
            ),
          ),
          // Active Filters Summary
          if (_hasActiveFilters()) ...[
            const Divider(),
            _buildActiveFiltersSummary(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    final theme = FluentTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.resources.dividerStrokeColorDefault.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  color: Colors.transparent,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.typography.bodyStrong,
                      ),
                    ),
                    Icon(
                      isExpanded ? FluentIcons.chevron_up : FluentIcons.chevron_down,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(style: DividerThemeData(thickness: 1)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: child,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTagsFilter(List<TagModel> tags) {
    // final theme = FluentTheme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tags.isEmpty)
          const Text('No tags available')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) {
              final isSelected = widget.selectedTags.contains(tag.name);
              return _buildFluentChip(
                label: tag.name,
                isSelected: isSelected,
                onTap: () {
                  final newTags = List<String>.from(widget.selectedTags);
                  if (isSelected) {
                    newTags.remove(tag.name);
                  } else {
                    newTags.add(tag.name);
                  }
                  widget.onFilterChanged(tags: newTags);
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildFluentChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = FluentTheme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.accentColor.withValues(alpha: 0.1)
                : theme.resources.cardBackgroundFillColorDefault,
            border: Border.all(
              color: isSelected
                  ? theme.accentColor
                  : theme.resources.dividerStrokeColorDefault.withValues(alpha: 0.5),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Icon(
                  FluentIcons.check_mark,
                  size: 12,
                  color: theme.accentColor,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? theme.accentColor
                      : theme.resources.textFillColorPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyFilter(List<String> companies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (companies.isEmpty)
          const Text('No companies found')
        else
          Column(
            children: companies.take(10).map((company) {
              final isSelected = widget.selectedCompany == company;
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 4),
                child: RadioButton(
                  checked: isSelected,
                  onChanged: (checked) {
                    widget.onFilterChanged(
                      company: checked == true ? company : null,
                    );
                  },
                  content: Text(
                    company,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              );
            }).toList(),
          ),
        if (companies.length > 10)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '... and ${companies.length - 10} more',
              style: FluentTheme.of(context).typography.caption?.copyWith(
                color: FluentTheme.of(context).resources.textFillColorSecondary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDateRangeFilter() {
    final theme = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick date range buttons
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickDateButton('Last 7 days', 7),
            _buildQuickDateButton('Last 30 days', 30),
            _buildQuickDateButton('Last 90 days', 90),
          ],
        ),
        const SizedBox(height: 12),
        
        // Custom date range
        Row(
          children: [
            Expanded(
              child: Button(
                onPressed: () => _showAdvancedDateRangePicker(),
                child: Text(
                  widget.dateRange != null
                      ? 'Custom Range'
                      : 'Select Range',
                ),
              ),
            ),
            if (widget.dateRange != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(FluentIcons.clear),
                onPressed: () => widget.onFilterChanged(dateRange: null),
              ),
            ],
          ],
        ),
        
        if (widget.dateRange != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.resources.cardBackgroundFillColorSecondary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${_formatDate(widget.dateRange!.start)} - ${_formatDate(widget.dateRange!.end)}',
              style: theme.typography.caption,
            ),
          ),
        ],
      ],
    );
  }

  void _showAdvancedDateRangePicker() {
    showDialog(
      context: context,
      builder: (context) => AdvancedDateRangePicker(
        initialRange: widget.dateRange,
        onRangeChanged: (range) => widget.onFilterChanged(dateRange: range),
      ),
    );
  }

  Widget _buildFilterPresetsSection() {
    return _buildFilterSection(
      title: 'Saved Presets',
      isExpanded: _isPresetExpanded,
      onToggle: () => setState(() {
        _isPresetExpanded = !_isPresetExpanded;
      }),
      child: FilterPresetManager(
        currentSearchTerm: widget.searchController.text,
        currentTags: widget.selectedTags,
        currentCompany: widget.selectedCompany,
        currentDateRange: widget.dateRange,
        currentSortBy: 'name', // You'll need to pass this from parent TODO
        currentSortAscending: true, // You'll need to pass this from parent
        onPresetSelected: (preset) {
          // Apply the preset filters
          widget.searchController.text = preset.searchTerm ?? '';
          widget.onFilterChanged(
            tags: preset.tags,
            company: preset.company,
            dateRange: preset.dateRange,
          );
          widget.onSearchChanged(preset.searchTerm ?? '');
        },
      ),
    );
  }

  Widget _buildQuickDateButton(String label, int days) {
    final isActive = widget.dateRange != null &&
        widget.dateRange!.start.isAfter(DateTime.now().subtract(Duration(days: days + 1))) &&
        widget.dateRange!.end.isAfter(DateTime.now().subtract(const Duration(days: 1)));

    return Button(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(
          isActive 
              ? FluentTheme.of(context).accentColor.withValues(alpha: 0.1)
              : null,
        ),
        foregroundColor: WidgetStateProperty.all(
          isActive 
              ? FluentTheme.of(context).accentColor
              : null,
        ),
      ),
      onPressed: () {
        final end = DateTime.now();
        final start = end.subtract(Duration(days: days));
        widget.onFilterChanged(dateRange: DateTimeRange(start: start, end: end));
      },
      child: Text(label),
    );
  }

  Widget _buildActiveFiltersSummary(FluentThemeData theme) {
    final activeFilters = <String>[];
    
    if (widget.searchController.text.isNotEmpty) {
      activeFilters.add('Search: "${widget.searchController.text}"');
    }
    if (widget.selectedTags.isNotEmpty) {
      activeFilters.add('Tags: ${widget.selectedTags.length}');
    }
    if (widget.selectedCompany != null) {
      activeFilters.add('Company: ${widget.selectedCompany}');
    }
    if (widget.dateRange != null) {
      activeFilters.add('Date Range');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Filters',
          style: theme.typography.caption?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.accentColor,
          ),
        ),
        const SizedBox(height: 8),
        ...activeFilters.map((filter) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  filter,
                  style: theme.typography.caption,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  bool _hasActiveFilters() {
    return widget.searchController.text.isNotEmpty ||
           widget.selectedTags.isNotEmpty ||
           widget.selectedCompany != null ||
           widget.dateRange != null;
  }
}