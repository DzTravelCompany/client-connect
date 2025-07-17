import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/client_activity_model.dart';
import '../../logic/client_activity_providers.dart';

class ClientActivityTimeline extends ConsumerWidget {
  final int clientId;

  const ClientActivityTimeline({
    super.key,
    required this.clientId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final activitiesAsync = ref.watch(clientActivitiesProvider(clientId));

    return activitiesAsync.when(
      data: (activities) => _buildTimeline(activities, theme),
      loading: () => const Center(child: ProgressRing()),
      error: (error, stack) => _buildErrorState(error.toString(), theme),
    );
  }

  Widget _buildTimeline(List<ClientActivityModel> activities, FluentThemeData theme) {
    if (activities.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        final isLast = index == activities.length - 1;
        
        return _buildTimelineItem(activity, isLast, theme);
      },
    );
  }

  Widget _buildTimelineItem(ClientActivityModel activity, bool isLast, FluentThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getActivityColor(activity.activityType),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.resources.cardBackgroundFillColorDefault,
                  width: 2,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: theme.resources.dividerStrokeColorDefault.withValues(alpha: 0.3),
              ),
          ],
        ),
        const SizedBox(width: 12),
        
        // Activity content
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getActivityIcon(activity.activityType),
                      size: 14,
                      color: _getActivityColor(activity.activityType),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        activity.description,
                        style: theme.typography.body?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _formatActivityDate(activity.createdAt),
                  style: theme.typography.caption?.copyWith(
                    color: theme.resources.textFillColorSecondary,
                  ),
                ),
                if (activity.metadata != null && activity.metadata!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _buildMetadataChips(activity.metadata!, theme),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataChips(Map<String, dynamic> metadata, FluentThemeData theme) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: metadata.entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: theme.resources.cardBackgroundFillColorSecondary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${entry.key}: ${entry.value}',
            style: TextStyle(
              fontSize: 10,
              color: theme.resources.textFillColorSecondary,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(FluentThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            FluentIcons.timeline,
            size: 48,
            color: theme.resources.textFillColorSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            'No activity yet',
            style: theme.typography.subtitle?.copyWith(
              color: theme.resources.textFillColorSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Client activities will appear here',
            style: theme.typography.body?.copyWith(
              color: theme.resources.textFillColorTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, FluentThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            FluentIcons.error,
            size: 48,
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          Text(
            'Error loading activities',
            style: theme.typography.subtitle,
          ),
          const SizedBox(height: 4),
          Text(
            error,
            style: theme.typography.body?.copyWith(
              color: theme.resources.textFillColorSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(ClientActivityType type) {
    switch (type) {
      case ClientActivityType.created:
        return Colors.green;
      case ClientActivityType.updated:
        return Colors.blue;
      case ClientActivityType.emailSent:
        return Colors.purple;
      case ClientActivityType.campaignSent:
        return Colors.orange;
      case ClientActivityType.tagAdded:
        return Colors.teal;
      case ClientActivityType.tagRemoved:
        return Colors.red;
      case ClientActivityType.noteAdded:
        return Colors.yellow;
      case ClientActivityType.exported:
        return Colors.grey;
      case ClientActivityType.imported:
        return Color(0xFF00FFFF); // cyan color
    }
  }

  IconData _getActivityIcon(ClientActivityType type) {
    switch (type) {
      case ClientActivityType.created:
        return FluentIcons.add;
      case ClientActivityType.updated:
        return FluentIcons.edit;
      case ClientActivityType.emailSent:
        return FluentIcons.mail;
      case ClientActivityType.campaignSent:
        return FluentIcons.send;
      case ClientActivityType.tagAdded:
        return FluentIcons.tag;
      case ClientActivityType.tagRemoved:
        return FluentIcons.remove;
      case ClientActivityType.noteAdded:
        return FluentIcons.note_forward;
      case ClientActivityType.exported:
        return FluentIcons.download;
      case ClientActivityType.imported:
        return FluentIcons.upload;
    }
  }

  String _formatActivityDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}