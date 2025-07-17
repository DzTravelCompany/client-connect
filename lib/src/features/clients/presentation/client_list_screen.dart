import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/paginated_list_view.dart';
import '../../../core/presentation/providers/layout_providers.dart';
import '../logic/client_providers.dart';
import '../data/client_model.dart';
import 'widgets/client_filter_panel.dart';
import 'widgets/enhanced_client_card.dart';
import 'widgets/client_details_panel.dart';
import 'dart:async';


class ClientListScreen extends ConsumerStatefulWidget {
  const ClientListScreen({super.key});

  @override
  ConsumerState<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends ConsumerState<ClientListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  Timer? _debounceTimer;
  final Set<int> _selectedClientIds = {};
  String _sortBy = 'name';
  bool _sortAscending = true;
  List<String> _selectedTags = [];
  String? _selectedCompany;
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchTerm = value.trim();
        });
      }
    });
  }

  void _onFilterChanged({
    List<String>? tags,
    String? company,
    DateTimeRange? dateRange,
  }) {
    setState(() {
      if (tags != null) _selectedTags = tags;
      if (company != null) _selectedCompany = company;
      if (dateRange != null) _dateRange = dateRange;
    });
  }

  void _clearFilters() {
    setState(() {
      _searchTerm = '';
      _selectedTags.clear();
      _selectedCompany = null;
      _dateRange = null;
      _searchController.clear();
    });
  }

  void _onClientSelected(int clientId) {
    ref.read(detailPanelStateProvider.notifier).showPanel(
      DetailPanelType.client,
      clientId.toString(),
    );
  }

  void _toggleClientSelection(int clientId) {
    setState(() {
      if (_selectedClientIds.contains(clientId)) {
        _selectedClientIds.remove(clientId);
      } else {
        _selectedClientIds.add(clientId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedClientIds.clear();
    });
  }

  Future<PaginatedResult<ClientModel>> _loadClients(int page, int limit) async {
    final params = PaginatedClientsParams(
      page: page,
      limit: limit,
      searchTerm: _searchTerm.isEmpty ? null : _searchTerm,
      tags: _selectedTags.isEmpty ? null : _selectedTags,
      company: _selectedCompany,
      dateRange: _dateRange,
      sortBy: _sortBy,
      sortAscending: _sortAscending,
    );
    
    return await ref.read(paginatedClientsProvider(params));
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final detailPanelState = ref.watch(detailPanelStateProvider);

    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: Container(
        color: theme.scaffoldBackgroundColor,
        child: Row(
          children: [
            // Left Column: Filter Panel
            Container(
              width: 320,
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(
                  right: BorderSide(
                    color: theme.resources.dividerStrokeColorDefault,
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: ClientFilterPanel(
                searchController: _searchController,
                onSearchChanged: _onSearchChanged,
                selectedTags: _selectedTags,
                selectedCompany: _selectedCompany,
                dateRange: _dateRange,
                onFilterChanged: _onFilterChanged,
                onClearFilters: _clearFilters,
              ),
            ),

            // Center Column: Client Cards
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                constraints: const BoxConstraints(minWidth: 0),
                child: Column(
                  children: [
                    // Header with actions
                    SizedBox(
                      width: double.infinity,
                      child: _buildClientListHeader(theme),
                    ),
                    const SizedBox(height: 16),

                    // Bulk actions bar
                    if (_selectedClientIds.isNotEmpty) ...[
                      SizedBox(
                        width: double.infinity,
                        child: _buildBulkActionsBar(theme),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Client cards list
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) => PaginatedListView<ClientModel>(
                          key: ValueKey('${_searchTerm}_${_selectedTags.join(',')}_${_selectedCompany}_${_dateRange?.toString()}_${_sortBy}_$_sortAscending'),
                          loadData: _loadClients,
                          pageSize: 20,
                          searchQuery: _searchTerm,
                          itemBuilder: (client, index) => ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                            child: EnhancedClientCard(
                              client: client,
                              isSelected: _selectedClientIds.contains(client.id),
                              onTap: () => _onClientSelected(client.id),
                              onSelectionChanged: (selected) => _toggleClientSelection(client.id),
                              showSelection: _selectedClientIds.isNotEmpty,
                            ),
                          ),
                          emptyBuilder: () => _buildEmptyState(theme),
                          errorBuilder: (error) => _buildErrorState(theme, error),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Right Column: Client Details Panel
            if (detailPanelState.isVisible && detailPanelState.type == DetailPanelType.client)
              Container(
                width: 400,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  border: Border(
                    left: BorderSide(
                      color: theme.resources.dividerStrokeColorDefault,
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(-2, 0),
                    ),
                  ],
                ),
                child: ClientDetailsPanel(
                  clientId: int.parse(detailPanelState.selectedItemId!),
                  onClose: () => ref.read(detailPanelStateProvider.notifier).hidePanel(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientListHeader(FluentThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final isNarrow = availableWidth < 600;
        
        if (isNarrow) {
          // Stack layout for narrow screens
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Clients',
                    style: theme.typography.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your client relationships',
                    style: theme.typography.body?.copyWith(
                      color: theme.resources.textFillColorSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Controls section - stacked for narrow screens
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          width: double.infinity,
                          child: ComboBox<String>(
                            value: _sortBy,
                            items: const [
                              ComboBoxItem(value: 'name', child: Text('Name')),
                              ComboBoxItem(value: 'company', child: Text('Company')),
                              ComboBoxItem(value: 'created', child: Text('Created')),
                              ComboBoxItem(value: 'updated', child: Text('Updated')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _sortBy = value;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: IconButton(
                          icon: Icon(_sortAscending ? FluentIcons.sort_up : FluentIcons.sort_down),
                          onPressed: () {
                            setState(() {
                              _sortAscending = !_sortAscending;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => context.go('/clients/add'),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(FluentIcons.add, size: 16),
                          SizedBox(width: 4),
                          Text('Add Client'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        }
        
        // Wide layout for normal screens
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Clients',
                    style: theme.typography.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your client relationships',
                    style: theme.typography.body?.copyWith(
                      color: theme.resources.textFillColorSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Controls with proper constraints
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 140,
                  child: ComboBox<String>(
                    value: _sortBy,
                    items: const [
                      ComboBoxItem(value: 'name', child: Text('Name')),
                      ComboBoxItem(value: 'company', child: Text('Company')),
                      ComboBoxItem(value: 'created', child: Text('Created')),
                      ComboBoxItem(value: 'updated', child: Text('Updated')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _sortBy = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    icon: Icon(_sortAscending ? FluentIcons.sort_up : FluentIcons.sort_down),
                    onPressed: () {
                      setState(() {
                        _sortAscending = !_sortAscending;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => context.go('/clients/add'),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FluentIcons.add, size: 16),
                      SizedBox(width: 4),
                      Text('Add'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildBulkActionsBar(FluentThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.accentColor.withValues(alpha: 0.3),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 500;
          
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      FluentIcons.multi_select,
                      color: theme.accentColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_selectedClientIds.length} selected',
                        style: TextStyle(
                          color: theme.accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Button(
                      onPressed: () => _showBulkTagDialog(),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(FluentIcons.tag, size: 14),
                          SizedBox(width: 4),
                          Text('Tag'),
                        ],
                      ),
                    ),
                    Button(
                      onPressed: () => _showBulkDeleteDialog(),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(FluentIcons.delete, size: 14),
                          SizedBox(width: 4),
                          Text('Delete'),
                        ],
                      ),
                    ),
                    Button(
                      onPressed: _clearSelection,
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            );
          }
          
          return Row(
            children: [
              Icon(
                FluentIcons.multi_select,
                color: theme.accentColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '${_selectedClientIds.length} clients selected',
                style: TextStyle(
                  color: theme.accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Wrap(
                spacing: 8,
                children: [
                  Button(
                    onPressed: () => _showBulkTagDialog(),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FluentIcons.tag, size: 14),
                        SizedBox(width: 4),
                        Text('Tag'),
                      ],
                    ),
                  ),
                  Button(
                    onPressed: () => _showBulkDeleteDialog(),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FluentIcons.delete, size: 14),
                        SizedBox(width: 4),
                        Text('Delete'),
                      ],
                    ),
                  ),
                  Button(
                    onPressed: _clearSelection,
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(FluentThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.people,
            size: 64,
            color: theme.resources.textFillColorSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            _hasActiveFilters() ? 'No clients match your filters' : 'No clients found',
            style: theme.typography.subtitle?.copyWith(
              color: theme.resources.textFillColorSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _hasActiveFilters() 
                ? 'Try adjusting your search criteria'
                : 'Add your first client to get started',
            style: theme.typography.body?.copyWith(
              color: theme.resources.textFillColorTertiary,
            ),
          ),
          const SizedBox(height: 16),
          if (_hasActiveFilters())
            Button(
              onPressed: _clearFilters,
              child: const Text('Clear Filters'),
            )
          else
            FilledButton(
              onPressed: () => context.go('/clients/add'),
              child: const Text('Add Client'),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState(FluentThemeData theme, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.error,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading clients',
            style: theme.typography.subtitle,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: theme.typography.body?.copyWith(
              color: theme.resources.textFillColorSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Button(
            onPressed: () => setState(() {}),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _searchTerm.isNotEmpty ||
           _selectedTags.isNotEmpty ||
           _selectedCompany != null ||
           _dateRange != null;
  }

  void _showBulkTagDialog() {
    // TODO: Implement bulk tag dialog
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: const Text('Bulk Tag'),
        content: const Text('Bulk tagging feature will be implemented soon.'),
        severity: InfoBarSeverity.info,
        onClose: close,
      ),
    );
  }

  void _showBulkDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Delete Clients'),
        content: Text('Are you sure you want to delete ${_selectedClientIds.length} clients? This action cannot be undone.'),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            child: const Text('Delete'),
            onPressed: () async {
              Navigator.of(context).pop();
              await _performBulkDelete();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _performBulkDelete() async {
    try {
      await ref.read(clientBulkOperationsProvider.notifier)
          .bulkDeleteClients(_selectedClientIds.toList());
      
      setState(() {
        _selectedClientIds.clear();
      });
      
      if (mounted) {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Clients Deleted'),
            content: Text('${_selectedClientIds.length} clients have been deleted.'),
            severity: InfoBarSeverity.success,
            onClose: close,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Error Deleting Clients'),
            content: Text('Failed to delete clients: ${e.toString()}'),
            severity: InfoBarSeverity.error,
            onClose: close,
          ),
        );
      }
    }
  }
}