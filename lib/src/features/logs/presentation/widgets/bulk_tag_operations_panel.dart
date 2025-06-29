import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/tag_providers.dart';
import 'tag_chip.dart';

class BulkTagOperationsPanel extends ConsumerWidget {
  const BulkTagOperationsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagManagementState = ref.watch(tagManagementProvider);
    final allTagsAsync = ref.watch(allTagsProvider);

    return ContentDialog(
      title: const Text('Bulk Tag Operations'),
      content: SizedBox(
        width: 500,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected clients info
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
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Selected tags info
            if (tagManagementState.selectedTags.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          FluentIcons.tag,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${tagManagementState.selectedTags.length} tags selected for operation',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    allTagsAsync.when(
                      data: (allTags) {
                        final selectedTags = allTags.where((tag) => 
                          tagManagementState.selectedTags.contains(tag.id)
                        ).toList();
                        
                        return Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: selectedTags.map((tag) => TagChip(
                            tag: tag,
                            size: TagChipSize.small,
                          )).toList(),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (error, stack) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Available tags
            const Text('Select tags for bulk operation:'),
            const SizedBox(height: 8),
            
            Expanded(
              child: allTagsAsync.when(
                data: (tags) {
                  if (tags.isEmpty) {
                    return const Center(
                      child: Text('No tags available. Create tags first.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: tags.length,
                    itemBuilder: (context, index) {
                      final tag = tags[index];
                      final isSelected = tagManagementState.selectedTags.contains(tag.id);

                      return GestureDetector(
                        onTap: () {
                          // Toggle selection when tapping the row
                          ref.read(tagManagementProvider.notifier).selectTag(tag.id);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Fluent UI checkbox
                              Checkbox(
                                checked: isSelected,
                                onChanged: (checked) {
                                  ref.read(tagManagementProvider.notifier).selectTag(tag.id);
                                },
                              ),

                              const SizedBox(width: 12),

                              // Tag icon + name + optional subtitle
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                                      ],
                                    ),
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
                  );
                },
                loading: () => const Center(child: ProgressRing()),
                error: (error, stack) => Center(
                  child: Text('Error loading tags: $error'),
                ),
              ),
            ),


            const SizedBox(height: 16),

            // Operation buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: tagManagementState.selectedClients.isEmpty ||
                            tagManagementState.selectedTags.isEmpty ||
                            tagManagementState.isLoading
                        ? null
                        : () async {
                            await ref.read(tagManagementProvider.notifier).addTagsToSelectedClients();
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                    child: tagManagementState.isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: ProgressRing(strokeWidth: 2),
                              ),
                              SizedBox(width: 8),
                              Text('Processing...'),
                            ],
                          )
                        : const Text('Add Tags to Clients'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Button(
                    onPressed: tagManagementState.selectedClients.isEmpty ||
                            tagManagementState.selectedTags.isEmpty ||
                            tagManagementState.isLoading
                        ? null
                        : () async {
                            await ref.read(tagManagementProvider.notifier).removeTagsFromSelectedClients();
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                    child: const Text('Remove Tags from Clients'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        Button(
          child: const Text('Close'),
          onPressed: () {
            ref.read(tagManagementProvider.notifier).clearSelectedTags();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}