import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../design_system/design_tokens.dart';
import '../design_system/theme_provider.dart';
import 'navigation/adaptive_toolbar.dart';
import 'navigation/command_palette.dart';
import 'navigation/keyboard_shortcuts.dart';
import 'navigation/navigation_providers.dart';
import 'navigation/context_switcher.dart';
import 'providers/layout_providers.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Update navigation state based on current route
    final currentRoute = GoRouterState.of(context).uri.path;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationStateProvider.notifier).updateFromRoute(currentRoute);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(currentThemeProvider);
    final detailPanelState = ref.watch(detailPanelStateProvider);
    
    return ProviderScope(
      overrides: [
        goRouterProvider.overrideWithValue(GoRouter.of(context)),
      ],
      child: FluentApp(
        theme: currentTheme,
        home: KeyboardShortcutsHandler(
          child: ScaffoldPage(
            content: Stack(
              children: [
                Column(
                  children: [
                    const AdaptiveToolbar(),
                    Expanded(
                      child: Row(
                        children: [
                          // Main content area
                          Expanded(
                            flex: detailPanelState.isVisible ? 2 : 1,
                            child: Container(
                              color: DesignTokens.surfacePrimary,
                              child: widget.child,
                            ),
                          ),
                          
                          // Detail panel (if visible)
                          if (detailPanelState.isVisible) ...[
                            Container(
                              width: 1,
                              color: DesignTokens.borderPrimary,
                            ),
                            Expanded(
                              flex: 1,
                              child: _buildDetailPanel(context, ref, detailPanelState),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Command palette overlay
                const CommandPalette(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailPanel(BuildContext context, WidgetRef ref, DetailPanelState state) {
    if (!state.isVisible || state.selectedItemId == null) {
      return const SizedBox.shrink();
    }

    switch (state.type) {
      case DetailPanelType.client:
        return _buildClientDetailPanel(context, ref, state.selectedItemId!);
      case DetailPanelType.campaign:
        return _buildCampaignDetailPanel(context, ref, state.selectedItemId!);
      case DetailPanelType.template:
        return _buildTemplateDetailPanel(context, ref, state.selectedItemId!);
      case DetailPanelType.none:
        return const SizedBox.shrink();
    }
  }

  Widget _buildClientDetailPanel(BuildContext context, WidgetRef ref, String clientId) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.surfacePrimary,
        boxShadow: DesignTokens.shadowLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(DesignTokens.space6),
            decoration: BoxDecoration(
              color: DesignTokens.surfaceSecondary,
              border: Border(
                bottom: BorderSide(
                  color: DesignTokens.borderPrimary,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(DesignTokens.space2),
                      decoration: BoxDecoration(
                        color: DesignTokens.withOpacity(DesignTokens.accentPrimary, 0.1),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                        border: Border.all(
                          color: DesignTokens.withOpacity(DesignTokens.accentPrimary, 0.2),
                        ),
                      ),
                      child: Icon(
                        FluentIcons.contact_card,
                        size: DesignTokens.iconSizeMedium,
                        color: DesignTokens.accentPrimary,
                      ),
                    ),
                    SizedBox(width: DesignTokens.space3),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Client Details',
                          style: DesignTextStyles.title.copyWith(
                            fontWeight: DesignTokens.fontWeightSemiBold,
                          ),
                        ),
                        Text(
                          'Comprehensive client information',
                          style: DesignTextStyles.caption.copyWith(
                            color: DesignTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Button(
                  onPressed: () {
                    ref.read(detailPanelStateProvider.notifier).hidePanel();
                  },
                  child: Icon(
                    FluentIcons.chrome_close,
                    size: DesignTokens.iconSizeSmall,
                    color: DesignTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.space6),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(DesignTokens.space6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            DesignTokens.withOpacity(DesignTokens.accentPrimary, 0.08),
                            DesignTokens.withOpacity(DesignTokens.accentPrimary, 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusXLarge),
                        border: Border.all(
                          color: DesignTokens.withOpacity(DesignTokens.accentPrimary, 0.15),
                        ),
                      ),
                      child: Icon(
                        FluentIcons.contact_card,
                        size: 48,
                        color: DesignTokens.withOpacity(DesignTokens.accentPrimary, 0.6),
                      ),
                    ),
                    SizedBox(height: DesignTokens.space6),
                    Text(
                      'Client Detail Panel',
                      style: DesignTextStyles.subtitle.copyWith(
                        color: DesignTokens.accentPrimary,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                    ),
                    SizedBox(height: DesignTokens.space2),
                    Text(
                      'Detailed client information and management tools will be displayed here.',
                      style: DesignTextStyles.body.copyWith(
                        color: DesignTokens.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: DesignTokens.space2),
                    Text(
                      'ID: $clientId',
                      style: DesignTextStyles.caption.copyWith(
                        color: DesignTokens.textTertiary,
                        fontFamily: DesignTokens.fontFamilyMonospace,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignDetailPanel(BuildContext context, WidgetRef ref, String campaignId) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.surfacePrimary,
        boxShadow: DesignTokens.shadowLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(DesignTokens.space6),
            decoration: BoxDecoration(
              color: DesignTokens.surfaceSecondary,
              border: Border(
                bottom: BorderSide(
                  color: DesignTokens.borderPrimary,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(DesignTokens.space2),
                      decoration: BoxDecoration(
                        color: DesignTokens.withOpacity(DesignTokens.semanticInfo, 0.1),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                        border: Border.all(
                          color: DesignTokens.withOpacity(DesignTokens.semanticInfo, 0.2),
                        ),
                      ),
                      child: Icon(
                        FluentIcons.send,
                        size: DesignTokens.iconSizeMedium,
                        color: DesignTokens.semanticInfo,
                      ),
                    ),
                    SizedBox(width: DesignTokens.space3),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Campaign Details',
                          style: DesignTextStyles.title.copyWith(
                            fontWeight: DesignTokens.fontWeightSemiBold,
                          ),
                        ),
                        Text(
                          'Campaign performance and settings',
                          style: DesignTextStyles.caption.copyWith(
                            color: DesignTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Button(
                  onPressed: () {
                    ref.read(detailPanelStateProvider.notifier).hidePanel();
                  },
                  child: Icon(
                    FluentIcons.chrome_close,
                    size: DesignTokens.iconSizeSmall,
                    color: DesignTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.space6),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(DesignTokens.space6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            DesignTokens.withOpacity(DesignTokens.semanticInfo, 0.08),
                            DesignTokens.withOpacity(DesignTokens.semanticInfo, 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusXLarge),
                        border: Border.all(
                          color: DesignTokens.withOpacity(DesignTokens.semanticInfo, 0.15),
                        ),
                      ),
                      child: Icon(
                        FluentIcons.send,
                        size: 48,
                        color: DesignTokens.withOpacity(DesignTokens.semanticInfo, 0.6),
                      ),
                    ),
                    SizedBox(height: DesignTokens.space6),
                    Text(
                      'Campaign Detail Panel',
                      style: DesignTextStyles.subtitle.copyWith(
                        color: DesignTokens.semanticInfo,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                    ),
                    SizedBox(height: DesignTokens.space2),
                    Text(
                      'Campaign analytics, performance metrics, and management tools will be displayed here.',
                      style: DesignTextStyles.body.copyWith(
                        color: DesignTokens.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: DesignTokens.space2),
                    Text(
                      'ID: $campaignId',
                      style: DesignTextStyles.caption.copyWith(
                        color: DesignTokens.textTertiary,
                        fontFamily: DesignTokens.fontFamilyMonospace,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateDetailPanel(BuildContext context, WidgetRef ref, String templateId) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.surfacePrimary,
        boxShadow: DesignTokens.shadowLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(DesignTokens.space6),
            decoration: BoxDecoration(
              color: DesignTokens.surfaceSecondary,
              border: Border(
                bottom: BorderSide(
                  color: DesignTokens.borderPrimary,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(DesignTokens.space2),
                      decoration: BoxDecoration(
                        color: DesignTokens.withOpacity(DesignTokens.semanticWarning, 0.1),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                        border: Border.all(
                          color: DesignTokens.withOpacity(DesignTokens.semanticWarning, 0.2),
                        ),
                      ),
                      child: Icon(
                        FluentIcons.page,
                        size: DesignTokens.iconSizeMedium,
                        color: DesignTokens.semanticWarning,
                      ),
                    ),
                    SizedBox(width: DesignTokens.space3),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Template Details',
                          style: DesignTextStyles.title.copyWith(
                            fontWeight: DesignTokens.fontWeightSemiBold,
                          ),
                        ),
                        Text(
                          'Template configuration and preview',
                          style: DesignTextStyles.caption.copyWith(
                            color: DesignTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Button(
                  onPressed: () {
                    ref.read(detailPanelStateProvider.notifier).hidePanel();
                  },
                  child: Icon(
                    FluentIcons.chrome_close,
                    size: DesignTokens.iconSizeSmall,
                    color: DesignTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.space6),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(DesignTokens.space6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            DesignTokens.withOpacity(DesignTokens.semanticWarning, 0.08),
                            DesignTokens.withOpacity(DesignTokens.semanticWarning, 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusXLarge),
                        border: Border.all(
                          color: DesignTokens.withOpacity(DesignTokens.semanticWarning, 0.15),
                        ),
                      ),
                      child: Icon(
                        FluentIcons.page,
                        size: 48,
                        color: DesignTokens.withOpacity(DesignTokens.semanticWarning, 0.6),
                      ),
                    ),
                    SizedBox(height: DesignTokens.space6),
                    Text(
                      'Template Detail Panel',
                      style: DesignTextStyles.subtitle.copyWith(
                        color: DesignTokens.semanticWarning,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                    ),
                    SizedBox(height: DesignTokens.space2),
                    Text(
                      'Template preview, usage statistics, and editing tools will be displayed here.',
                      style: DesignTextStyles.body.copyWith(
                        color: DesignTokens.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: DesignTokens.space2),
                    Text(
                      'ID: $templateId',
                      style: DesignTextStyles.caption.copyWith(
                        color: DesignTokens.textTertiary,
                        fontFamily: DesignTokens.fontFamilyMonospace,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}