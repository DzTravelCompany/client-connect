import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../logic/tag_providers.dart';
import '../data/tag_model.dart';
import 'widgets/tag_chip.dart';
import 'widgets/tag_form_dialog.dart';
import 'widgets/bulk_tag_operations_panel.dart';

class TagManagementScreen extends ConsumerStatefulWidget {
  const TagManagementScreen({super.key});

  @override
  ConsumerState<TagManagementScreen> createState() => _TagManagementScreenState();
}

class _TagManagementScreenState extends ConsumerState<TagManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  final List<int> _selectedTagFilter = [];

  @override
  void dispose() {
    _searchController.dispose();
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
      header: PageHeader(
        title: const Text('Tag Management'),
        commandBar: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.add),
              label: const Text('New Tag'),
              onPressed: () => _showTagDialog(),
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.bulk_upload),
              label: const Text('Bulk Operations'),
              onPressed: () => _showBulkOperationsPanel(),
            ),
          ],
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Status messages
            if (tagManagementState.error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(FluentIcons.error, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tagManagementState.error!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(FluentIcons.clear, size: 16, color: Colors.white),
                      onPressed: () => ref.read(tagManagementProvider.notifier).clearMessages(),
                    ),
                  ],
                ),
              ),

            if (tagManagementState.successMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(FluentIcons.check_mark, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tagManagementState.successMessage!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(FluentIcons.clear, size: 16, color: Colors.white),
                      onPressed: () => ref.read(tagManagementProvider.notifier).clearMessages(),
                    ),
                  ],
                ),
              ),

            Row(
              children: [
                // Search bar
                Expanded(
                  flex: 2,
                  child: TextBox(
                    controller: _searchController,
                    placeholder: 'Search clients...',
                    prefix: const Icon(FluentIcons.search),
                    onChanged: (value) {
                      setState(() {
                        _searchTerm = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                
                // Tag filter
                Expanded(
                  flex: 3,
                  child: tagsAsync.when(
                    data: (tags) => _buildTagFilter(tags),
                    loading: () => const ProgressRing(),
                    error: (error, stack) => Text('Error: $error'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Selected clients info
            if (tagManagementState.selectedClients.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FluentTheme.of(context).accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: FluentTheme.of(context).accentColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      FluentIcons.people,
                      size: 16,
                      color: FluentTheme.of(context).accentColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${tagManagementState.selectedClients.length} clients selected',
                      style: TextStyle(
                        color: FluentTheme.of(context).accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Button(
                      child: const Text('Clear Selection'),
                      onPressed: () => ref.read(tagManagementProvider.notifier).clearSelectedClients(),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Client list with tags
            Expanded(
              child: Row(
                children: [
                  // Main client list
                  Expanded(
                    flex: 3,
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
                          return const Center(
                            child: Text('No clients found matching your criteria.'),
                          );
                        }

                        return ListView.builder(
                          itemCount: filteredClients.length,
                          itemBuilder: (context, index) {
                            final client = filteredClients[index];
                            final isSelected = tagManagementState.selectedClients.contains(client.id);

                            return Card(
                              backgroundColor: isSelected
                                  ? FluentTheme.of(context).accentColor.withValues(alpha: 0.1)
                                  : null,
                              child: ListTile(
                                leading: Checkbox(
                                  checked: isSelected,
                                  onChanged: (checked) {
                                    ref.read(tagManagementProvider.notifier).selectClient(client.id);
                                  },
                                ),
                                title: Text(client.fullName),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (client.email != null) Text(client.email!),
                                    if (client.company != null) Text(client.company!),
                                    if (client.tags.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                        children: client.tags.map((tag) => TagChip(
                                          tag: tag,
                                          size: TagChipSize.small,
                                          onRemove: () => _removeTagFromClient(client.id, tag.id),
                                        )).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(FluentIcons.tag),
                                      onPressed: () => _showClientTagDialog(client.id, client.fullName),
                                    ),
                                    IconButton(
                                      icon: const Icon(FluentIcons.edit),
                                      onPressed: () => context.go('/clients/edit/${client.id}'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: ProgressRing()),
                      error: (error, stack) => Center(
                        child: Text('Error: $error'),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Tag management sidebar
                  Expanded(
                    flex: 1,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available Tags',
                              style: FluentTheme.of(context).typography.subtitle,
                            ),
                            const SizedBox(height: 12),
                            
                            Expanded(
                              child: tagsAsync.when(
                                data: (tags) => tagUsageStatsAsync.when(
                                  data: (stats) => _buildTagList(tags, stats),
                                  loading: () => _buildTagList(tags, {}),
                                  error: (error, stack) => _buildTagList(tags, {}),
                                ),
                                loading: () => const Center(child: ProgressRing()),
                                error: (error, stack) => Center(
                                  child: Text('Error: $error'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildTagFilter(List<TagModel> tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Filter by tags:'),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            ...tags.map((tag) {
              final isSelected = _selectedTagFilter.contains(tag.id);
              return TagChip(
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
                },
              );
            }),
            if (_selectedTagFilter.isNotEmpty)
              ActionChip(
                avatar: const Icon(FluentIcons.clear, size: 12),
                label: const Text('Clear'),
                onPressed: () {
                  setState(() {
                    _selectedTagFilter.clear();
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
      return const Center(
        child: Text('No tags available. Create your first tag!'),
      );
    }

    return ListView.builder(
      itemCount: tags.length,
      itemBuilder: (context, index) {
        final tag = tags[index];
        final usageCount = usageStats[tag.id] ?? 0;
        final isSelected = ref.watch(tagManagementProvider).selectedTags.contains(tag.id);

        return Card(
          backgroundColor: isSelected
              ? FluentTheme.of(context).accentColor.withValues(alpha: 0.1)
              : null,
          child: ListTile(
            leading: Checkbox(
              checked: isSelected,
              onChanged: (checked) {
                ref.read(tagManagementProvider.notifier).selectTag(tag.id);
              },
            ),
            title: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(int.parse('0xFF${tag.color.substring(1)}')),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(tag.name)),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (tag.description != null) Text(tag.description!),
                Text('Used by $usageCount clients'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(FluentIcons.edit),
                  onPressed: () => _showTagDialog(tag),
                ),
                IconButton(
                  icon: const Icon(FluentIcons.delete),
                  onPressed: () => _showDeleteTagDialog(tag),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTagDialog([TagModel? tag]) {
    showDialog(
      context: context,
      builder: (context) => TagFormDialog(tag: tag),
    );
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
    );
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
