import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../tags/logic/tag_providers.dart';
import '../../../tags/data/tag_model.dart';
import '../../logic/client_providers.dart';
import 'advanced_date_range_picker.dart';
import 'filter_preset_manager.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/component_library.dart';

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
    final tagsAsync = ref.watch(allTagsProvider);
    final companiesAsync = ref.watch(clientCompaniesProvider);

    return Container(
      padding: EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.surfacePrimary,
            DesignTokens.surfacePrimary.withValues(alpha: 0.95),
          ],
        ),
        border: Border(
          right: BorderSide(
            color: DesignTokens.borderPrimary,
            width: 1,
          ),
        ),
        boxShadow: DesignTokens.shadowLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with design system styling
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(DesignTokens.space2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DesignTokens.accentPrimary.withValues(alpha: 0.15),
                      DesignTokens.accentPrimary.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                ),
                child: Icon(
                  FluentIcons.filter,
                  size: DesignTokens.iconSizeMedium,
                  color: DesignTokens.accentPrimary,
                ),
              ),
              SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Text(
                  'Filters',
                  style: DesignTextStyles.subtitle.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
              ),
              if (_hasActiveFilters())
                DesignSystemComponents.secondaryButton(
                  text: 'Clear All',
                  onPressed: widget.onClearFilters,
                ),
            ],
          ),
          SizedBox(height: DesignTokens.space4),
          
          // Search with design system input
          DesignSystemComponents.textInput(
            controller: widget.searchController,
            placeholder: 'Search clients...',
            prefixIcon: FluentIcons.search,
            suffixIcon: widget.searchController.text.isNotEmpty ? FluentIcons.clear : null,
            onSuffixIconPressed: widget.searchController.text.isNotEmpty ? () {
              widget.searchController.clear();
              widget.onSearchChanged('');
            } : null,
            onChanged: widget.onSearchChanged,
          ),
          SizedBox(height: DesignTokens.space5),
          
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
                        loading: () => DesignSystemComponents.skeletonLoader(height: 80),
                        error: (_, __) => DesignSystemComponents.emptyState(
                          title: 'Error loading tags',
                          message: 'Could not load available tags',
                          icon: FluentIcons.error,
                          iconColor: DesignTokens.semanticError,
                        ),
                      ),
                    ),
                    SizedBox(height: DesignTokens.space4),
                    
                    // Company Filter
                    _buildFilterSection(
                      title: 'Company',
                      isExpanded: _isCompanyExpanded,
                      onToggle: () => setState(() => _isCompanyExpanded = !_isCompanyExpanded),
                      child: companiesAsync.when(
                        data: (companies) => _buildCompanyFilter(companies),
                        loading: () => DesignSystemComponents.skeletonLoader(height: 120),
                        error: (_, __) => DesignSystemComponents.emptyState(
                          title: 'Error loading companies',
                          message: 'Could not load company list',
                          icon: FluentIcons.error,
                          iconColor: DesignTokens.semanticError,
                        ),
                      ),
                    ),
                    SizedBox(height: DesignTokens.space4),
                    
                    // Date Range Filter
                    _buildFilterSection(
                      title: 'Date Added',
                      isExpanded: _isDateExpanded,
                      onToggle: () => setState(() => _isDateExpanded = !_isDateExpanded),
                      child: _buildDateRangeFilter(),
                    ),
                    SizedBox(height: DesignTokens.space4),
                    
                    // Filter Presets
                    _buildFilterPresetsSection(),
                  ],
                ),
              ),
            ),
          ),
          
          // Active Filters Summary
          if (_hasActiveFilters()) ...[
            Container(
              margin: EdgeInsets.only(top: DesignTokens.space4),
              padding: EdgeInsets.all(DesignTokens.space3),
              decoration: BoxDecoration(
                color: DesignTokens.withOpacity(DesignTokens.accentPrimary, 0.05),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                border: Border.all(
                  color: DesignTokens.withOpacity(DesignTokens.accentPrimary, 0.2),
                ),
              ),
              child: _buildActiveFiltersSummary(),
            ),
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
    return DesignSystemComponents.standardCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          DesignSystemComponents.navigationItem(
            label: title,
            icon: isExpanded ? FluentIcons.chevron_up : FluentIcons.chevron_down,
            onPressed: onToggle,
            isActive: isExpanded,
          ),
          if (isExpanded) ...[
            Container(
              width: double.infinity,
              height: 1,
              color: DesignTokens.borderPrimary,
            ),
            Padding(
              padding: EdgeInsets.all(DesignTokens.space3),
              child: child,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTagsFilter(List<TagModel> tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tags.isEmpty)
          DesignSystemComponents.emptyState(
            title: 'No tags available',
            message: 'Create some tags to filter clients',
            icon: FluentIcons.tag,
          )
        else
          Wrap(
            spacing: DesignTokens.space2,
            runSpacing: DesignTokens.space2,
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
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: DesignTokens.animationNormal,
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.space3,
            vertical: DesignTokens.space2,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? DesignTokens.withOpacity(DesignTokens.accentPrimary, 0.1)
                : DesignTokens.surfaceSecondary,
            border: Border.all(
              color: isSelected
                  ? DesignTokens.accentPrimary
                  : DesignTokens.borderPrimary,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(DesignTokens.radiusRound),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Icon(
                  FluentIcons.check_mark,
                  size: DesignTokens.iconSizeSmall,
                  color: DesignTokens.accentPrimary,
                ),
                SizedBox(width: DesignTokens.space1),
              ],
              Text(
                label,
                style: DesignTextStyles.caption.copyWith(
                  fontWeight: isSelected 
                      ? DesignTokens.fontWeightSemiBold 
                      : DesignTokens.fontWeightRegular,
                  color: isSelected
                      ? DesignTokens.accentPrimary
                      : DesignTokens.textPrimary,
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
          DesignSystemComponents.emptyState(
            title: 'No companies found',
            message: 'No company data available',
            icon: FluentIcons.build,
          )
        else
          Column(
            children: companies.take(10).map((company) {
              final isSelected = widget.selectedCompany == company;
              return Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: DesignTokens.space1),
                child: RadioButton(
                  checked: isSelected,
                  onChanged: (checked) {
                    widget.onFilterChanged(
                      company: checked == true ? company : null,
                    );
                  },
                  content: Text(
                    company,
                    style: DesignTextStyles.body,
                  ),
                ),
              );
            }).toList(),
          ),
        if (companies.length > 10)
          Padding(
            padding: EdgeInsets.only(top: DesignTokens.space2),
            child: Text(
              '... and ${companies.length - 10} more',
              style: DesignTextStyles.caption.copyWith(
                color: DesignTokens.textSecondary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick date range buttons
        Wrap(
          spacing: DesignTokens.space2,
          runSpacing: DesignTokens.space2,
          children: [
            _buildQuickDateButton('Last 7 days', 7),
            _buildQuickDateButton('Last 30 days', 30),
            _buildQuickDateButton('Last 90 days', 90),
          ],
        ),
        SizedBox(height: DesignTokens.space3),
        
        // Custom date range
        Row(
          children: [
            Expanded(
              child: DesignSystemComponents.secondaryButton(
                text: widget.dateRange != null ? 'Custom Range' : 'Select Range',
                icon: FluentIcons.calendar,
                onPressed: () => _showAdvancedDateRangePicker(),
              ),
            ),
            if (widget.dateRange != null) ...[
              SizedBox(width: DesignTokens.space2),
              IconButton(
                icon: Icon(
                  FluentIcons.clear,
                  size: DesignTokens.iconSizeSmall,
                ),
                onPressed: () => widget.onFilterChanged(dateRange: null),
              ),
            ],
          ],
        ),
        
        if (widget.dateRange != null) ...[
          SizedBox(height: DesignTokens.space2),
          DesignSystemComponents.standardCard(
            padding: EdgeInsets.all(DesignTokens.space2),
            child: Text(
              '${_formatDate(widget.dateRange!.start)} - ${_formatDate(widget.dateRange!.end)}',
              style: DesignTextStyles.caption.copyWith(
                color: DesignTokens.textSecondary,
              ),
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
        currentSortBy: 'name',
        currentSortAscending: true,
        onPresetSelected: (preset) {
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
    // ignore: unused_local_variable
    final isActive = widget.dateRange != null &&
        widget.dateRange!.start.isAfter(DateTime.now().subtract(Duration(days: days + 1))) &&
        widget.dateRange!.end.isAfter(DateTime.now().subtract(const Duration(days: 1)));

    return DesignSystemComponents.secondaryButton(
      text: label,
      onPressed: () {
        final end = DateTime.now();
        final start = end.subtract(Duration(days: days));
        widget.onFilterChanged(dateRange: DateTimeRange(start: start, end: end));
      },
    );
  }

  Widget _buildActiveFiltersSummary() {
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
          style: DesignTextStyles.caption.copyWith(
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: DesignTokens.accentPrimary,
          ),
        ),
        SizedBox(height: DesignTokens.space2),
        ...activeFilters.map((filter) => Padding(
          padding: EdgeInsets.only(bottom: DesignTokens.space1),
          child: Row(
            children: [
              DesignSystemComponents.statusDot(
                type: SemanticColorType.info,
                size: 4,
              ),
              SizedBox(width: DesignTokens.space2),
              Expanded(
                child: Text(
                  filter,
                  style: DesignTextStyles.caption,
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
