import 'package:fluent_ui/fluent_ui.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/component_library.dart';

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final String? trend;
  final bool? isPositiveTrend;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.trend,
    this.isPositiveTrend,
  });

  @override
  Widget build(BuildContext context) {
    return DesignSystemComponents.standardCard(
      padding: EdgeInsets.all(DesignTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(DesignTokens.space2),
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
              const Spacer(),
              if (trend != null) ...[
                DesignSystemComponents.statusBadge(
                  text: trend!,
                  type: isPositiveTrend == true 
                      ? SemanticColorType.success 
                      : SemanticColorType.error,
                  icon: isPositiveTrend == true 
                      ? FluentIcons.up 
                      : FluentIcons.down,
                ),
              ],
            ],
          ),
          SizedBox(height: DesignTokens.space3),
          Text(
            value,
            style: DesignTextStyles.displayLarge.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
              color: DesignTokens.textPrimary,
            ),
          ),
          SizedBox(height: DesignTokens.space1),
          Text(
            title,
            style: DesignTextStyles.body.copyWith(
              color: DesignTokens.textSecondary,
              fontWeight: DesignTokens.fontWeightMedium,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: DesignTokens.space1),
            Text(
              subtitle!,
              style: DesignTextStyles.caption.copyWith(
                color: DesignTokens.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
