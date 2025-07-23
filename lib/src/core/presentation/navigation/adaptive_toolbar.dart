import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../design_system/design_tokens.dart';
import '../../design_system/component_library.dart';
import '../../design_system/component_styles.dart';
import 'navigation_context.dart';
import 'navigation_providers.dart';
import 'context_switcher.dart';


class AdaptiveToolbar extends ConsumerWidget {
  const AdaptiveToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationState = ref.watch(navigationStateProvider);
    
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: DesignTokens.surfacePrimary,
        border: Border(
          bottom: BorderSide(
            color: DesignTokens.borderPrimary,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space4),
        child: Row(
          children: [
            // Left Section: Context Switcher + Breadcrumbs
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  const ContextSwitcher(),
                  SizedBox(width: DesignTokens.space4),
                  Expanded(child: _buildBreadcrumbs(context, ref, navigationState)),
                ],
              ),
            ),
            
            // Center Section: Context-specific actions and search
            Expanded(
              flex: 3,
              child: _buildCenterSection(context, ref, navigationState),
            ),
            
            // Right Section: Global actions
            Expanded(
              flex: 1,
              child: _buildRightSection(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumbs(BuildContext context, WidgetRef ref, NavigationState navigationState) {
    if (navigationState.breadcrumbs.isEmpty) return const SizedBox.shrink();
    
    return Row(
      children: [
        for (int i = 0; i < navigationState.breadcrumbs.length; i++) ...[
          if (i > 0) ...[
            SizedBox(width: DesignTokens.space2),
            Icon(
              FluentIcons.chevron_right,
              size: DesignTokens.iconSizeSmall,
              color: DesignTokens.textTertiary,
            ),
            SizedBox(width: DesignTokens.space2),
          ],
          _buildBreadcrumbItem(context, ref, navigationState.breadcrumbs[i]),
        ],
      ],
    );
  }

  Widget _buildBreadcrumbItem(BuildContext context, WidgetRef ref, NavigationBreadcrumb breadcrumb) {
    final isClickable = breadcrumb.route != null && !breadcrumb.isActive;
    
    return HoverButton(
      onPressed: isClickable ? () => context.go(breadcrumb.route!) : null,
      builder: (context, states) {
        final isHovered = states.contains(WidgetState.hovered);
        
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space2,
            vertical: DesignTokens.space1,
          ),
          decoration: BoxDecoration(
            color: isHovered && isClickable
                ? DesignTokens.withOpacity(DesignTokens.accentPrimary, 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (breadcrumb.icon != null) ...[
                Icon(
                  breadcrumb.icon,
                  size: DesignTokens.iconSizeSmall,
                  color: breadcrumb.isActive
                      ? DesignTokens.accentPrimary
                      : DesignTokens.textSecondary,
                ),
                SizedBox(width: DesignTokens.space1),
              ],
              Text(
                breadcrumb.label,
                style: DesignTextStyles.body.copyWith(
                  color: breadcrumb.isActive
                      ? DesignTokens.accentPrimary
                      : isClickable
                          ? DesignTokens.textPrimary
                          : DesignTokens.textSecondary,
                  fontWeight: breadcrumb.isActive
                      ? DesignTokens.fontWeightSemiBold
                      : DesignTokens.fontWeightRegular,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCenterSection(BuildContext context, WidgetRef ref, NavigationState navigationState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Context-specific search
        SizedBox(
          width: 300,
          child: DesignSystemComponents.textInput(
            controller: TextEditingController(),
            placeholder: 'Search ${navigationState.currentContext.label.toLowerCase()}...',
            prefixIcon: FluentIcons.search,
            onTap: () => ref.read(commandPaletteProvider.notifier).show(),
          ),
        ),
        SizedBox(width: DesignTokens.space4),
        
        // Context-specific actions
        ..._buildContextActions(context, ref, navigationState.currentContext),
      ],
    );
  }

  List<Widget> _buildContextActions(BuildContext context, WidgetRef ref, NavigationContext currentContext) {
    switch (currentContext) {
      case NavigationContext.clients:
        return [
          DesignSystemComponents.primaryButton(
            text: 'Add Client',
            icon: FluentIcons.add_friend,
            onPressed: () => context.go('/clients/add'),
          ),
        ];
      
      case NavigationContext.templates:
        return [
          DesignSystemComponents.secondaryButton(
            text: 'Import',
            icon: FluentIcons.cloud_download,
            onPressed: () {},
          ),
          SizedBox(width: DesignTokens.space2),
          DesignSystemComponents.primaryButton(
            text: 'New Template',
            icon: FluentIcons.page_add,
            onPressed: () => context.go('/templates/editor'),
          ),
        ];
      
      case NavigationContext.campaigns:
        return [
          DesignSystemComponents.secondaryButton(
            text: 'Analytics',
            icon: FluentIcons.chart_template,
            onPressed: () => context.go('/campaigns/analytics'),
          ),
          SizedBox(width: DesignTokens.space2),
          DesignSystemComponents.primaryButton(
            text: 'Create Campaign',
            icon: FluentIcons.send,
            onPressed: () => context.go('/campaigns/create'),
          ),
        ];
      
      default:
        return [];
    }
  }

  Widget _buildRightSection(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Command palette trigger
        Tooltip(
          message: 'Command Palette (Ctrl+K)',
          child: Button(
            style: ComponentStyles.iconButton,
            onPressed: () => ref.read(commandPaletteProvider.notifier).show(),
            child: Icon(
              FluentIcons.lightning_bolt,
              size: DesignTokens.iconSizeSmall,
              color: DesignTokens.textSecondary,
            ),
          ),
        ),
        
        SizedBox(width: DesignTokens.space2),
        
        // Notifications
        Button(
          style: ComponentStyles.iconButton,
          onPressed: () {},
          child: Badge(
            child: Icon(
              FluentIcons.ringer,
              size: DesignTokens.iconSizeSmall,
              color: DesignTokens.textSecondary,
            ),
          ),
        ),
        
        SizedBox(width: DesignTokens.space2),
        
        // User profile
        Button(
          style: ComponentStyles.iconButton,
          onPressed: () {},
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: DesignTokens.accentPrimary,
              borderRadius: BorderRadius.circular(DesignTokens.radiusRound),
            ),
            child: Icon(
              FluentIcons.contact,
              size: DesignTokens.iconSizeSmall,
              color: DesignTokens.textInverse,
            ),
          ),
        ),
      ],
    );
  }
}