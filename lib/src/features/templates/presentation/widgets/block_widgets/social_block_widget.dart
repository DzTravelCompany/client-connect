import 'package:client_connect/constants.dart';
import 'package:client_connect/src/features/templates/data/template_block_model.dart';
import 'package:fluent_ui/fluent_ui.dart';


class SocialBlockWidget extends StatelessWidget {
  final SocialBlock block;

  const SocialBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: block.socialLinks.isEmpty
          ? _buildEmptyState(theme)
          : _buildSocialLinks(theme),
    );
  }

  Widget _buildEmptyState(FluentThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
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
            size: 32,
            color: theme.inactiveColor,
          ),
          const SizedBox(height: 8),
          Text(
            'Social Links',
            style: TextStyle(
              color: theme.inactiveColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'No social links added',
            style: TextStyle(
              color: theme.inactiveColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLinks(FluentThemeData theme) {
    if (block.layout == 'horizontal') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _buildSocialIcons(theme),
      );
    } else {
      return Column(
        children: _buildSocialIcons(theme),
      );
    }
  }

  List<Widget> _buildSocialIcons(FluentThemeData theme) {
    return block.socialLinks.map((link) {
      final platform = link['platform'] ?? 'unknown';
      final url = link['url'] ?? '';
      
      return Container(
        margin: const EdgeInsets.all(4),
        child: HoverButton(
          onPressed: () => _handleSocialClick(platform, url),
          builder: (context, states) {
            final isHovering = states.contains(WidgetState.hovered);
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: block.iconSize,
              height: block.iconSize,
              decoration: BoxDecoration(
                color: isHovering
                    ? _getPlatformColor(platform)
                    : _getPlatformColor(platform).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(
                  block.style == 'buttons' ? 6 : block.iconSize / 2,
                ),
                boxShadow: isHovering
                    ? [
                        BoxShadow(
                          color: _getPlatformColor(platform).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                _getPlatformIcon(platform),
                size: block.iconSize * 0.6,
                color: Colors.white,
              ),
            );
          },
        ),
      );
    }).toList();
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'facebook':
        return FluentIcons.share;
      case 'twitter':
        return FluentIcons.share;
      case 'instagram':
        return FluentIcons.share;
      case 'linkedin':
        return FluentIcons.share;
      case 'youtube':
        return FluentIcons.video;
      case 'tiktok':
        return FluentIcons.video;
      default:
        return FluentIcons.share;
    }
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'twitter':
        return const Color(0xFF1DA1F2);
      case 'instagram':
        return const Color(0xFFE4405F);
      case 'linkedin':
        return const Color(0xFF0A66C2);
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'tiktok':
        return const Color(0xFF000000);
      default:
        return const Color(0xFF6B7280);
    }
  }

  void _handleSocialClick(String platform, String url) {
    // In preview mode, just show the URL
    logger.i('Social link clicked: $platform - $url');
  }
}