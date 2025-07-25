import 'package:fluent_ui/fluent_ui.dart';
import 'design_tokens.dart';
import 'responsive_utils.dart';

/// Layout system providing consistent spacing and structure
class LayoutSystem {
  LayoutSystem._();
  
  // =============================================================================
  // LAYOUT CONTAINERS
  // =============================================================================
  
  /// Standard page container with responsive padding
  static Widget pageContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
    bool includeScrollView = true,
  }) {
    return Builder(
      builder: (context) {
        final responsivePadding = padding ?? ResponsiveUtils.getResponsivePadding(context);
        
        final content = Container(
          padding: responsivePadding,
          child: child,
        );
        
        return includeScrollView
            ? SingleChildScrollView(child: content)
            : content;
      },
    );
  }
  
  /// Section container with consistent spacing
  static Widget sectionContainer({
    required Widget child,
    String? title,
    String? subtitle,
    Widget? action,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: DesignTokens.sectionSpacing),
      padding: padding ?? const EdgeInsets.all(DesignTokens.space6),
      decoration: BoxDecoration(
        color: DesignTokens.surfacePrimary,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: DesignTokens.borderPrimary),
        boxShadow: DesignTokens.shadowLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null || action != null) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(
                          title,
                          style: DesignTextStyles.subtitle.copyWith(
                            fontWeight: DesignTokens.fontWeightSemiBold,
                          ),
                        ),
                      if (subtitle != null) ...[
                        const SizedBox(height: DesignTokens.space1),
                        Text(
                          subtitle,
                          style: DesignTextStyles.body.copyWith(
                            color: DesignTokens.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (action != null) action,
              ],
            ),
            const SizedBox(height: DesignTokens.space4),
          ],
          child,
        ],
      ),
    );
  }
  
  /// Grid layout with responsive columns
  static Widget responsiveGrid({
    required List<Widget> children,
    double spacing = DesignTokens.space4,
    double runSpacing = DesignTokens.space4,
    int? forceColumns,
  }) {
    return Builder(
      builder: (context) {
        final columns = forceColumns ?? ResponsiveUtils.getResponsiveGridColumns(context);
        
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            return SizedBox(
              width: (MediaQuery.of(context).size.width - (spacing * (columns - 1))) / columns,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
  
  /// Two-column layout with responsive behavior
  static Widget twoColumnLayout({
    required Widget left,
    required Widget right,
    double spacing = DesignTokens.space6,
    double leftFlex = 1.0,
    double rightFlex = 1.0,
  }) {
    return Builder(
      builder: (context) {
        if (ResponsiveUtils.isMobile(context)) {
          return Column(
            children: [
              left,
              SizedBox(height: spacing),
              right,
            ],
          );
        }
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: leftFlex.round(), child: left),
            SizedBox(width: spacing),
            Expanded(flex: rightFlex.round(), child: right),
          ],
        );
      },
    );
  }
  
  /// Three-column layout with responsive behavior
  static Widget threeColumnLayout({
    required Widget left,
    required Widget center,
    required Widget right,
    double spacing = DesignTokens.space6,
    double leftFlex = 1.0,
    double centerFlex = 2.0,
    double rightFlex = 1.0,
  }) {
    return Builder(
      builder: (context) {
        if (ResponsiveUtils.isMobile(context)) {
          return Column(
            children: [
              left,
              SizedBox(height: spacing),
              center,
              SizedBox(height: spacing),
              right,
            ],
          );
        }
        
        if (ResponsiveUtils.isTablet(context)) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: leftFlex.round(), child: left),
                  SizedBox(width: spacing),
                  Expanded(flex: centerFlex.round(), child: center),
                ],
              ),
              SizedBox(height: spacing),
              right,
            ],
          );
        }
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: leftFlex.round(), child: left),
            SizedBox(width: spacing),
            Expanded(flex: centerFlex.round(), child: center),
            SizedBox(width: spacing),
            Expanded(flex: rightFlex.round(), child: right),
          ],
        );
      },
    );
  }
  
  // =============================================================================
  // SPACING UTILITIES
  // =============================================================================
  
  /// Vertical spacing widget
  static Widget verticalSpace(double space) {
    return SizedBox(height: space);
  }
  
  /// Horizontal spacing widget
  static Widget horizontalSpace(double space) {
    return SizedBox(width: space);
  }
  
  /// Responsive vertical spacing
  static Widget responsiveVerticalSpace(BuildContext context) {
    return SizedBox(
      height: ResponsiveUtils.getResponsiveValue(
        context,
        mobile: DesignTokens.space4,
        tablet: DesignTokens.space5,
        desktop: DesignTokens.space6,
      ),
    );
  }
  
  /// Responsive horizontal spacing
  static Widget responsiveHorizontalSpace(BuildContext context) {
    return SizedBox(
      width: ResponsiveUtils.getResponsiveValue(
        context,
        mobile: DesignTokens.space4,
        tablet: DesignTokens.space5,
        desktop: DesignTokens.space6,
      ),
    );
  }
  
  // =============================================================================
  // FORM LAYOUTS
  // =============================================================================
  
  /// Form field group with consistent spacing
  static Widget formFieldGroup({
    required List<Widget> children,
    String? title,
    double spacing = DesignTokens.formFieldSpacing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title,
            style: DesignTextStyles.subtitle.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          const SizedBox(height: DesignTokens.space3),
        ],
        ...children.expand((child) => [
          child,
          if (child != children.last) SizedBox(height: spacing),
        ]),
      ],
    );
  }
  
  /// Inline form layout for related fields
  static Widget inlineFormFields({
    required List<Widget> children,
    double spacing = DesignTokens.space4,
    MainAxisAlignment alignment = MainAxisAlignment.start,
  }) {
    return Builder(
      builder: (context) {
        if (ResponsiveUtils.isMobile(context)) {
          return Column(
            children: children.expand((child) => [
              child,
              if (child != children.last) SizedBox(height: spacing),
            ]).toList(),
          );
        }
        
        return Row(
          mainAxisAlignment: alignment,
          children: children.expand((child) => [
            Expanded(child: child),
            if (child != children.last) SizedBox(width: spacing),
          ]).toList(),
        );
      },
    );
  }
  
  // =============================================================================
  // CARD LAYOUTS
  // =============================================================================
  
  /// Card grid layout with responsive behavior
  static Widget cardGrid({
    required List<Widget> cards,
    double spacing = DesignTokens.space4,
    int? forceColumns,
    double? cardAspectRatio,
  }) {
    return Builder(
      builder: (context) {
        final columns = forceColumns ?? ResponsiveUtils.getResponsiveGridColumns(context);
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: cardAspectRatio ?? 1.0,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }
  
  /// Masonry layout for cards with varying heights
  static Widget masonryLayout({
    required List<Widget> children,
    double spacing = DesignTokens.space4,
    int? forceColumns,
  }) {
    return Builder(
      builder: (context) {
        final columns = forceColumns ?? ResponsiveUtils.getResponsiveGridColumns(context);
        
        // Simple implementation - for production, consider using flutter_staggered_grid_view
        final columnChildren = List.generate(columns, (index) => <Widget>[]);
        
        for (int i = 0; i < children.length; i++) {
          columnChildren[i % columns].add(children[i]);
        }
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: columnChildren.map((columnWidgets) {
            return Expanded(
              child: Column(
                children: columnWidgets.expand((widget) => [
                  widget,
                  if (widget != columnWidgets.last) SizedBox(height: spacing),
                ]).toList(),
              ),
            );
          }).toList(),
        );
      },
    );
  }
  
  // =============================================================================
  // HEADER LAYOUTS
  // =============================================================================
  
  /// Page header with title, subtitle, and actions
  static Widget pageHeader({
    required String title,
    String? subtitle,
    List<Widget>? actions,
    Widget? leading,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(DesignTokens.space6),
          child: Row(
            children: [
              if (leading != null) ...[
                leading,
                const SizedBox(width: DesignTokens.space4),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: DesignTextStyles.titleLarge.copyWith(
                        fontWeight: DesignTokens.fontWeightBold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: DesignTokens.space1),
                      Text(
                        subtitle,
                        style: DesignTextStyles.body.copyWith(
                          color: DesignTokens.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (actions != null) ...[
                const SizedBox(width: DesignTokens.space4),
                Row(
                  children: actions.expand((action) => [
                    action,
                    if (action != actions.last) const SizedBox(width: DesignTokens.space2),
                  ]).toList(),
                ),
              ],
            ],
          ),
        ),
        if (showDivider)
          Container(
            height: 1,
            color: DesignTokens.borderPrimary,
          ),
      ],
    );
  }
  
  /// Section header with title and optional action
  static Widget sectionHeader({
    required String title,
    String? subtitle,
    Widget? action,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.only(bottom: DesignTokens.space4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DesignTextStyles.subtitle.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: DesignTokens.space1),
                  Text(
                    subtitle,
                    style: DesignTextStyles.body.copyWith(
                      color: DesignTokens.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }
}
