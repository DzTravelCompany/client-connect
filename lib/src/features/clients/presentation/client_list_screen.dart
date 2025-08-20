import 'package:client_connect/src/features/tags/data/tag_model.dart';
import 'package:client_connect/src/features/tags/logic/tag_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/paginated_list_view.dart';
import '../../../core/presentation/providers/layout_providers.dart';
import '../../../core/design_system/design_tokens.dart';
import '../../../core/design_system/component_library.dart';
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
  String? _selectedJobTitle;
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
    String? jobTitle,
    DateTimeRange? dateRange,
  }) {
    setState(() {
      if (tags != null) _selectedTags = tags;
      if (company != null) _selectedCompany = company;
      if (jobTitle != null) _selectedJobTitle = jobTitle;
      if (dateRange != null) _dateRange = dateRange;
    });
    
    Future.microtask(() {
      final currentValue = ref.read(clientRefreshTriggerProvider);
      ref.read(clientRefreshTriggerProvider.notifier).state = currentValue + 1;
    });
  }

  void _clearFilters() {
    setState(() {
      _searchTerm = '';
      _selectedTags.clear();
      _selectedCompany = null;
      _selectedJobTitle = null;
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

  Stream<PaginatedResult<ClientModel>> _loadClients(int page, int limit) {
    final params = PaginatedClientsParams(
      page: page,
      limit: limit,
      searchTerm: _searchTerm.isEmpty ? null : _searchTerm,
      tags: _selectedTags.isEmpty ? null : _selectedTags,
      company: _selectedCompany,
      jobTitle: _selectedJobTitle,
      dateRange: _dateRange,
      sortBy: _sortBy,
      sortAscending: _sortAscending,
    );
  
    // Use the stream directly from the provider
    return ref.read(paginatedClientsProvider(params).stream);
  }

  @override
  Widget build(BuildContext context) {
    final detailPanelState = ref.watch(detailPanelStateProvider);
    final filterPanelState = ref.watch(filterPanelStateProvider);

    // Listen to client form state to refresh list when clients are saved
    ref.listen<ClientFormState>(clientFormProvider, (previous, next) {
      if (previous?.isSaved != next.isSaved && next.isSaved) {
        // Clear selection when data changes
        setState(() {
          _selectedClientIds.clear();
        });
      }
    });

    // Listen to bulk operations to refresh list
    ref.listen<ClientBulkOperationsState>(clientBulkOperationsProvider, (previous, next) {
      if (previous?.successMessage != next.successMessage && next.successMessage != null) {
        // Clear selection when data changes
        setState(() {
          _selectedClientIds.clear();
        });
      }
    });

    ref.listen<AsyncValue<List<TagModel>>>(allTagsProvider, (previous, next) {
      // Force refresh when tags are modified
      if (previous != null && next.hasValue && previous.hasValue) {
        final currentValue = ref.read(clientRefreshTriggerProvider);
        ref.read(clientRefreshTriggerProvider.notifier).state = currentValue + 1;
      }
    });

    return Container(
      color: DesignTokens.surfacePrimary,
      child: Column(
        children: [
          _buildClientListHeader(),
          Expanded(
            child: Row(
              children: [
                // Left Column: Filter Panel - Made conditionally visible with animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: filterPanelState.isVisible ? filterPanelState.width : 0,
                  child: filterPanelState.isVisible
                      ? Container(
                          decoration: BoxDecoration(
                            color: DesignTokens.surfaceSecondary,
                            border: Border(
                              right: BorderSide(
                                color: DesignTokens.borderPrimary,
                                width: 1,
                              ),
                            ),
                            boxShadow: DesignTokens.shadowLow,
                          ),
                          child: ClientFilterPanel(
                            searchController: _searchController,
                            onSearchChanged: _onSearchChanged,
                            selectedTags: _selectedTags,
                            selectedCompany: _selectedCompany,
                            selectedJobTitle: _selectedJobTitle,
                            dateRange: _dateRange,
                            onFilterChanged: _onFilterChanged,
                            onClearFilters: _clearFilters,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                // Center Column: Client Cards
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(DesignTokens.space4),
                    constraints: const BoxConstraints(minWidth: 0),
                    child: Column(
                      children: [
                        // Bulk actions bar
                        if (_selectedClientIds.isNotEmpty) ...[
                          SizedBox(
                            width: double.infinity,
                            child: _buildBulkActionsBar(),
                          ),
                          SizedBox(height: DesignTokens.space3),
                        ],

                        // Client cards list - Force rebuild when refresh trigger changes
                        Expanded(
                          child: Consumer(
                            builder: (context, ref, child) {
                              // Watch the refresh trigger to force rebuild
                              final refreshTrigger = ref.watch(clientRefreshTriggerProvider);
                              
                              return LayoutBuilder(
                                builder: (context, constraints) => PaginatedListView<ClientModel>(
                                  key: ValueKey('clients_${refreshTrigger}_${_searchTerm}_${_selectedTags.join(',')}_${_selectedCompany}_${_selectedJobTitle}_${_dateRange?.start}_${_sortBy}_$_sortAscending'),
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
                                  emptyBuilder: () => _buildEmptyState(),
                                  errorBuilder: (error) => _buildErrorState(error),
                                ),
                              );
                            },
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
                      color: DesignTokens.surfaceSecondary,
                      border: Border(
                        left: BorderSide(
                          color: DesignTokens.borderPrimary,
                          width: 1,
                        ),
                      ),
                      boxShadow: DesignTokens.shadowLow,
                    ),
                    child: ClientDetailsPanel(
                      clientId: int.parse(detailPanelState.selectedItemId!),
                      onClose: () => ref.read(detailPanelStateProvider.notifier).hidePanel(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientListHeader() {
    final filterPanelState = ref.watch(filterPanelStateProvider);
    
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space6),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceSecondary,
        border: Border(
          bottom: BorderSide(
            color: DesignTokens.borderPrimary,
            width: 1,
          ),
        ),
        boxShadow: DesignTokens.shadowLow,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final isNarrow = availableWidth < 600;
          
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(DesignTokens.space2),
                      decoration: BoxDecoration(
                        color: DesignTokens.withOpacity(DesignTokens.accentPrimary, 0.1),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                        border: Border.all(
                          color: DesignTokens.withOpacity(DesignTokens.accentPrimary, 0.2),
                        ),
                      ),
                      child: Icon(
                        FluentIcons.people,
                        size: DesignTokens.iconSizeLarge,
                        color: DesignTokens.accentPrimary,
                      ),
                    ),
                    SizedBox(width: DesignTokens.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Clients',
                            style: DesignTextStyles.titleLarge.copyWith(
                              fontWeight: DesignTokens.fontWeightSemiBold,
                            ),
                          ),
                          SizedBox(height: DesignTokens.space1),
                          Text(
                            'Manage your client relationships',
                            style: DesignTextStyles.body.copyWith(
                              color: DesignTokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: DesignTokens.space4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        DesignSystemComponents.secondaryButton(
                          text: '',
                          icon: filterPanelState.isVisible ? FluentIcons.side_panel : FluentIcons.filter,
                          onPressed: () => ref.read(filterPanelStateProvider.notifier).toggleVisibility(),
                          tooltip: filterPanelState.isVisible ? 'Hide filters' : 'Show filters',
                        ),
                        SizedBox(width: DesignTokens.space2),
                        Expanded(
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
                        SizedBox(width: DesignTokens.space2),
                        DesignSystemComponents.secondaryButton(
                          text: '',
                          icon: _sortAscending ? FluentIcons.sort_up : FluentIcons.sort_down,
                          onPressed: () {
                            setState(() {
                              _sortAscending = !_sortAscending;
                            });
                          },
                          tooltip: _sortAscending ? 'Sort descending' : 'Sort ascending',
                        ),
                      ],
                    ),
                    SizedBox(height: DesignTokens.space3),
                    DesignSystemComponents.primaryButton(
                      text: 'Add Client',
                      icon: FluentIcons.add,
                      onPressed: () => context.go('/clients/add'),
                    ),
                  ],
                ),
              ],
            );
          }
          
          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.space2),
                decoration: BoxDecoration(
                  color: DesignTokens.withOpacity(DesignTokens.accentPrimary, 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                  border: Border.all(
                    color: DesignTokens.withOpacity(DesignTokens.accentPrimary, 0.2),
                  ),
                ),
                child: Icon(
                  FluentIcons.people,
                  size: DesignTokens.iconSizeLarge,
                  color: DesignTokens.accentPrimary,
                ),
              ),
              SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clients',
                      style: DesignTextStyles.titleLarge.copyWith(
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                    ),
                    SizedBox(height: DesignTokens.space1),
                    Text(
                      'Manage your client relationships',
                      style: DesignTextStyles.body.copyWith(
                        color: DesignTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DesignSystemComponents.secondaryButton(
                    text: filterPanelState.isVisible ? 'Hide Filters' : 'Show Filters',
                    icon: filterPanelState.isVisible ? FluentIcons.side_panel : FluentIcons.filter,
                    onPressed: () => ref.read(filterPanelStateProvider.notifier).toggleVisibility(),
                  ),
                  SizedBox(width: DesignTokens.space3),
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
                  SizedBox(width: DesignTokens.space2),
                  DesignSystemComponents.secondaryButton(
                    text: '',
                    icon: _sortAscending ? FluentIcons.sort_up : FluentIcons.sort_down,
                    onPressed: () {
                      setState(() {
                        _sortAscending = !_sortAscending;
                      });
                    },
                    tooltip: _sortAscending ? 'Sort descending' : 'Sort ascending',
                  ),
                  SizedBox(width: DesignTokens.space3),
                  DesignSystemComponents.primaryButton(
                    text: 'Add',
                    icon: FluentIcons.add,
                    onPressed: () => context.go('/clients/add'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBulkActionsBar() {
    return DesignSystemComponents.standardCard(
      padding: const EdgeInsets.all(DesignTokens.space4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 500;
          
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(DesignTokens.space1),
                      decoration: BoxDecoration(
                        color: DesignTokens.withOpacity(DesignTokens.accentPrimary, 0.1),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                      ),
                      child: Icon(
                        FluentIcons.multi_select,
                        color: DesignTokens.accentPrimary,
                        size: DesignTokens.iconSizeSmall,
                      ),
                    ),
                    SizedBox(width: DesignTokens.space2),
                    Expanded(
                      child: Text(
                        '${_selectedClientIds.length} selected',
                        style: DesignTextStyles.body.copyWith(
                          color: DesignTokens.accentPrimary,
                          fontWeight: DesignTokens.fontWeightSemiBold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: DesignTokens.space3),
                Wrap(
                  spacing: DesignTokens.space2,
                  runSpacing: DesignTokens.space2,
                  children: [
                    DesignSystemComponents.secondaryButton(
                      text: 'Tag',
                      icon: FluentIcons.tag,
                      onPressed: () => _showBulkTagDialog(),
                    ),
                    DesignSystemComponents.dangerButton(
                      text: 'Delete',
                      icon: FluentIcons.delete,
                      onPressed: () => _showBulkDeleteDialog(),
                      requireConfirmation: false,
                    ),
                    DesignSystemComponents.secondaryButton(
                      text: 'Clear',
                      onPressed: _clearSelection,
                    ),
                  ],
                ),
              ],
            );
          }
          
          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.space1),
                decoration: BoxDecoration(
                  color: DesignTokens.withOpacity(DesignTokens.accentPrimary, 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                ),
                child: Icon(
                  FluentIcons.multi_select,
                  color: DesignTokens.accentPrimary,
                  size: DesignTokens.iconSizeSmall,
                ),
              ),
              SizedBox(width: DesignTokens.space2),
              Text(
                '${_selectedClientIds.length} clients selected',
                style: DesignTextStyles.body.copyWith(
                  color: DesignTokens.accentPrimary,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                ),
              ),
              const Spacer(),
              Wrap(
                spacing: DesignTokens.space2,
                children: [
                  DesignSystemComponents.secondaryButton(
                    text: 'Tag',
                    icon: FluentIcons.tag,
                    onPressed: () => _showBulkTagDialog(),
                  ),
                  DesignSystemComponents.dangerButton(
                    text: 'Delete',
                    icon: FluentIcons.delete,
                    onPressed: () => _showBulkDeleteDialog(),
                    requireConfirmation: false,
                  ),
                  DesignSystemComponents.secondaryButton(
                    text: 'Clear',
                    onPressed: _clearSelection,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return DesignSystemComponents.emptyState(
      title: _hasActiveFilters() ? 'No clients match your filters' : 'No clients found',
      message: _hasActiveFilters() 
          ? 'Try adjusting your search criteria'
          : 'Add your first client to get started',
      icon: FluentIcons.people,
      iconColor: DesignTokens.textTertiary,
      actionText: _hasActiveFilters() ? 'Clear Filters' : 'Add Client',
      onAction: _hasActiveFilters() ? _clearFilters : () => context.go('/clients/add'),
    );
  }

  Widget _buildErrorState(String error) {
    return DesignSystemComponents.emptyState(
      title: 'Error loading clients',
      message: error,
      icon: FluentIcons.error,
      iconColor: DesignTokens.semanticError,
      actionText: 'Retry',
      onAction: () => setState(() {}),
    );
  }

  bool _hasActiveFilters() {
    return _searchTerm.isNotEmpty ||
           _selectedTags.isNotEmpty ||
           _selectedCompany != null ||
           _selectedJobTitle != null ||
           _dateRange != null;
  }

  void _showBulkTagDialog() {
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
          DesignSystemComponents.secondaryButton(
            text: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
          ),
          DesignSystemComponents.dangerButton(
            text: 'Delete',
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