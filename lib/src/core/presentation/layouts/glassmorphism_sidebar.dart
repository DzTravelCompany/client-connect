import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/layout_providers.dart';
import '../../design_system/design_tokens.dart';
import '../../design_system/component_styles.dart';
import '../../design_system/responsive_utils.dart';

class GlassmorphismSidebar extends ConsumerWidget {
  const GlassmorphismSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    final sidebarState = ref.watch(sidebarStateProvider);
    final currentRoute = GoRouterState.of(context).uri.path;
    
    return ResponsiveBuilder(
      builder: (context, responsive) {
        return MouseRegion(
          onEnter: (_) => ref.read(sidebarStateProvider.notifier).setHovered(true),
          onExit: (_) => ref.read(sidebarStateProvider.notifier).setHovered(false),
          child: AnimatedContainer(
            duration: DesignTokens.animationNormal,
            width: ResponsiveUtils.getResponsiveSidebarWidth(context),
            decoration: _buildGlassmorphismDecoration(theme, sidebarState.isHovered),
            child: Column(
              children: [
                _buildHeader(theme, responsive),
                Expanded(
                  child: _buildNavigationItems(context, ref, theme, currentRoute),
                ),
                _buildFooter(theme, responsive),
              ],
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _buildGlassmorphismDecoration(FluentThemeData theme, bool isHovered) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          DesignTokens.getGlassColor(
            DesignTokens.glassPrimary,
            isHovered ? DesignTokens.glassOpacityPrimary : DesignTokens.glassOpacitySecondary,
          ),
          DesignTokens.getGlassColor(
            DesignTokens.glassSecondary,
            isHovered ? DesignTokens.glassOpacitySecondary : DesignTokens.glassOpacityTertiary,
          ),
        ],
      ),
      border: Border(
        right: BorderSide(
          color: DesignTokens.withOpacity(DesignTokens.borderPrimary, 0.3),
          width: 1,
        ),
      ),
      boxShadow: isHovered ? DesignTokens.shadowMedium : DesignTokens.shadowLow,
    );
  }

  Widget _buildHeader(FluentThemeData theme, ResponsiveInfo responsive) {
    return Container(
      padding: EdgeInsets.all(
        responsive.isMobile ? DesignTokens.space4 : DesignTokens.space6,
      ),
      child: Row(
        children: [
          Container(
            width: DesignTokens.avatarSizeLarge,
            height: DesignTokens.avatarSizeLarge,
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
                  color: DesignTokens.withOpacity(DesignTokens.accentPrimary, 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              FluentIcons.contact_card,
              color: DesignTokens.textInverse,
              size: DesignTokens.iconSizeMedium,
            ),
          ),
          SizedBox(width: DesignTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ClientConnect',
                  style: DesignTextStyles.title.copyWith(
                    color: DesignTokens.textPrimary,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
                Text(
                  'Command Center',
                  style: DesignTextStyles.caption.copyWith(
                    color: DesignTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItems(
    BuildContext context,
    WidgetRef ref,
    FluentThemeData theme,
    String currentRoute,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space4),
      child: Column(
        children: [
          _NavigationItem(
            icon: FluentIcons.view_dashboard,
            label: 'Dashboard',
            route: '/dashboard',
            isActive: currentRoute == '/dashboard',
          ),
          SizedBox(height: DesignTokens.space1),
          _NavigationItem(
            icon: FluentIcons.people,
            label: 'Clients',
            route: '/clients',
            isActive: currentRoute.startsWith('/clients'),
          ),
          SizedBox(height: DesignTokens.space1),
          _NavigationItem(
            icon: FluentIcons.page,
            label: 'Templates',
            route: '/templates',
            isActive: currentRoute.startsWith('/templates'),
          ),
          SizedBox(height: DesignTokens.space1),
          _NavigationItem(
            icon: FluentIcons.send,
            label: 'Campaigns',
            route: '/campaigns',
            isActive: currentRoute.startsWith('/campaigns'),
          ),
          SizedBox(height: DesignTokens.space1),
          _NavigationItem(
            icon: FluentIcons.analytics_view,
            label: 'Analytics',
            route: '/analytics',
            isActive: currentRoute.startsWith('/analytics'),
          ),
          SizedBox(height: DesignTokens.space1),
          _NavigationItem(
            icon: FluentIcons.import,
            label: 'Import/Export',
            route: '/import-export',
            isActive: currentRoute.startsWith('/import-export'),
          ),
          SizedBox(height: DesignTokens.space1),
          _NavigationItem(
            icon: FluentIcons.tag,
            label: 'Tags',
            route: '/tags',
            isActive: currentRoute.startsWith('/tags'),
          ),
          SizedBox(height: DesignTokens.space1),
          _NavigationItem(
            icon: FluentIcons.settings,
            label: 'Settings',
            route: '/settings',
            isActive: currentRoute.startsWith('/settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(FluentThemeData theme, ResponsiveInfo responsive) {
    return Container(
      padding: EdgeInsets.all(
        responsive.isMobile ? DesignTokens.space4 : DesignTokens.space4,
      ),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.space3),
        decoration: ComponentStyles.standardCard.copyWith(
          color: DesignTokens.withOpacity(DesignTokens.surfaceSecondary, 0.8),
        ),
        child: Row(
          children: [
            Container(
              width: DesignTokens.avatarSizeSmall,
              height: DesignTokens.avatarSizeSmall,
              decoration: BoxDecoration(
                color: DesignTokens.accentPrimary,
                borderRadius: BorderRadius.circular(DesignTokens.radiusRound),
              ),
              child: const Center(
                child: Text(
                  'U',
                  style: TextStyle(
                    color: DesignTokens.textInverse,
                    fontSize: DesignTokens.fontSizeCaption,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
              ),
            ),
            SizedBox(width: DesignTokens.space2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User',
                    style: DesignTextStyles.captionStrong.copyWith(
                      color: DesignTokens.textPrimary,
                    ),
                  ),
                  Text(
                    'Administrator',
                    style: DesignTextStyles.caption.copyWith(
                      color: DesignTokens.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem extends ConsumerWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool isActive;

  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: DesignTokens.space1),
      child: HoverButton(
        onPressed: () => GoRouter.of(context).go(route),
        builder: (context, states) {
          final isHovering = states.contains(WidgetState.hovered);
          
          return AnimatedContainer(
            duration: DesignTokens.animationFast,
            padding: const EdgeInsets.all(DesignTokens.space3),
            decoration: ComponentStyles.getNavigationItem(
              isActive: isActive,
              isHovered: isHovering,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: DesignTokens.iconSizeMedium,
                  color: isActive 
                      ? DesignTokens.accentPrimary
                      : isHovering
                          ? DesignTokens.textPrimary
                          : DesignTokens.textSecondary,
                ),
                SizedBox(width: DesignTokens.space3),
                Expanded(
                  child: Text(
                    label,
                    style: DesignTextStyles.body.copyWith(
                      color: isActive 
                          ? DesignTokens.accentPrimary
                          : isHovering
                              ? DesignTokens.textPrimary
                              : DesignTokens.textSecondary,
                      fontWeight: isActive 
                          ? DesignTokens.fontWeightSemiBold 
                          : DesignTokens.fontWeightRegular,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: DesignTokens.accentPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
