import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThreeColumnLayout extends ConsumerWidget {
  final Widget sidebar;
  final Widget mainContent;
  final Widget? detailPanel;
  final bool showDetailPanel;
  final double sidebarWidth;
  final double detailPanelWidth;

  const ThreeColumnLayout({
    super.key,
    required this.sidebar,
    required this.mainContent,
    this.detailPanel,
    this.showDetailPanel = false,
    this.sidebarWidth = 280,
    this.detailPanelWidth = 320,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FluentTheme.of(context);
    
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Row(
        children: [
          // Sidebar
          SizedBox(
            width: sidebarWidth,
            child: sidebar,
          ),
          
          // Main Content Area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(
                  left: BorderSide(
                    color: theme.resources.dividerStrokeColorDefault,
                    width: 1,
                  ),
                  right: showDetailPanel ? BorderSide(
                    color: theme.resources.dividerStrokeColorDefault,
                    width: 1,
                  ) : BorderSide.none,
                ),
              ),
              child: mainContent,
            ),
          ),
          
          // Detail Panel
          if (showDetailPanel && detailPanel != null)
            SizedBox(
              width: detailPanelWidth,
              child: Container(
                color: theme.cardColor,
                child: detailPanel!,
              ),
            ),
        ],
      ),
    );
  }
}