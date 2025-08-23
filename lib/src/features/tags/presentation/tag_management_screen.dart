import 'package:client_connect/constants.dart' show logger;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../logic/tag_providers.dart';
import '../data/tag_model.dart';
import 'widgets/tag_chip.dart';
import 'widgets/tag_form_dialog.dart';
import 'widgets/bulk_tag_operations_panel.dart';
import '../../../core/realtime/realtime_sync_service.dart';
import '../../../core/realtime/event_bus.dart';
import '../../../core/design_system/design_tokens.dart';
import '../../../core/design_system/component_library.dart';
import '../../../core/design_system/layout_system.dart';
import 'dart:async';

class TagManagementScreen extends ConsumerStatefulWidget {
  const TagManagementScreen({super.key});

  @override
  ConsumerState<TagManagementScreen> createState() => _TagManagementScreenState();
}

class _TagManagementScreenState extends ConsumerState<TagManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  final List<int> _selectedTagFilter = [];
  late StreamSubscription _eventSubscription;
  final RealtimeSyncService _syncService = RealtimeSyncService();

  @override
  void initState() {
    super.initState();
    _setupRealtimeListeners();
  }

  void _setupRealtimeListeners() {
    // Listen to real-time events and refresh providers when needed
    _eventSubscription = _syncService.allEvents.listen((event) {
      if (mounted) {
        if (event is TagEvent) {
          // Tag-specific events - immediate refresh
          Future.microtask(() {
            ref.invalidate(allTagsProvider);
            ref.invalidate(tagUsageStatsProvider);
            ref.invalidate(allClientsWithTagsProvider);
            
            if (event.tagId != null) {
              ref.invalidate(tagByIdProvider(event.tagId!));
            }
            
            if (_selectedTagFilter.isNotEmpty) {
              ref.invalidate(clientsWithTagsProvider(_selectedTagFilter));
            }
          });
        } else if (event is DatabaseEvent && 
            (event.tableName == 'tags' || event.tableName == 'client_tags')) {
          // Database-level changes
          Future.microtask(() {
            ref.invalidate(allTagsProvider);
            ref.invalidate(allClientsWithTagsProvider);
            ref.invalidate(tagUsageStatsProvider);
            
            if (_selectedTagFilter.isNotEmpty) {
              ref.invalidate(clientsWithTagsProvider(_selectedTagFilter));
            }
          });
        } else if (event is ClientEvent) {
          // Client changes might affect tag assignments
          Future.microtask(() {
            ref.invalidate(allClientsWithTagsProvider);
            if (_selectedTagFilter.isNotEmpty) {
              ref.invalidate(clientsWithTagsProvider(_selectedTagFilter));
            }
            
            // If specific client was updated, refresh its tags
            if (event.clientId != null) {
              ref.invalidate(tagsForClientProvider(event.clientId!));
              ref.invalidate(clientTagsProvider(event.clientId!));
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _eventSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(allTagsProvider);
    final clientsAsync = _selectedTagFilter.isEmpty
        ? ref.watch(allClientsWithTagsProvider)
        : ref.watch(clientsWithTagsProvider(_selectedTagFilter));
    final tagManagementState = ref.watch(tagManagementProvider);
    final tagUsageStatsAsync = ref.watch(tagUsageStatsProvider);

    return ScaffoldPage(
      header: LayoutSystem.pageHeader(
        title: 'Tag Management',
        subtitle: 'Organize and manage client tags',
        actions: [
          DesignSystemComponents.primaryButton(
            text: 'New Tag',
            icon: FluentIcons.add,
            onPressed: () => _showTagDialog(),
            tooltip: 'Create a new tag',
          ),
          DesignSystemComponents.secondaryButton(
            text: 'Bulk Operations',
            icon: FluentIcons.bulk_upload,
            onPressed: () => _showBulkOperationsPanel(),
            tooltip: 'Perform bulk operations on selected clients',
          ),
          DesignSystemComponents.secondaryButton(
            text: 'Refresh',
            icon: FluentIcons.refresh,
            onPressed: () => _refreshAllData(),
            tooltip: 'Refresh all data',
          ),
        ],
      ),
      content: LayoutSystem.pageContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tagManagementState.error != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: DesignTokens.space4),
                child: DesignSystemComponents.statusBadge(
                  text: tagManagementState.error!,
                  type: SemanticColorType.error,
                  icon: FluentIcons.error,
                ),
              ),

            if (tagManagementState.successMessage != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: DesignTokens.space4),
                child: DesignSystemComponents.statusBadge(
                  text: tagManagementState.successMessage!,
                  type: SemanticColorType.success,
                  icon: FluentIcons.check_mark,
                ),
              ),

            LayoutSystem.inlineFormFields(
              children: [
                DesignSystemComponents.textInput(
                  controller: _searchController,
                  label: 'Search Clients',
                  placeholder: 'Search by name, email, or company...',
                  prefixIcon: FluentIcons.search,
                  onChanged: (value) {
                    setState(() {
                      _searchTerm = value;
                    });
                  },
                ),
                tagsAsync.when(
                  data: (tags) => _buildTagFilter(tags),
                  loading: () => DesignSystemComponents.loadingIndicator(
                    message: 'Loading tags...',
                    size: 24,
                  ),
                  error: (error, stack) => DesignSystemComponents.statusBadge(
                    text: 'Error loading tags',
                    type: SemanticColorType.error,
                  ),
                ),
              ],
            ),

            LayoutSystem.verticalSpace(DesignTokens.space4),

            if (tagManagementState.selectedClients.isNotEmpty)
              DesignSystemComponents.standardCard(
                child: Row(
                  children: [
                    DesignSystemComponents.statusDot(
                      type: SemanticColorType.info,
                      size: 12,
                    ),
                    LayoutSystem.horizontalSpace(DesignTokens.space2),
                    Expanded(
                      child: Text(
                        '${tagManagementState.selectedClients.length} clients selected',
                        style: DesignTextStyles.body.copyWith(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                        ),
                      ),
                    ),
                    DesignSystemComponents.secondaryButton(
                      text: 'Clear Selection',
                      onPressed: () => ref.read(tagManagementProvider.notifier).clearSelectedClients(),
                    ),
                  ],
                ),
              ),

            LayoutSystem.verticalSpace(DesignTokens.space4),

            Flexible(
              fit: FlexFit.loose,
              child: LayoutSystem.threeColumnLayout(
                leftFlex: 2,
                centerFlex: 3,
                rightFlex: 2,
                left: _buildTagSidebar(tagsAsync, tagUsageStatsAsync),
                center: _buildClientList(clientsAsync, tagManagementState),
                right: _buildTagStatistics(tagsAsync, tagUsageStatsAsync),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagSidebar(AsyncValue<List<TagModel>> tagsAsync, AsyncValue<Map<int, int>> tagUsageStatsAsync) {
    return LayoutSystem.sectionContainer(
      title: 'Available Tags',
      subtitle: 'Select tags to filter clients',
      action: DesignSystemComponents.secondaryButton(
        text: 'Manage',
        icon: FluentIcons.settings,
        onPressed: () => _showTagDialog(),
      ),
      child: SizedBox(
        height: 400,
        child: tagsAsync.when(
          data: (tags) => tagUsageStatsAsync.when(
            data: (stats) => _buildTagList(tags, stats),
            loading: () => _buildTagList(tags, {}),
            error: (error, stack) => _buildTagList(tags, {}),
          ),
          loading: () => DesignSystemComponents.loadingIndicator(
            message: 'Loading tags...',
          ),
          error: (error, stack) => DesignSystemComponents.emptyState(
            title: 'Error Loading Tags',
            message: 'Failed to load tags: $error',
            icon: FluentIcons.error,
            actionText: 'Retry',
            onAction: () => _refreshAllData(),
          ),
        ),
      ),
    );
  }

  Widget _buildClientList(AsyncValue<List<ClientWithTags>> clientsAsync, TagManagementState tagManagementState) {
    return LayoutSystem.sectionContainer(
      title: 'Clients',
      subtitle: 'Manage client tags and assignments',
      child: clientsAsync.when(
        data: (clients) {
          final filteredClients = _searchTerm.isEmpty
              ? clients
              : clients.where((client) =>
                  client.fullName.toLowerCase().contains(_searchTerm.toLowerCase()) ||
                  (client.email?.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false) ||
                  (client.company?.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false)
                ).toList();

          if (filteredClients.isEmpty) {
            return DesignSystemComponents.emptyState(
              title: 'No Clients Found',
              message: _searchTerm.isEmpty && _selectedTagFilter.isEmpty
                  ? 'No clients found. Add some clients to get started.'
                  : 'No clients found matching your criteria.',
              icon: FluentIcons.people,
              actionText: _searchTerm.isNotEmpty || _selectedTagFilter.isNotEmpty ? 'Clear Filters' : null,
              onAction: _searchTerm.isNotEmpty || _selectedTagFilter.isNotEmpty ? () {
                setState(() {
                  _searchTerm = '';
                  _searchController.clear();
                  _selectedTagFilter.clear();
                });
                Future.microtask(() {
                  ref.invalidate(allClientsWithTagsProvider);
                });
              } : null,
            );
          }

          return SizedBox(
            height: 500,
            child: ListView.builder(
              key: ValueKey('clients_${filteredClients.length}_${_selectedTagFilter.join(",")}_${DateTime.now().millisecondsSinceEpoch ~/ 1000}'),
              itemCount: filteredClients.length,
              itemBuilder: (context, index) {
                final client = filteredClients[index];
                final isSelected = tagManagementState.selectedClients.contains(client.id);

                return Padding(
                  padding: const EdgeInsets.only(bottom: DesignTokens.space2),
                  child: DesignSystemComponents.standardCard(
                    isSelected: isSelected,
                    onTap: () => ref.read(tagManagementProvider.notifier).selectClient(client.id),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              checked: isSelected,
                              onChanged: (checked) {
                                ref.read(tagManagementProvider.notifier).selectClient(client.id);
                              },
                            ),
                            LayoutSystem.horizontalSpace(DesignTokens.space2),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    client.fullName,
                                    style: DesignTextStyles.body.copyWith(
                                      fontWeight: DesignTokens.fontWeightSemiBold,
                                    ),
                                  ),
                                  if (client.email != null) ...[
                                    LayoutSystem.verticalSpace(DesignTokens.space1),
                                    Text(
                                      client.email!,
                                      style: DesignTextStyles.caption,
                                    ),
                                  ],
                                  if (client.company != null) ...[
                                    LayoutSystem.verticalSpace(DesignTokens.space1),
                                    Text(
                                      client.company!,
                                      style: DesignTextStyles.caption,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                DesignSystemComponents.secondaryButton(
                                  text: 'Tags',
                                  icon: FluentIcons.tag,
                                  onPressed: () => _showClientTagDialog(client.id, client.fullName),
                                ),
                                LayoutSystem.horizontalSpace(DesignTokens.space1),
                                DesignSystemComponents.secondaryButton(
                                  text: 'Edit',
                                  icon: FluentIcons.edit,
                                  onPressed: () => context.go('/clients/edit/${client.id}'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (client.tags.isNotEmpty) ...[
                          LayoutSystem.verticalSpace(DesignTokens.space3),
                          Wrap(
                            spacing: DesignTokens.space1,
                            runSpacing: DesignTokens.space1,
                            children: client.tags.map((tag) => TagChip(
                              key: ValueKey('tag_${tag.id}_${tag.name}_${tag.color}'),
                              tag: tag,
                              size: TagChipSize.small,
                              onRemove: () => _removeTagFromClient(client.id, tag.id),
                            )).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => DesignSystemComponents.loadingIndicator(
          message: 'Loading clients...',
        ),
        error: (error, stack) => DesignSystemComponents.emptyState(
          title: 'Error Loading Clients',
          message: 'Failed to load clients: $error',
          icon: FluentIcons.error,
          actionText: 'Retry',
          onAction: () => _refreshAllData(),
        ),
      ),
    );
  }

  Widget _buildTagStatistics(AsyncValue<List<TagModel>> tagsAsync, AsyncValue<Map<int, int>> tagUsageStatsAsync) {
    return LayoutSystem.sectionContainer(
      title: 'Tag Statistics',
      subtitle: 'Overview of tag usage',
      child: SizedBox(
        height: 400,
        child: tagsAsync.when(
          data: (tags) => tagUsageStatsAsync.when(
            data: (stats) {
              if (tags.isEmpty) {
                return DesignSystemComponents.emptyState(
                  title: 'No Tags',
                  message: 'Create your first tag to get started!',
                  icon: FluentIcons.tag,
                  actionText: 'Create Tag',
                  onAction: () => _showTagDialog(),
                );
              }

              return ListView.builder(
                itemCount: tags.length,
                itemBuilder: (context, index) {
                  final tag = tags[index];
                  final usageCount = stats[tag.id] ?? 0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: DesignTokens.space2),
                    child: DesignSystemComponents.standardCard(
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Color(int.parse('0xFF${tag.color.substring(1)}')),
                              shape: BoxShape.circle,
                            ),
                          ),
                          LayoutSystem.horizontalSpace(DesignTokens.space2),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tag.name,
                                  style: DesignTextStyles.body.copyWith(
                                    fontWeight: DesignTokens.fontWeightMedium,
                                  ),
                                ),
                                if (tag.description != null) ...[
                                  LayoutSystem.verticalSpace(DesignTokens.space1),
                                  Text(
                                    tag.description!,
                                    style: DesignTextStyles.caption,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          DesignSystemComponents.statusBadge(
                            text: '$usageCount',
                            type: SemanticColorType.info,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => DesignSystemComponents.loadingIndicator(
              message: 'Loading statistics...',
            ),
            error: (error, stack) => Text('Error: $error'),
          ),
          loading: () => DesignSystemComponents.loadingIndicator(
            message: 'Loading tags...',
          ),
          error: (error, stack) => Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildTagFilter(List<TagModel> tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filter by tags:',
          style: DesignTextStyles.body.copyWith(
            fontWeight: DesignTokens.fontWeightMedium,
          ),
        ),
        LayoutSystem.verticalSpace(DesignTokens.space1),
        Wrap(
          spacing: DesignTokens.space1,
          runSpacing: DesignTokens.space1,
          children: [
            ...tags.map((tag) {
              final isSelected = _selectedTagFilter.contains(tag.id);
              return TagChip(
                key: ValueKey('filter_tag_${tag.id}_${tag.name}_${tag.color}'),
                tag: tag,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedTagFilter.remove(tag.id);
                    } else {
                      _selectedTagFilter.add(tag.id);
                    }
                  });
                  Future.microtask(() {
                    logger.i('Invalidating providers for tag selection: $_selectedTagFilter');
                    
                    if (_selectedTagFilter.isNotEmpty) {
                      ref.invalidate(clientsWithTagsProvider(_selectedTagFilter));
                    }
                    
                    ref.invalidate(allClientsWithTagsProvider);
                  });
                },
              );
            }),
            if (_selectedTagFilter.isNotEmpty)
              DesignSystemComponents.secondaryButton(
                text: 'Clear',
                icon: FluentIcons.clear,
                onPressed: () {
                  setState(() {
                    _selectedTagFilter.clear();
                  });
                  Future.microtask(() {
                    ref.invalidate(allClientsWithTagsProvider);
                  });
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTagList(List<TagModel> tags, Map<int, int> usageStats) {
    if (tags.isEmpty) {
      return DesignSystemComponents.emptyState(
        title: 'No Tags Available',
        message: 'Create your first tag!',
        icon: FluentIcons.tag,
        actionText: 'Create Tag',
        onAction: () => _showTagDialog(),
      );
    }

    return ListView.builder(
      key: ValueKey('tags_${tags.length}_${DateTime.now().millisecondsSinceEpoch ~/ 1000}'),
      itemCount: tags.length,
      itemBuilder: (context, index) {
        final tag = tags[index];
        final usageCount = usageStats[tag.id] ?? 0;
        final isSelected = ref.watch(tagManagementProvider).selectedTags.contains(tag.id);

        return Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.space2),
          child: DesignSystemComponents.standardCard(
            isSelected: isSelected,
            onTap: () => ref.read(tagManagementProvider.notifier).selectTag(tag.id),
            child: Row(
              children: [
                Checkbox(
                  checked: isSelected,
                  onChanged: (checked) {
                    ref.read(tagManagementProvider.notifier).selectTag(tag.id);
                  },
                ),
                LayoutSystem.horizontalSpace(DesignTokens.space2),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(int.parse('0xFF${tag.color.substring(1)}')),
                    shape: BoxShape.circle,
                  ),
                ),
                LayoutSystem.horizontalSpace(DesignTokens.space2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tag.name,
                        style: DesignTextStyles.body.copyWith(
                          fontWeight: DesignTokens.fontWeightMedium,
                        ),
                      ),
                      if (tag.description != null) ...[
                        LayoutSystem.verticalSpace(DesignTokens.space1),
                        Text(
                          tag.description!,
                          style: DesignTextStyles.caption,
                        ),
                      ],
                      LayoutSystem.verticalSpace(DesignTokens.space1),
                      Text(
                        'Used by $usageCount clients',
                        style: DesignTextStyles.caption.copyWith(
                          color: DesignTokens.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DesignSystemComponents.secondaryButton(
                      text: 'Edit',
                      icon: FluentIcons.edit,
                      onPressed: () => _showTagDialog(tag),
                    ),
                    LayoutSystem.horizontalSpace(DesignTokens.space1),
                    DesignSystemComponents.dangerButton(
                      text: 'Delete',
                      icon: FluentIcons.delete,
                      onPressed: () => _showDeleteTagDialog(tag),
                      requireConfirmation: true,
                      confirmationTitle: 'Delete Tag',
                      confirmationMessage: 'Are you sure you want to delete the tag "${tag.name}"? This will remove it from all clients.',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _refreshAllData() {
    ref.invalidate(allTagsProvider);
    ref.invalidate(allClientsWithTagsProvider);
    ref.invalidate(tagUsageStatsProvider);
    
    if (_selectedTagFilter.isNotEmpty) {
      ref.invalidate(clientsWithTagsProvider(_selectedTagFilter));
    }
  }

  void _showTagDialog([TagModel? tag]) {
    showDialog(
      context: context,
      builder: (context) => TagFormDialog(tag: tag),
    ).then((_) {
      // Force refresh after dialog closes
      _refreshAllData();
    });
  }

  void _showBulkOperationsPanel() {
    showDialog(
      context: context,
      builder: (context) => const BulkTagOperationsPanel(),
    );
  }

  void _showClientTagDialog(int clientId, String clientName) {
    showDialog(
      context: context,
      builder: (context) => ClientTagDialog(
        clientId: clientId,
        clientName: clientName,
      ),
    ).then((_) {
      // Force refresh after dialog closes
      _refreshAllData();
    });
  }

  void _showDeleteTagDialog(TagModel tag) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Delete Tag'),
        content: Text('Are you sure you want to delete the tag "${tag.name}"? This will remove it from all clients.'),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            child: const Text('Delete'),
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(tagDaoProvider).deleteTag(tag.id);
                
                // Force immediate refresh
                _refreshAllData();
                
                if (context.mounted) {
                  displayInfoBar(
                    context,
                    builder: (context, close) => InfoBar(
                      title: const Text('Tag deleted'),
                      content: Text('The tag "${tag.name}" has been deleted.'),
                      severity: InfoBarSeverity.success,
                      onClose: close,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  displayInfoBar(
                    context,
                    builder: (context, close) => InfoBar(
                      title: const Text('Error'),
                      content: Text('Failed to delete tag: $e'),
                      severity: InfoBarSeverity.error,
                      onClose: close,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _removeTagFromClient(int clientId, int tagId) async {
    try {
      await ref.read(tagDaoProvider).removeTagFromClient(clientId, tagId);
      
      // Force immediate refresh
      _refreshAllData();
      
      if (mounted) {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Tag removed'),
            content: const Text('Tag has been removed from client.'),
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
            title: const Text('Error'),
            content: Text('Failed to remove tag: $e'),
            severity: InfoBarSeverity.error,
            onClose: close,
          ),
        );
      }
    }
  }
}

class ClientTagDialog extends ConsumerStatefulWidget {
  final int clientId;
  final String clientName;

  const ClientTagDialog({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  ConsumerState<ClientTagDialog> createState() => _ClientTagDialogState();
}

class _ClientTagDialogState extends ConsumerState<ClientTagDialog> {
  final Set<int> _selectedTags = {};

  @override
  Widget build(BuildContext context) {
    final allTagsAsync = ref.watch(allTagsProvider);
    final clientTagsAsync = ref.watch(tagsForClientProvider(widget.clientId));

    return ContentDialog(
      title: Text('Manage Tags for ${widget.clientName}'),
      content: SizedBox(
        width: 400,
        height: 300,
        child: allTagsAsync.when(
          data: (allTags) => clientTagsAsync.when(
            data: (clientTags) {
              final clientTagIds = clientTags.map((t) => t.id).toSet();
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select tags to assign:'),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: allTags.length,
                      itemBuilder: (context, index) {
                        final tag = allTags[index];
                        final isCurrentlyAssigned = clientTagIds.contains(tag.id);
                        final isToggled = _selectedTags.contains(tag.id);
                        final willBeAssigned = isCurrentlyAssigned || isToggled;
                        final willBeRemoved = isCurrentlyAssigned && isToggled;
                        final checked = willBeAssigned && !willBeRemoved;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isCurrentlyAssigned) {
                                // Toggle removal
                                if (_selectedTags.contains(tag.id)) {
                                  _selectedTags.remove(tag.id);
                                } else {
                                  _selectedTags.add(tag.id);
                                }
                              } else {
                                // Toggle addition
                                if (_selectedTags.contains(tag.id)) {
                                  _selectedTags.remove(tag.id);
                                } else {
                                  _selectedTags.add(tag.id);
                                }
                              }
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Fluent UI checkbox
                                Checkbox(
                                  checked: checked,
                                  onChanged: (value) {
                                    setState(() {
                                      if (isCurrentlyAssigned) {
                                        if (_selectedTags.contains(tag.id)) {
                                          _selectedTags.remove(tag.id);
                                        } else {
                                          _selectedTags.add(tag.id);
                                        }
                                      } else {
                                        if (_selectedTags.contains(tag.id)) {
                                          _selectedTags.remove(tag.id);
                                        } else {
                                          _selectedTags.add(tag.id);
                                        }
                                      }
                                    });
                                  },
                                ),

                                const SizedBox(width: 12),

                                // Tag content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Title row: color dot + name + status hint
                                      Row(
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: Color(
                                                int.parse('0xFF${tag.color.substring(1)}'),
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(tag.name),
                                          if (willBeRemoved) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              '(will be removed)',
                                              style: TextStyle(color: Colors.red),
                                            ),
                                          ] else if (isToggled && !isCurrentlyAssigned) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              '(will be added)',
                                              style: TextStyle(color: Colors.green),
                                            ),
                                          ],
                                        ],
                                      ),

                                      // Optional subtitle
                                      if (tag.description != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          tag.description!,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                ],
              );
            },
            loading: () => const Center(child: ProgressRing()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
          loading: () => const Center(child: ProgressRing()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
      actions: [
        Button(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        FilledButton(
          onPressed: _selectedTags.isEmpty ? null : () async {
            Navigator.of(context).pop();
            await _applyTagChanges();
          },
          child: const Text('Apply Changes'),
        ),
      ],
    );
  }

  Future<void> _applyTagChanges() async {
    try {
      final dao = ref.read(tagDaoProvider);
      final clientTags = await ref.read(tagsForClientProvider(widget.clientId).future);
      final currentTagIds = clientTags.map((t) => t.id).toSet();

      for (final tagId in _selectedTags) {
        if (currentTagIds.contains(tagId)) {
          // Remove tag
          await dao.removeTagFromClient(widget.clientId, tagId);
        } else {
          // Add tag
          await dao.addTagToClient(widget.clientId, tagId);
        }
      }

      // Force immediate refresh of relevant providers
      Future.microtask(() {
        ref.invalidate(tagsForClientProvider(widget.clientId));
        ref.invalidate(clientTagsProvider(widget.clientId));
        ref.invalidate(allClientsWithTagsProvider);
        ref.invalidate(tagUsageStatsProvider);
        ref.invalidate(allTagsProvider);
      });

      if (mounted) {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Tags updated'),
            content: const Text('Client tags have been updated successfully.'),
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
            title: const Text('Error'),
            content: Text('Failed to update tags: $e'),
            severity: InfoBarSeverity.error,
            onClose: close,
          ),
        );
      }
    }
  }
}