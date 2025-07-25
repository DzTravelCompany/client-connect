import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show PopupMenuButton, PopupMenuItem;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../design_system/design_tokens.dart';
import 'navigation_context.dart';
import 'navigation_providers.dart';

class ContextSwitcher extends ConsumerWidget {
  const ContextSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationState = ref.watch(navigationStateProvider);
    final currentContext = navigationState.currentContext;
    
    return DropDownButton(
      title: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space3,
          vertical: DesignTokens.space2,
        ),
        decoration: BoxDecoration(
          color: DesignTokens.withOpacity(currentContext.getContextColor(), 0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          border: Border.all(
            color: DesignTokens.withOpacity(currentContext.getContextColor(), 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.space1),
              decoration: BoxDecoration(
                color: currentContext.getContextColor(),
                borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
              ),
              child: Icon(
                currentContext.icon,
                size: DesignTokens.iconSizeSmall,
                color: DesignTokens.textInverse,
              ),
            ),
            SizedBox(width: DesignTokens.space2),
            Text(
              currentContext.label,
              style: DesignTextStyles.body.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: currentContext.getContextColor(),
              ),
            ),
            SizedBox(width: DesignTokens.space2),
            Icon(
              FluentIcons.chevron_down,
              size: DesignTokens.iconSizeSmall,
              color: currentContext.getContextColor(),
            ),
          ],
        ),
      ),
      items: [
        // Recent contexts section
        if (navigationState.recentContexts.isNotEmpty) ...[
          _buildSectionHeader('Recent'),
          ...navigationState.recentContexts.take(3).map(
            (context) => _buildContextItem(context, ref, isRecent: true),
          ),
          const MenuFlyoutSeparator(),
        ],
        
        // Pinned contexts section
        if (navigationState.pinnedContexts.isNotEmpty) ...[
          _buildSectionHeader('Pinned'),
          ...navigationState.pinnedContexts.map(
            (context) => _buildContextItem(context, ref, isPinned: true),
          ),
          const MenuFlyoutSeparator(),
        ],
        
        // All contexts section
        _buildSectionHeader('All Contexts'),
        ...NavigationContext.values.map(
          (context) => _buildContextItem(context, ref),
        ),
      ],
    );
  }

  MenuFlyoutItem _buildSectionHeader(String title) {
    return MenuFlyoutItem(
      text: Container(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.space1),
        child: Text(
          title,
          style: DesignTextStyles.caption.copyWith(
            color: DesignTokens.textTertiary,
            fontWeight: DesignTokens.fontWeightSemiBold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      onPressed: null, // Non-clickable header
    );
  }

  MenuFlyoutItem _buildContextItem(
    NavigationContext navContext,
    WidgetRef ref, {
    bool isRecent = false,
    bool isPinned = false,
  }) {
    return MenuFlyoutItem(
      leading: Container(
        padding: const EdgeInsets.all(DesignTokens.space1),
        decoration: BoxDecoration(
          color: DesignTokens.withOpacity(navContext.getContextColor(), 0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        ),
        child: Icon(
          navContext.icon,
          size: DesignTokens.iconSizeSmall,
          color: navContext.getContextColor(),
        ),
      ),
      text: Row(
        children: [
          Expanded(
            child: Text(
              navContext.label,
              style: DesignTextStyles.body.copyWith(
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
          ),
          if (isRecent) ...[
            Icon(
              FluentIcons.recent,
              size: DesignTokens.iconSizeSmall,
              color: DesignTokens.textTertiary,
            ),
          ],
          if (isPinned) ...[
            Icon(
              FluentIcons.pinned,
              size: DesignTokens.iconSizeSmall,
              color: DesignTokens.accentPrimary,
            ),
          ],
        ],
      ),
      onPressed: () {
        ref.read(navigationStateProvider.notifier).navigateToContext(navContext);
        ref.read(goRouterProvider).go(navContext.route);
      },
      trailing: PopupMenuButton<String>(
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'pin',
            child: Row(
              children: [
                Icon(
                  isPinned ? FluentIcons.unpin : FluentIcons.pinned,
                  size: DesignTokens.iconSizeSmall,
                ),
                SizedBox(width: DesignTokens.space2),
                Text(isPinned ? 'Unpin' : 'Pin'),
              ],
            ),
          ),
        ],
        onSelected: (value) {
          if (value == 'pin') {
            ref.read(navigationStateProvider.notifier).togglePinnedContext(navContext);
          }
        },
        child: Icon(
          FluentIcons.more,
          size: DesignTokens.iconSizeSmall,
          color: DesignTokens.textTertiary,
        ),
      ),
    );
  }
}

// Provider for GoRouter access
final goRouterProvider = Provider<GoRouter>((ref) {
  throw UnimplementedError('GoRouter provider must be overridden');
});
