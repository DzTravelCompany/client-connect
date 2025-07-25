import 'package:fluent_ui/fluent_ui.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/component_library.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final String? trend;
  final bool? isPositiveTrend;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.iconColor,
    this.trend,
    this.isPositiveTrend,
  });

  @override
  Widget build(BuildContext context) {
    return DesignSystemComponents.glassmorphismCard(
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
                      iconColor.withValues(alpha: 0.15),
                      iconColor.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: DesignTokens.iconSizeMedium,
                  color: iconColor,
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
          SizedBox(height: DesignTokens.space4),
          Text(
            value,
            style: DesignTextStyles.display.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
              color: DesignTokens.textPrimary,
            ),
          ),
          SizedBox(height: DesignTokens.space1),
          Text(
            title,
            style: DesignTextStyles.bodyLarge.copyWith(
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
