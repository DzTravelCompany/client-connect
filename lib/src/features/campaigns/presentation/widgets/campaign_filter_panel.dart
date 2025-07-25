import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show showDatePicker;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../logic/campaign_providers.dart';

class CampaignFilterPanel extends ConsumerStatefulWidget {
  const CampaignFilterPanel({super.key});

  @override
  ConsumerState<CampaignFilterPanel> createState() => _CampaignFilterPanelState();
}

class _CampaignFilterPanelState extends ConsumerState<CampaignFilterPanel> {
  final _searchController = TextEditingController();
  bool _showAdvancedFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(campaignFilterStateProvider);
    final theme = FluentTheme.of(context);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          right: BorderSide(
            color: theme.resources.dividerStrokeColorDefault,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: theme.resources.dividerStrokeColorDefault,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(FluentIcons.filter, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Filter Campaigns',
                  style: theme.typography.bodyStrong,
                ),
                const Spacer(),
                if (filterState.hasActiveFilters)
                  Button(
                    onPressed: () {
                      ref.read(campaignFilterStateProvider.notifier).clearFilters();
                      _searchController.clear();
                    },
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search
                  _buildSearchSection(),
                  const SizedBox(height: 24),

                  // Status filters
                  _buildStatusFilters(),
                  const SizedBox(height: 24),

                  // Advanced filters toggle
                  _buildAdvancedFiltersToggle(),
                  
                  if (_showAdvancedFilters) ...[
                    const SizedBox(height: 16),
                    _buildAdvancedFilters(),
                  ],

                  const SizedBox(height: 24),

                  // Sort options
                  _buildSortOptions(),
                ],
              ),
            ),
          ),

          // Filter summary
          _buildFilterSummary(),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Search',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextBox(
          controller: _searchController,
          placeholder: 'Search campaigns...',
          prefix: const Icon(FluentIcons.search, size: 16),
          onChanged: (value) {
            ref.read(campaignFilterStateProvider.notifier).updateSearchTerm(value);
          },
        ),
      ],
    );
  }

  Widget _buildStatusFilters() {
    final filterState = ref.watch(campaignFilterStateProvider);
    final statusOptions = [
      'pending',
      'queued', 
      'in_progress',
      'paused',
      'completed',
      'failed',
      'cancelled',
      'scheduled',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: statusOptions.map((status) {
            final isSelected = filterState.statusFilters.contains(status);
            return GestureDetector(
              onTap: () {
                ref.read(campaignFilterStateProvider.notifier).toggleStatusFilter(status);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? FluentTheme.of(context).accentColor.withValues(alpha: 0.1)
                      : Colors.grey[150],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected 
                        ? FluentTheme.of(context).accentColor
                        : Colors.grey[200],
                  ),
                ),
                child: Text(
                  status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected 
                        ? FluentTheme.of(context).accentColor
                        : Colors.grey[100],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAdvancedFiltersToggle() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showAdvancedFilters = !_showAdvancedFilters;
        });
      },
      child: Row(
        children: [
          Icon(
            _showAdvancedFilters ? FluentIcons.chevron_down : FluentIcons.chevron_right,
            size: 12,
          ),
          const SizedBox(width: 8),
          const Text(
            'Advanced Filters',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    final filterState = ref.watch(campaignFilterStateProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date range
        const Text(
          'Date Range',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Button(
                onPressed: () => _selectStartDate(),
                child: Text(
                  filterState.startDate != null
                      ? DateFormat('dd/MM/yyyy').format(filterState.startDate!)
                      : 'Start Date',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Button(
                onPressed: () => _selectEndDate(),
                child: Text(
                  filterState.endDate != null
                      ? DateFormat('dd/MM/yyyy').format(filterState.endDate!)
                      : 'End Date',
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Template type
        const Text(
          'Template Type',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ComboBox<String>(
          value: filterState.templateType,
          placeholder: const Text('All Types'),
          items: const [
            ComboBoxItem(value: 'email', child: Text('Email')),
            ComboBoxItem(value: 'whatsapp', child: Text('WhatsApp')),
          ],
          onChanged: (value) {
            ref.read(campaignFilterStateProvider.notifier).setTemplateType(value);
          },
        ),
      ],
    );
  }

  Widget _buildSortOptions() {
    final filterState = ref.watch(campaignFilterStateProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sort By',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ComboBox<String>(
          value: filterState.sortBy,
          items: const [
            ComboBoxItem(value: 'createdAt', child: Text('Created Date')),
            ComboBoxItem(value: 'name', child: Text('Name')),
            ComboBoxItem(value: 'status', child: Text('Status')),
            ComboBoxItem(value: 'scheduledAt', child: Text('Scheduled Date')),
          ],
          onChanged: (value) {
            if (value != null) {
              ref.read(campaignFilterStateProvider.notifier)
                  .setSorting(value, filterState.sortAscending);
            }
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(
              checked: filterState.sortAscending,
              onChanged: (value) {
                ref.read(campaignFilterStateProvider.notifier)
                    .setSorting(filterState.sortBy!, value ?? false);
              },
            ),
            const SizedBox(width: 8),
            const Text('Ascending'),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterSummary() {
    final campaignsAsync = ref.watch(allCampaignsProvider);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: FluentTheme.of(context).resources.dividerStrokeColorDefault,
            width: 1,
          ),
        ),
      ),
      child: campaignsAsync.when(
        data: (campaigns) {
          final filteredCount = _getFilteredCampaigns(campaigns).length;
          return Row(
            children: [
              Icon(FluentIcons.info, size: 14, color: Colors.grey[100]),
              const SizedBox(width: 8),
              Text(
                '$filteredCount of ${campaigns.length} campaigns',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[100],
                ),
              ),
            ],
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  List<dynamic> _getFilteredCampaigns(List<dynamic> campaigns) {
    final filterState = ref.read(campaignFilterStateProvider);
    
    return campaigns.where((campaign) {
      // Apply search filter
      if (filterState.searchTerm.isNotEmpty) {
        final searchLower = filterState.searchTerm.toLowerCase();
        if (!campaign.name.toLowerCase().contains(searchLower)) {
          return false;
        }
      }
      
      // Apply status filters
      if (filterState.statusFilters.isNotEmpty) {
        if (!filterState.statusFilters.contains(campaign.status)) {
          return false;
        }
      }
      
      // Apply date range filters
      if (filterState.startDate != null) {
        if (campaign.createdAt.isBefore(filterState.startDate!)) {
          return false;
        }
      }
      
      if (filterState.endDate != null) {
        if (campaign.createdAt.isAfter(filterState.endDate!.add(const Duration(days: 1)))) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  void _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      ref.read(campaignFilterStateProvider.notifier)
          .setDateRange(date, ref.read(campaignFilterStateProvider).endDate);
    }
  }

  void _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      ref.read(campaignFilterStateProvider.notifier)
          .setDateRange(ref.read(campaignFilterStateProvider).startDate, date);
    }
  }
}
