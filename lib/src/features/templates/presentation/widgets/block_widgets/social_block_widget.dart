import 'package:client_connect/constants.dart';
import 'package:client_connect/src/features/templates/data/template_block_model.dart';
import 'package:fluent_ui/fluent_ui.dart';

class SocialBlockWidget extends StatelessWidget {
  final SocialBlock block;
  final TemplateType? templateType;

  const SocialBlockWidget({
    super.key, 
    required this.block,
    this.templateType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    
    return Container(
      padding: _getPlatformPadding(),
      child: block.socialLinks.isEmpty
          ? _buildEmptyState(theme)
          : _buildSocialLinks(theme),
    );
  }

  EdgeInsets _getPlatformPadding() {
    switch (templateType) {
      case TemplateType.whatsapp:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case TemplateType.email:
        return const EdgeInsets.all(16);
      default:
        return const EdgeInsets.all(16);
    }
  }

  Widget _buildEmptyState(FluentThemeData theme) {
    return Container(
      padding: _getEmptyStatePadding(),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.accentColor.withValues(alpha: 0.5),
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Icon(
            FluentIcons.share,
            size: _getEmptyStateIconSize(),
            color: theme.inactiveColor,
          ),
          SizedBox(height: _getEmptyStateSpacing()),
          Text(
            'Social Links',
            style: TextStyle(
              color: theme.inactiveColor,
              fontWeight: FontWeight.w500,
              fontSize: _getEmptyStateTextSize(),
            ),
          ),
          Text(
            'No social links added',
            style: TextStyle(
              color: theme.inactiveColor,
              fontSize: _getEmptyStateTextSize() - 2,
            ),
          ),
        ],
      ),
    );
  }

  EdgeInsets _getEmptyStatePadding() {
    switch (templateType) {
      case TemplateType.whatsapp:
        return const EdgeInsets.all(16);
      case TemplateType.email:
        return const EdgeInsets.all(20);
      default:
        return const EdgeInsets.all(20);
    }
  }

  double _getEmptyStateIconSize() {
    switch (templateType) {
      case TemplateType.whatsapp:
        return 24;
      case TemplateType.email:
        return 32;
      default:
        return 32;
    }
  }

  double _getEmptyStateSpacing() {
    switch (templateType) {
      case TemplateType.whatsapp:
        return 6;
      case TemplateType.email:
        return 8;
      default:
        return 8;
    }
  }

  double _getEmptyStateTextSize() {
    switch (templateType) {
      case TemplateType.whatsapp:
        return 12;
      case TemplateType.email:
        return 14;
      default:
        return 14;
    }
  }

  Widget _buildSocialLinks(FluentThemeData theme) {
    final adjustedIconSize = _getAdjustedIconSize();
    
    if (block.layout == 'horizontal') {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _buildSocialIcons(theme, adjustedIconSize),
        ),
      );
    } else {
      return Column(
        children: _buildSocialIcons(theme, adjustedIconSize),
      );
    }
  }

  double _getAdjustedIconSize() {
    final baseSize = block.iconSize;
    
    // Adjust icon size based on platform
    switch (templateType) {
      case TemplateType.whatsapp:
        return baseSize > 32 ? 32 : (baseSize < 16 ? 16 : baseSize);
      case TemplateType.email:
        return baseSize > 40 ? 40 : (baseSize < 20 ? 20 : baseSize);
      default:
        return baseSize;
    }
  }

  List<Widget> _buildSocialIcons(FluentThemeData theme, double iconSize) {
    return block.socialLinks.map((link) {
      final platform = link['platform'] ?? 'unknown';
      final url = link['url'] ?? '';
      
      return Container(
        margin: EdgeInsets.all(_getIconMargin()),
        child: HoverButton(
          onPressed: () => _handleSocialClick(platform, url),
          builder: (context, states) {
            final isHovering = states.contains(WidgetState.hovered);
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: isHovering
                    ? _getPlatformColor(platform)
                    : _getPlatformColor(platform).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(
                  block.style == 'buttons' ? _getButtonRadius() : iconSize / 2,
                ),
                boxShadow: _getSocialShadow(platform, isHovering),
              ),
              child: Icon(
                _getPlatformIcon(platform),
                size: iconSize * 0.6,
                color: Colors.white,
              ),
            );
          },
        ),
      );
    }).toList();
  }

  double _getIconMargin() {
    switch (templateType) {
      case TemplateType.whatsapp:
        return 3;
      case TemplateType.email:
        return 4;
      default:
        return 4;
    }
  }

  double _getButtonRadius() {
    switch (templateType) {
      case TemplateType.whatsapp:
        return 8; // More rounded for mobile
      case TemplateType.email:
        return 6; // Conservative for email
      default:
        return 6;
    }
  }

  List<BoxShadow>? _getSocialShadow(String platform, bool isHovering) {
    if (!isHovering) return null;
    
    final shadowColor = _getPlatformColor(platform);
    
    switch (templateType) {
      case TemplateType.whatsapp:
        return [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ];
      case TemplateType.email:
        return [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ];
      default:
        return [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];
    }
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'facebook':
        return FluentIcons.share;
      case 'twitter':
      case 'x':
        return FluentIcons.share;
      case 'instagram':
        return FluentIcons.share;
      case 'linkedin':
        return FluentIcons.share;
      case 'youtube':
        return FluentIcons.video;
      case 'tiktok':
        return FluentIcons.video;
      case 'whatsapp':
        return FluentIcons.chat;
      case 'telegram':
        return FluentIcons.chat;
      default:
        return FluentIcons.share;
    }
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'twitter':
      case 'x':
        return const Color(0xFF000000);
      case 'instagram':
        return const Color(0xFFE4405F);
      case 'linkedin':
        return const Color(0xFF0A66C2);
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'tiktok':
        return const Color(0xFF000000);
      case 'whatsapp':
        return const Color(0xFF25D366);
      case 'telegram':
        return const Color(0xFF0088CC);
      default:
        return const Color(0xFF6B7280);
    }
  }

  void _handleSocialClick(String platform, String url) {
    // In preview mode, just show the URL
    logger.i('Social link clicked: $platform - $url');
  }
}
