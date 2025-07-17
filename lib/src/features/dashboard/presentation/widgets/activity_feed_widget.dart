import 'package:fluent_ui/fluent_ui.dart';

class ActivityFeedWidget extends StatelessWidget {
  final List<ActivityItem> activities;

  const ActivityFeedWidget({
    super.key,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Recent Activity',
                style: theme.typography.bodyStrong?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Button(
              style: ButtonStyle(
                padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
              ),
              onPressed: () {},
              child: Text(
                'View All',
                style: theme.typography.caption?.copyWith(
                  color: theme.accentColor,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Expanded(
          child: activities.isEmpty 
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      FluentIcons.timeline,
                      size: 48,
                      color: theme.resources.textFillColorTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No recent activity',
                      style: theme.typography.body?.copyWith(
                        color: theme.resources.textFillColorSecondary,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: activities.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return _ActivityTile(activity: activity);
                },
              ),
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityItem activity;

  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.resources.cardBackgroundFillColorSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.resources.dividerStrokeColorDefault.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: activity.iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              activity.icon,
              size: 16,
              color: activity.iconColor,
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: theme.typography.body?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(
                  activity.subtitle,
                  style: theme.typography.caption?.copyWith(
                    color: theme.resources.textFillColorSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          Text(
            activity.timeAgo,
            style: theme.typography.caption?.copyWith(
              color: theme.resources.textFillColorTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class ActivityItem {
  final String title;
  final String subtitle;
  final String timeAgo;
  final IconData icon;
  final Color iconColor;

  ActivityItem({
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    required this.icon,
    required this.iconColor,
  });
}