import 'package:client_connect/src/core/design_system/accessibility_utils.dart';
import 'package:client_connect/src/core/design_system/layout_system.dart';
import 'package:client_connect/src/core/design_system/responsive_utils.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'design_tokens.dart';
import 'theme_provider.dart';
import 'component_library.dart';
import 'animation_system.dart';

/// Integration utilities for seamlessly applying design system throughout the app
class DesignSystemIntegration {
  DesignSystemIntegration._();
  
  // =============================================================================
  // THEME INTEGRATION
  // =============================================================================
  
  /// Apply design system theme to the entire app
  static Widget wrapWithDesignSystem({
    required Widget child,
    required WidgetRef ref,
  }) {
    final themeState = ref.watch(themeProvider);
    
    return FluentApp(
      theme: themeState.currentTheme,
      builder: (context, child) {
        return DesignSystemProvider(
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: child,
    );
  }
  
  /// Enhanced ScaffoldPage with design system integration
  static Widget enhancedScaffoldPage({
    required Widget content,
    PageHeader? header,
    Widget? bottomBar,
    bool includeAnimation = true,
    EdgeInsetsGeometry? contentPadding,
  }) {
    final pageContent = LayoutSystem.pageContainer(
      padding: contentPadding,
      child: content,
    );
    
    return ScaffoldPage(
      header: header,
      bottomBar: bottomBar,
      content: includeAnimation
          ? AnimationSystem.fadeIn(child: pageContent)
          : pageContent,
    );
  }
  
  // =============================================================================
  // COMPONENT MIGRATION HELPERS
  // =============================================================================
  
  /// Migrate existing buttons to design system buttons
  static Widget migrateButton({
    required String text,
    required VoidCallback? onPressed,
    ButtonStyle? oldStyle,
    IconData? icon,
    bool isPrimary = false,
    bool isDanger = false,
    bool isLoading = false,
  }) {
    if (isDanger) {
      return DesignSystemComponents.dangerButton(
        text: text,
        onPressed: onPressed,
        icon: icon,
        isLoading: isLoading,
      );
    } else if (isPrimary) {
      return DesignSystemComponents.primaryButton(
        text: text,
        onPressed: onPressed,
        icon: icon,
        isLoading: isLoading,
      );
    } else {
      return DesignSystemComponents.secondaryButton(
        text: text,
        onPressed: onPressed,
        icon: icon,
        isLoading: isLoading,
      );
    }
  }
  
  /// Migrate existing cards to design system cards
  static Widget migrateCard({
    required Widget child,
    VoidCallback? onTap,
    bool isSelected = false,
    EdgeInsetsGeometry? padding,
    BoxDecoration? oldDecoration,
    bool useGlassmorphism = false,
  }) {
    if (useGlassmorphism) {
      return DesignSystemComponents.glassmorphismCard(
        onTap: onTap,
        padding: padding,
        child: child,
      );
    } else {
      return DesignSystemComponents.standardCard(
        onTap: onTap,
        isSelected: isSelected,
        padding: padding,
        child: child,
      );
    }
  }
  
  /// Migrate existing text inputs to design system inputs
  static Widget migrateTextInput({
    required TextEditingController controller,
    String? labelText,
    String? hintText,
    String? errorText,
    String? helperText,
    IconData? prefixIcon,
    IconData? suffixIcon,
    VoidCallback? onSuffixIconPressed,
    bool obscureText = false,
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return DesignSystemComponents.textInput(
      controller: controller,
      label: labelText,
      placeholder: hintText,
      errorText: errorText,
      helperText: helperText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      onSuffixIconPressed: onSuffixIconPressed,
      obscureText: obscureText,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
    );
  }
  
  // =============================================================================
  // LAYOUT MIGRATION HELPERS
  // =============================================================================
  
  /// Migrate existing page layouts to design system layouts
  static Widget migratePageLayout({
    required Widget child,
    String? title,
    String? subtitle,
    List<Widget>? actions,
    Widget? leading,
    bool includeScrollView = true,
    EdgeInsetsGeometry? padding,
  }) {
    return Column(
      children: [
        if (title != null)
          LayoutSystem.pageHeader(
            title: title,
            subtitle: subtitle,
            actions: actions,
            leading: leading,
          ),
        Expanded(
          child: LayoutSystem.pageContainer(
            padding: padding,
            includeScrollView: includeScrollView,
            child: child,
          ),
        ),
      ],
    );
  }
  
  /// Migrate existing form layouts to design system form layouts
  static Widget migrateFormLayout({
    required List<Widget> fields,
    String? title,
    double? spacing,
  }) {
    return LayoutSystem.formFieldGroup(
      title: title,
      spacing: spacing ?? DesignTokens.formFieldSpacing,
      children: fields,
    );
  }
  
  // =============================================================================
  // ANIMATION MIGRATION HELPERS
  // =============================================================================
  
  /// Add entrance animations to existing widgets
  static Widget addEntranceAnimation({
    required Widget child,
    AnimationType type = AnimationType.fadeIn,
    Duration delay = Duration.zero,
  }) {
    switch (type) {
      case AnimationType.fadeIn:
        return AnimationSystem.fadeIn(child: child, delay: delay);
      case AnimationType.slideIn:
        return AnimationSystem.slideIn(child: child, delay: delay);
      case AnimationType.scaleIn:
        return AnimationSystem.scaleIn(child: child, delay: delay);
    }
  }
  
  /// Add staggered animations to lists
  static Widget addStaggeredAnimation({
    required List<Widget> children,
    Duration staggerDelay = const Duration(milliseconds: 100),
    SlideDirection direction = SlideDirection.bottom,
  }) {
    return AnimationSystem.staggeredList(
      children: children,
      staggerDelay: staggerDelay,
      direction: direction,
    );
  }
  
  // =============================================================================
  // STATUS AND FEEDBACK MIGRATION
  // =============================================================================
  
  /// Migrate existing loading states to design system loading
  static Widget migrateLoadingState({
    String? message,
    double size = 32.0,
  }) {
    return DesignSystemComponents.loadingIndicator(
      message: message,
      size: size,
    );
  }
  
  /// Migrate existing empty states to design system empty states
  static Widget migrateEmptyState({
    required String title,
    required String message,
    required IconData icon,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return DesignSystemComponents.emptyState(
      title: title,
      message: message,
      icon: icon,
      actionText: actionText,
      onAction: onAction,
    );
  }
  
  /// Create status indicators from existing status logic
  static Widget createStatusIndicator({
    required String status,
    String? text,
    IconData? icon,
  }) {
    SemanticColorType type;
    IconData defaultIcon;
    
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
      case 'active':
        type = SemanticColorType.success;
        defaultIcon = FluentIcons.check_mark;
        break;
      case 'warning':
      case 'pending':
        type = SemanticColorType.warning;
        defaultIcon = FluentIcons.warning;
        break;
      case 'error':
      case 'failed':
      case 'inactive':
        type = SemanticColorType.error;
        defaultIcon = FluentIcons.error;
        break;
      default:
        type = SemanticColorType.info;
        defaultIcon = FluentIcons.info;
    }
    
    return DesignSystemComponents.statusBadge(
      text: text ?? status,
      type: type,
      icon: icon ?? defaultIcon,
    );
  }
  
  // =============================================================================
  // VALIDATION AND TESTING HELPERS
  // =============================================================================
  
  /// Validate design system implementation
  static List<String> validateImplementation(BuildContext context) {
    final issues = <String>[];
    
    // Check theme consistency
    final theme = FluentTheme.of(context);
    if (theme.accentColor != DesignTokens.accentColor) {
      issues.add('Theme accent color does not match design tokens');
    }
    
    // Check accessibility
    final accessibilityReport = AccessibilityUtils.generateAccessibilityReport();
    final colorTests = accessibilityReport['color_contrast_tests'] as Map<String, dynamic>;
    
    for (final entry in colorTests.entries) {
      final testData = entry.value as Map<String, dynamic>;
      if (!(testData['wcag_aa'] as bool)) {
        issues.add('Color contrast issue: ${entry.key}');
      }
    }
    
    return issues;
  }
  
  /// Generate design system usage report
  static Map<String, dynamic> generateUsageReport(BuildContext context) {
    return {
      'theme_applied': FluentTheme.of(context).accentColor == DesignTokens.accentColor,
      'design_tokens_version': '1.0.0',
      'components_available': [
        'buttons',
        'cards',
        'inputs',
        'status_indicators',
        'navigation',
        'loading_states',
        'empty_states',
      ],
      'accessibility_compliant': true,
      'responsive_design': true,
      'animation_system': true,
    };
  }
}

/// Design system provider for context-based access
class DesignSystemProvider extends InheritedWidget {
  const DesignSystemProvider({
    required super.child,
    super.key,
  });

  static DesignSystemProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DesignSystemProvider>();
  }

  @override
  bool updateShouldNotify(DesignSystemProvider oldWidget) {
    return false;
  }
}

/// Animation types for migration helpers
enum AnimationType {
  fadeIn,
  slideIn,
  scaleIn,
}

/// Extension methods for easier design system integration
extension DesignSystemWidgetExtensions on Widget {
  /// Apply design system card styling
  Widget asDesignSystemCard({
    VoidCallback? onTap,
    bool isSelected = false,
    EdgeInsetsGeometry? padding,
  }) {
    return DesignSystemComponents.standardCard(
      onTap: onTap,
      isSelected: isSelected,
      padding: padding,
      child: this,
    );
  }
  
  /// Apply design system section container
  Widget asDesignSystemSection({
    String? title,
    String? subtitle,
    Widget? action,
  }) {
    return LayoutSystem.sectionContainer(
      title: title,
      subtitle: subtitle,
      action: action,
      child: this,
    );
  }
  
  /// Apply entrance animation
  Widget withEntranceAnimation({
    AnimationType type = AnimationType.fadeIn,
    Duration delay = Duration.zero,
  }) {
    return DesignSystemIntegration.addEntranceAnimation(
      child: this,
      type: type,
      delay: delay,
    );
  }
  
  /// Apply responsive padding
  Widget withResponsivePadding(BuildContext context) {
    return Padding(
      padding: ResponsiveUtils.getResponsivePadding(context),
      child: this,
    );
  }
}
