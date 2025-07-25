import 'package:client_connect/src/core/realtime/realtime_dashboard_service.dart';
import 'package:fluent_ui/fluent_ui.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/component_library.dart';

class ActivityFeedWidget extends StatelessWidget {
  final List<ActivityItem> activities;

  const ActivityFeedWidget({
    super.key,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    return DesignSystemComponents.standardCard(
      padding: EdgeInsets.all(DesignTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
                      FluentIcons.timeline,
                      size: DesignTokens.iconSizeMedium,
                      color: DesignTokens.accentPrimary,
                    ),
                  ),
                  SizedBox(width: DesignTokens.space3),
                  Text(
                    'Recent Activity',
                    style: DesignTextStyles.subtitle.copyWith(
                      fontWeight: DesignTokens.fontWeightSemiBold,
                    ),
                  ),
                ],
              ),
              DesignSystemComponents.secondaryButton(
                text: 'View All',
                onPressed: () {},
              ),
            ],
          ),
          
          SizedBox(height: DesignTokens.space4),
          
          Expanded(
            child: activities.isEmpty 
              ? DesignSystemComponents.emptyState(
                  title: 'No recent activity',
                  message: 'Activity will appear here as it happens',
                  icon: FluentIcons.timeline,
                  iconColor: DesignTokens.textTertiary,
                )
              : ListView.separated(
                  itemCount: activities.length,
                  separatorBuilder: (context, index) => SizedBox(height: DesignTokens.space3),
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return _ActivityTile(activity: activity);
                  },
                ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityItem activity;

  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    return DesignSystemComponents.standardCard(
      padding: EdgeInsets.all(DesignTokens.space3),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  activity.iconColor.withValues(alpha: 0.15),
                  activity.iconColor.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusRound),
            ),
            child: Icon(
              activity.icon,
              size: DesignTokens.iconSizeSmall,
              color: activity.iconColor,
            ),
          ),
          
          SizedBox(width: DesignTokens.space3),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: DesignTextStyles.body.copyWith(
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                SizedBox(height: DesignTokens.space1),
                Text(
                  activity.subtitle,
                  style: DesignTextStyles.caption.copyWith(
                    color: DesignTokens.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          
          SizedBox(width: DesignTokens.space2),
          
          Text(
            activity.timeAgo,
            style: DesignTextStyles.caption.copyWith(
              color: DesignTokens.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// class ActivityItem {
//   final String title;
//   final String subtitle;
//   final String timeAgo;
//   final IconData icon;
//   final Color iconColor;

//   ActivityItem({
//     required this.title,
//     required this.subtitle,
//     required this.timeAgo,
//     required this.icon,
//     required this.iconColor,
//   });
// }
