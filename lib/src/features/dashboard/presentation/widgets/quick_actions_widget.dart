import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/component_library.dart';

class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return DesignSystemComponents.glassmorphismCard(
      padding: EdgeInsets.all(DesignTokens.space4),
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
                      DesignTokens.accentPrimary,
                      DesignTokens.accentSecondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: DesignTokens.accentPrimary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  FluentIcons.lightning_bolt,
                  size: DesignTokens.iconSizeMedium,
                  color: DesignTokens.textInverse,
                ),
              ),
              SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: DesignTextStyles.subtitle.copyWith(
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                    ),
                    SizedBox(height: DesignTokens.space1),
                    Text(
                      'Common tasks and shortcuts',
                      style: DesignTextStyles.caption.copyWith(
                        color: DesignTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.space4),
          
          // Quick Action Items
          Expanded(
            child: Column(
              children: [
                _buildQuickActionItem(
                  context,
                  'Add New Client',
                  'Create a new client profile',
                  FluentIcons.reminder_person,
                  DesignTokens.accentPrimary,
                  () => context.go('/clients/add'),
                ),
                SizedBox(height: DesignTokens.space3),
                _buildQuickActionItem(
                  context,
                  'Create Campaign',
                  'Start a new marketing campaign',
                  FluentIcons.send,
                  DesignTokens.semanticInfo,
                  () => context.go('/campaigns/create'),
                ),
                SizedBox(height: DesignTokens.space3),
                _buildQuickActionItem(
                  context,
                  'New Template',
                  'Design a message template',
                  FluentIcons.page,
                  DesignTokens.semanticWarning,
                  () => context.go('/templates/editor'),
                ),
                SizedBox(height: DesignTokens.space3),
                _buildQuickActionItem(
                  context,
                  'View Analytics',
                  'Check performance metrics',
                  FluentIcons.analytics_report,
                  DesignTokens.semanticSuccess,
                  () => context.go('/analytics'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return DesignSystemComponents.standardCard(
      onTap: onTap,
      isHoverable: true,
      padding: EdgeInsets.all(DesignTokens.space4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              icon,
              size: DesignTokens.iconSizeMedium,
              color: color,
            ),
          ),
          SizedBox(width: DesignTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DesignTextStyles.body.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
                SizedBox(height: DesignTokens.space1),
                Text(
                  subtitle,
                  style: DesignTextStyles.caption.copyWith(
                    color: DesignTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            FluentIcons.chevron_right,
            size: DesignTokens.iconSizeSmall,
            color: DesignTokens.textTertiary,
          ),
        ],
      ),
    );
  }
}