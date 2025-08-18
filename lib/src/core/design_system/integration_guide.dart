/// Integration Guide for Client Connect Design System
/// 
/// This file provides comprehensive guidance for integrating the design system
/// throughout the application, ensuring consistency and maintainability.
library;

import 'package:fluent_ui/fluent_ui.dart';
import 'design_tokens.dart';
import 'component_library.dart';
import 'layout_system.dart';
import 'animation_system.dart';
import 'design_system_integration.dart';

/// Design System Integration Guide
/// 
/// Follow these patterns to ensure consistent implementation across the app
class DesignSystemIntegrationGuide {
  DesignSystemIntegrationGuide._();
  
  // =============================================================================
  // SCREEN STRUCTURE PATTERNS
  // =============================================================================
  
  /// Standard screen structure using design system
  /// 
  /// Use this pattern for all main screens in the application
  static Widget standardScreen({
    required String title,
    String? subtitle,
    required Widget content,
    List<Widget>? headerActions,
    Widget? floatingActionButton,
    bool includeAnimation = true,
  }) {
    return DesignSystemIntegration.enhancedScaffoldPage(
      header: LayoutSystem.pageHeader(
        title: title,
        subtitle: subtitle,
        actions: headerActions,
      ) as PageHeader?,
      content: includeAnimation
          ? AnimationSystem.fadeIn(child: content)
          : content,
    );
  }
  
  /// List screen pattern with search and filters
  static Widget listScreen({
    required String title,
    required Widget searchBar,
    required Widget filterPanel,
    required Widget listContent,
    Widget? emptyState,
    List<Widget>? headerActions,
  }) {
    return standardScreen(
      title: title,
      headerActions: headerActions,
      content: Column(
        children: [
          // Search and filter section
          LayoutSystem.sectionContainer(
            child: Column(
              children: [
                searchBar,
                const SizedBox(height: DesignTokens.space4),
                filterPanel,
              ],
            ),
          ),
          
          // List content
          Expanded(
            child: listContent,
          ),
        ],
      ),
    );
  }
  
  /// Form screen pattern with validation and auto-save
  static Widget formScreen({
    required String title,
    required Widget form,
    required VoidCallback onSave,
    VoidCallback? onCancel,
    bool isLoading = false,
    String? errorMessage,
    bool hasUnsavedChanges = false,
  }) {
    return standardScreen(
      title: title,
      headerActions: [
        if (onCancel != null)
          DesignSystemComponents.secondaryButton(
            text: 'Cancel',
            onPressed: isLoading ? null : onCancel,
          ),
        DesignSystemComponents.primaryButton(
          text: 'Save',
          onPressed: isLoading ? null : onSave,
          isLoading: isLoading,
          icon: FluentIcons.save,
        ),
      ],
      content: Column(
        children: [
          // Status indicators
          if (isLoading || hasUnsavedChanges || errorMessage != null)
            AnimationSystem.slideIn(
              direction: SlideDirection.top,
              child: _buildFormStatusIndicator(
                isLoading: isLoading,
                hasUnsavedChanges: hasUnsavedChanges,
                errorMessage: errorMessage,
              ),
            ),
          
          // Form content
          Expanded(child: form),
        ],
      ),
    );
  }
  
  /// Detail screen pattern with tabs and actions
  static Widget detailScreen({
    required String title,
    String? subtitle,
    required List<Tab> tabs,
    required List<Widget> tabViews,
    required int currentIndex,
    required ValueChanged<int> onTabChanged,
    List<Widget>? headerActions,
    Widget? sidebar,
  }) {
    assert(tabs.length == tabViews.length, 'The number of tabs and tabViews must be equal.');
    final List<Tab> completeTabs = List.generate(
      tabs.length,
      (index) {
        final header = tabs[index];
        final body = tabViews[index];
        // Create a new Tab object with both the header info and the body content
        return Tab(
          text: header.text,
          icon: header.icon,
          semanticLabel: header.semanticLabel,
          body: body, // The content for the tab goes here
        );
      },
    );
    final tabViewWidget = TabView(
      tabs: completeTabs,
      currentIndex: currentIndex,
      onChanged: onTabChanged,
    );
    return standardScreen(
      title: title,
      subtitle: subtitle,
      headerActions: headerActions,
      content: sidebar != null
          ? LayoutSystem.twoColumnLayout(
              left: tabViewWidget, // Use the correctly configured TabView
              right: sidebar,
              leftFlex: 2,
              rightFlex: 1,
            )
          : tabViewWidget, // Use the correctly configured TabView
    );
  }
  
  // =============================================================================
  // COMPONENT USAGE PATTERNS
  // =============================================================================
  
  /// Standard card list pattern
  static Widget cardList({
    required List<Widget> cards,
    bool useStaggeredAnimation = true,
    int? forceColumns,
  }) {
    final cardGrid = LayoutSystem.cardGrid(
      cards: cards,
      forceColumns: forceColumns,
    );
    
    return useStaggeredAnimation
        ? AnimationSystem.staggeredGrid(
            children: cards,
            columns: forceColumns ?? 3,
          )
        : cardGrid;
  }
  
  /// Standard data table pattern
  static Widget dataTable({
    required List<String> headers,
    required List<List<Widget>> rows,
    List<Widget>? actions,
    String? emptyMessage,
  }) {
    if (rows.isEmpty && emptyMessage != null) {
      return DesignSystemComponents.emptyState(
        title: 'No Data Available',
        message: emptyMessage,
        icon: FluentIcons.table,
      );
    }
    
    return LayoutSystem.sectionContainer(
      action: actions != null
          ? Row(children: actions)
          : null,
      child: Table(
        children: [
          // Header row
          TableRow(
            decoration: BoxDecoration(
              color: DesignTokens.surfaceSecondary,
              borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            ),
            children: headers.map((header) => Padding(
              padding: const EdgeInsets.all(DesignTokens.space3),
              child: Text(
                header,
                style: DesignTextStyles.body.copyWith(
                  fontWeight: DesignTokens.fontWeightSemiBold,
                ),
              ),
            )).toList(),
          ),
          
          // Data rows
          ...rows.map((row) => TableRow(
            children: row.map((cell) => Padding(
              padding: const EdgeInsets.all(DesignTokens.space3),
              child: cell,
            )).toList(),
          )),
        ],
      ),
    );
  }
  
  /// Standard filter panel pattern
  static Widget filterPanel({
    required List<Widget> filters,
    VoidCallback? onClear,
    VoidCallback? onApply,
    bool isExpanded = false,
  }) {
    return LayoutSystem.sectionContainer(
      title: 'Filters',
      action: Row(
        children: [
          if (onClear != null)
            DesignSystemComponents.secondaryButton(
              text: 'Clear',
              onPressed: onClear,
              icon: FluentIcons.clear_filter,
            ),
          if (onApply != null) ...[
            const SizedBox(width: DesignTokens.space2),
            DesignSystemComponents.primaryButton(
              text: 'Apply',
              onPressed: onApply,
              icon: FluentIcons.filter,
            ),
          ],
        ],
      ),
      child: AnimatedContainer(
        duration: DesignTokens.animationNormal,
        height: isExpanded ? null : 0,
        child: isExpanded
            ? LayoutSystem.formFieldGroup(children: filters)
            : null,
      ),
    );
  }
  
  // =============================================================================
  // NAVIGATION PATTERNS
  // =============================================================================
  
  /// Standard sidebar navigation pattern
  static Widget sidebarNavigation({
    required List<NavigationItem> items,
    required int selectedIndex,
    required Function(int) onItemSelected,
    Widget? header,
    Widget? footer,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.surfaceSecondary,
        border: Border(
          right: BorderSide(color: DesignTokens.borderPrimary),
        ),
      ),
      child: Column(
        children: [
          if (header != null) header,
          
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return DesignSystemComponents.navigationItem(
                  label: item.label,
                  icon: item.icon,
                  isActive: selectedIndex == index,
                  badge: item.badge,
                  onPressed: () => onItemSelected(index),
                );
              },
            ),
          ),
          
          if (footer != null) footer,
        ],
      ),
    );
  }
  
  /// Standard breadcrumb navigation pattern
  static Widget breadcrumbNavigation({
    required List<BreadcrumbItem> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space4),
      child: Row(
        children: items.expand((item) => [
          if (item.onPressed != null)
            GestureDetector(
              onTap: item.onPressed,
              child: Text(
                item.label,
                style: DesignTextStyles.body.copyWith(
                  color: DesignTokens.accentPrimary,
                  decoration: TextDecoration.underline,
                ),
              ),
            )
          else
            Text(
              item.label,
              style: DesignTextStyles.body.copyWith(
                color: DesignTokens.textSecondary,
              ),
            ),
          
          if (item != items.last) ...[
            const SizedBox(width: DesignTokens.space2),
            Icon(
              FluentIcons.chevron_right,
              size: DesignTokens.iconSizeSmall,
              color: DesignTokens.textTertiary,
            ),
            const SizedBox(width: DesignTokens.space2),
          ],
        ]).toList(),
      ),
    );
  }
  
  // =============================================================================
  // HELPER METHODS
  // =============================================================================
  
  static Widget _buildFormStatusIndicator({
    required bool isLoading,
    required bool hasUnsavedChanges,
    String? errorMessage,
  }) {
    if (errorMessage != null) {
      return DesignSystemComponents.statusBadge(
        text: errorMessage,
        type: SemanticColorType.error,
        icon: FluentIcons.error,
      ).asDesignSystemSection();
    } else if (isLoading) {
      return DesignSystemComponents.loadingIndicator(
        message: 'Saving...',
      );
    } else if (hasUnsavedChanges) {
      return DesignSystemComponents.statusBadge(
        text: 'Unsaved changes',
        type: SemanticColorType.warning,
        icon: FluentIcons.edit,
      ).asDesignSystemSection();
    }
    
    return const SizedBox.shrink();
  }
}

// =============================================================================
// SUPPORTING CLASSES
// =============================================================================

class NavigationItem {
  final String label;
  final IconData icon;
  final String? badge;
  final VoidCallback? onPressed;
  
  NavigationItem({
    required this.label,
    required this.icon,
    this.badge,
    this.onPressed,
  });
}

class BreadcrumbItem {
  final String label;
  final VoidCallback? onPressed;
  
  BreadcrumbItem({
    required this.label,
    this.onPressed,
  });
}

// =============================================================================
// MIGRATION CHECKLIST
// =============================================================================

/// Migration Checklist for Design System Integration
/// 
/// Use this checklist to ensure complete integration:
/// 
/// ✅ Theme Integration
/// - [ ] Replace FluentApp with DesignSystemIntegration.wrapWithDesignSystem
/// - [ ] Update all color references to use DesignTokens
/// - [ ] Replace custom text styles with DesignTextStyles
/// 
/// ✅ Component Migration
/// - [ ] Replace Button widgets with DesignSystemComponents.primaryButton/secondaryButton
/// - [ ] Replace Container cards with DesignSystemComponents.standardCard
/// - [ ] Replace TextFormBox with DesignSystemComponents.textInput
/// - [ ] Replace custom loading states with DesignSystemComponents.loadingIndicator
/// - [ ] Replace custom empty states with DesignSystemComponents.emptyState
/// 
/// ✅ Layout Migration
/// - [ ] Replace ScaffoldPage with DesignSystemIntegration.enhancedScaffoldPage
/// - [ ] Use LayoutSystem.pageContainer for page content
/// - [ ] Use LayoutSystem.sectionContainer for grouped content
/// - [ ] Use LayoutSystem.formFieldGroup for form layouts
/// 
/// ✅ Animation Integration
/// - [ ] Add AnimationSystem.fadeIn to page transitions
/// - [ ] Use AnimationSystem.staggeredList for list animations
/// - [ ] Apply AnimationSystem.slideIn for status indicators
/// 
/// ✅ Accessibility Integration
/// - [ ] Add semantic labels to interactive components
/// - [ ] Ensure proper focus management
/// - [ ] Validate color contrast ratios
/// - [ ] Test keyboard navigation
/// 
/// ✅ Responsive Design
/// - [ ] Use ResponsiveUtils for breakpoint-based logic
/// - [ ] Apply responsive padding and margins
/// - [ ] Test on different screen sizes
/// 
/// ✅ Testing and Validation
/// - [ ] Run DesignSystemIntegration.validateImplementation
/// - [ ] Generate usage report with generateUsageReport
/// - [ ] Test accessibility with screen readers
/// - [ ] Validate design consistency across screens