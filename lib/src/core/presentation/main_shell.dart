import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'layouts/three_column_layout.dart';
import 'layouts/glassmorphism_sidebar.dart';
import 'providers/layout_providers.dart';

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailPanelState = ref.watch(detailPanelStateProvider);
    
    return FluentApp(
      home: ThreeColumnLayout(
        sidebar: const GlassmorphismSidebar(),
        mainContent: child,
        detailPanel: _buildDetailPanel(context, ref, detailPanelState),
        showDetailPanel: detailPanelState.isVisible,
      ),
    );
  }

  Widget? _buildDetailPanel(BuildContext context, WidgetRef ref, DetailPanelState state) {
    if (!state.isVisible || state.selectedItemId == null) {
      return null;
    }

    final theme = FluentTheme.of(context);
    
    switch (state.type) {
      case DetailPanelType.client:
        return _buildClientDetailPanel(context, theme, state.selectedItemId!);
      case DetailPanelType.campaign:
        return _buildCampaignDetailPanel(context, theme, state.selectedItemId!);
      case DetailPanelType.template:
        return _buildTemplateDetailPanel(context, theme, state.selectedItemId!);
      case DetailPanelType.none:
        return null;
    }
  }

  Widget _buildClientDetailPanel(BuildContext context, FluentThemeData theme, String clientId) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Client Details',
                style: theme.typography.subtitle?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Button(
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(const EdgeInsets.all(8)),
                ),
                onPressed: () {
                  // Close detail panel
                  final container = ProviderScope.containerOf(context);
                  container.read(detailPanelStateProvider.notifier).hidePanel();
                },
                child: const Icon(FluentIcons.chrome_close, size: 12),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    FluentIcons.contact_card,
                    size: 48,
                    color: theme.resources.textFillColorSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Client Detail Panel',
                    style: theme.typography.body?.copyWith(
                      color: theme.resources.textFillColorSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ID: $clientId',
                    style: theme.typography.caption?.copyWith(
                      color: theme.resources.textFillColorTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignDetailPanel(BuildContext context, FluentThemeData theme, String campaignId) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Campaign Details',
                style: theme.typography.subtitle?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Button(
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(const EdgeInsets.all(8)),
                ),
                onPressed: () {
                  // Close detail panel
                },
                child: const Icon(FluentIcons.chrome_close, size: 12),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    FluentIcons.send,
                    size: 48,
                    color: theme.resources.textFillColorSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Campaign Detail Panel',
                    style: theme.typography.body?.copyWith(
                      color: theme.resources.textFillColorSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ID: $campaignId',
                    style: theme.typography.caption?.copyWith(
                      color: theme.resources.textFillColorTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateDetailPanel(BuildContext context, FluentThemeData theme, String templateId) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Template Details',
                style: theme.typography.subtitle?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Button(
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(const EdgeInsets.all(8)),
                ),
                onPressed: () {
                  // Close detail panel
                },
                child: const Icon(FluentIcons.chrome_close, size: 12),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    FluentIcons.page,
                    size: 48,
                    color: theme.resources.textFillColorSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Template Detail Panel',
                    style: theme.typography.body?.copyWith(
                      color: theme.resources.textFillColorSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ID: $templateId',
                    style: theme.typography.caption?.copyWith(
                      color: theme.resources.textFillColorTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}