import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/layout_providers.dart';

class GlassmorphismSidebar extends ConsumerWidget {
  const GlassmorphismSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    // final sidebarState = ref.watch(sidebarStateProvider);
    
    return MouseRegion(
      onEnter: (_) => ref.read(sidebarStateProvider.notifier).setHovered(true),
      onExit: (_) => ref.read(sidebarStateProvider.notifier).setHovered(false),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.cardColor.withValues(alpha: 0.9),
              theme.cardColor.withValues(alpha: 0.7),
            ],
          ),
          border: Border(
            right: BorderSide(
              color: theme.resources.dividerStrokeColorDefault.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.accentColor,
                          theme.accentColor.darker,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      FluentIcons.contact_card,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'ClientConnect',
                    style: theme.typography.bodyStrong?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            // Navigation Items
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _NavigationItem(
                      icon: FluentIcons.view_dashboard,
                      label: 'Dashboard',
                      route: '/dashboard',
                      isActive: true,
                    ),
                    const SizedBox(height: 4),
                    _NavigationItem(
                      icon: FluentIcons.people,
                      label: 'Clients',
                      route: '/clients',
                    ),
                    const SizedBox(height: 4),
                    _NavigationItem(
                      icon: FluentIcons.page,
                      label: 'Templates',
                      route: '/templates',
                    ),
                    const SizedBox(height: 4),
                    _NavigationItem(
                      icon: FluentIcons.send,
                      label: 'Campaigns',
                      route: '/campaigns',
                    ),
                    const SizedBox(height: 4),
                    _NavigationItem(
                      icon: FluentIcons.analytics_view,
                      label: 'Analytics',
                      route: '/analytics',
                    ),
                    const SizedBox(height: 4),
                    _NavigationItem(
                      icon: FluentIcons.import,
                      label: 'Import/Export',
                      route: '/import-export',
                    ),
                    const SizedBox(height: 4),
                    _NavigationItem(
                      icon: FluentIcons.tag,
                      label: 'Tags',
                      route: '/tags',
                    ),
                    const SizedBox(height: 4),
                    _NavigationItem(
                      icon: FluentIcons.settings,
                      label: 'Settings',
                      route: '/settings',
                    ),
                  ],
                ),
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              child: Container(
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
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: theme.accentColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'U',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User',
                            style: theme.typography.caption?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Administrator',
                            style: theme.typography.caption?.copyWith(
                              color: theme.resources.textFillColorSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
    final theme = FluentTheme.of(context);
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Button(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (isActive) {
              return theme.accentColor.withValues(alpha: 0.1);
            }
            if (states.isHovered) {
              return theme.resources.cardBackgroundFillColorSecondary;
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (isActive) {
              return theme.accentColor;
            }
            return theme.resources.textFillColorPrimary;
          }),
          padding: WidgetStateProperty.all(const EdgeInsets.all(12)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: isActive
                  ? BorderSide(color: theme.accentColor.withValues(alpha: 0.3))
                  : BorderSide.none,
            ),
          ),
        ),
        onPressed: () {
          // Navigation will be handled by router
          GoRouter.of(context).go(route);          
        },
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: theme.typography.body?.copyWith(
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}