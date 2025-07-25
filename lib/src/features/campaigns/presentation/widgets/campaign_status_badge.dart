import 'package:fluent_ui/fluent_ui.dart';
import '../../data/campaigns_model.dart';

enum CampaignStatusBadgeSize { small, medium, large }

class CampaignStatusBadge extends StatelessWidget {
  final CampaignModel campaign;
  final CampaignStatusBadgeSize size;
  final bool showIcon;
  final bool showText;

  const CampaignStatusBadge({
    super.key,
    required this.campaign,
    this.size = CampaignStatusBadgeSize.medium,
    this.showIcon = true,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = campaign.statusColor;
    final icon = campaign.statusIcon;
    final text = campaign.statusDisplayName;
    
    final double iconSize;
    final double fontSize;
    final EdgeInsets padding;
    
    switch (size) {
      case CampaignStatusBadgeSize.small:
        iconSize = 10;
        fontSize = 8;
        padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
        break;
      case CampaignStatusBadgeSize.medium:
        iconSize = 12;
        fontSize = 10;
        padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
        break;
      case CampaignStatusBadgeSize.large:
        iconSize = 16;
        fontSize = 12;
        padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
        break;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(icon, size: iconSize, color: color),
            if (showText) SizedBox(width: size == CampaignStatusBadgeSize.small ? 2 : 4),
          ],
          if (showText)
            Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}
