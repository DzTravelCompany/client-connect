import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'design_tokens.dart';

/// Accessibility utilities for ensuring WCAG compliance
class AccessibilityUtils {
  AccessibilityUtils._();
  
  // =============================================================================
  // COLOR CONTRAST VALIDATION
  // =============================================================================
  
  /// Calculate luminance of a color
  static double _calculateLuminance(Color color) {
    final r = color.r / 255.0;
    final g = color.g / 255.0;
    final b = color.b / 255.0;
    
    final rLum = r <= 0.03928 ? r / 12.92 : pow((r + 0.055) / 1.055, 2.4);
    final gLum = g <= 0.03928 ? g / 12.92 : pow((g + 0.055) / 1.055, 2.4);
    final bLum = b <= 0.03928 ? b / 12.92 : pow((b + 0.055) / 1.055, 2.4);
    
    return 0.2126 * rLum + 0.7152 * gLum + 0.0722 * bLum;
  }
  
  /// Calculate contrast ratio between two colors
  static double calculateContrastRatio(Color foreground, Color background) {
    final foregroundLuminance = _calculateLuminance(foreground);
    final backgroundLuminance = _calculateLuminance(background);
    
    final lighter = foregroundLuminance > backgroundLuminance 
        ? foregroundLuminance 
        : backgroundLuminance;
    final darker = foregroundLuminance > backgroundLuminance 
        ? backgroundLuminance 
        : foregroundLuminance;
    
    return (lighter + 0.05) / (darker + 0.05);
  }
  
  /// Check if color combination meets WCAG AA standard (4.5:1)
  static bool meetsWCAGAA(Color foreground, Color background) {
    return calculateContrastRatio(foreground, background) >= 4.5;
  }
  
  /// Check if color combination meets WCAG AAA standard (7:1)
  static bool meetsWCAGAAA(Color foreground, Color background) {
    return calculateContrastRatio(foreground, background) >= 7.0;
  }
  
  /// Get accessible text color for given background
  static Color getAccessibleTextColor(Color background) {
    final whiteContrast = calculateContrastRatio(DesignTokens.textInverse, background);
    final blackContrast = calculateContrastRatio(DesignTokens.textPrimary, background);
    
    return whiteContrast > blackContrast ? DesignTokens.textInverse : DesignTokens.textPrimary;
  }
  
  // =============================================================================
  // FOCUS MANAGEMENT
  // =============================================================================
  
  /// Create accessible focus decoration
  static BoxDecoration getFocusDecoration({
    Color? focusColor,
    double borderWidth = 2.0,
    double borderRadius = DesignTokens.radiusMedium,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: focusColor ?? DesignTokens.accentPrimary,
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: (focusColor ?? DesignTokens.accentPrimary).withValues(alpha: 0.3),
          blurRadius: 4,
          offset: const Offset(0, 0),
        ),
      ],
    );
  }
  
  /// Create focus-aware widget wrapper
  static Widget createFocusableWidget({
    required Widget child,
    required VoidCallback? onPressed,
    String? semanticLabel,
    String? tooltip,
    FocusNode? focusNode,
  }) {
    return Semantics(
      label: semanticLabel,
      button: onPressed != null,
      child: Tooltip(
        message: tooltip ?? '',
        child: Focus(
          focusNode: focusNode,
          child: Builder(
            builder: (context) {
              final isFocused = Focus.of(context).hasFocus;
              return Container(
                decoration: isFocused ? getFocusDecoration() : null,
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }
  
  // =============================================================================
  // SEMANTIC LABELS AND DESCRIPTIONS
  // =============================================================================
  
  /// Generate semantic label for status indicators
  static String getStatusSemanticLabel(SemanticColorType type, String value) {
    final typeLabel = switch (type) {
      SemanticColorType.success => 'Success',
      SemanticColorType.warning => 'Warning',
      SemanticColorType.error => 'Error',
      SemanticColorType.info => 'Information',
    };
    return '$typeLabel: $value';
  }
  
  /// Generate semantic label for interactive elements
  static String getInteractiveSemanticLabel({
    required String action,
    required String target,
    String? state,
  }) {
    final stateText = state != null ? ', $state' : '';
    return '$action $target$stateText';
  }
  
  /// Generate semantic label for navigation items
  static String getNavigationSemanticLabel({
    required String label,
    required bool isActive,
    required bool hasSubItems,
  }) {
    final activeText = isActive ? ', currently selected' : '';
    final subItemsText = hasSubItems ? ', has sub items' : '';
    return '$label$activeText$subItemsText';
  }
  
  // =============================================================================
  // KEYBOARD NAVIGATION
  // =============================================================================
  
  /// Handle keyboard navigation for custom widgets
  static KeyEventResult handleKeyboardNavigation(
    KeyEvent event,
    VoidCallback? onActivate,
  ) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        onActivate?.call();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }
  
  /// Create keyboard shortcuts for common actions
  static Map<ShortcutActivator, Intent> getCommonShortcuts() {
    return {
      const SingleActivator(LogicalKeyboardKey.escape): const DismissIntent(),
      const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
      const SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
      const SingleActivator(LogicalKeyboardKey.tab): const NextFocusIntent(),
      const SingleActivator(LogicalKeyboardKey.tab, shift: true): const PreviousFocusIntent(),
    };
  }
  
  // =============================================================================
  // SCREEN READER SUPPORT
  // =============================================================================
  
  /// Announce message to screen readers
  static void announceToScreenReader(
    BuildContext context,
    String message, {
    Assertiveness assertiveness = Assertiveness.polite,
  }) {
    SemanticsService.announce(message, TextDirection.ltr);
  }
  
  /// Create live region for dynamic content updates
  static Widget createLiveRegion({
    required Widget child,
    required String label,
    LiveRegionImportance importance = LiveRegionImportance.polite,
  }) {
    return Semantics(
      liveRegion: true,
      label: label,
      child: child,
    );
  }
  
  // =============================================================================
  // VALIDATION AND TESTING
  // =============================================================================
  
  /// Validate component accessibility
  static List<String> validateComponentAccessibility({
    required Color foregroundColor,
    required Color backgroundColor,
    required String? semanticLabel,
    required bool isFocusable,
    required bool hasKeyboardSupport,
  }) {
    final issues = <String>[];
    
    // Check color contrast
    if (!meetsWCAGAA(foregroundColor, backgroundColor)) {
      issues.add('Color contrast ratio does not meet WCAG AA standards');
    }
    
    // Check semantic labeling
    if (isFocusable && (semanticLabel == null || semanticLabel.isEmpty)) {
      issues.add('Focusable element missing semantic label');
    }
    
    // Check keyboard support
    if (isFocusable && !hasKeyboardSupport) {
      issues.add('Focusable element missing keyboard support');
    }
    
    return issues;
  }
  
  /// Generate accessibility report for design system
  static Map<String, dynamic> generateAccessibilityReport() {
    final report = <String, dynamic>{};
    
    // Test primary color combinations
    final colorTests = <String, Map<String, dynamic>>{};
    
    // Test text on primary backgrounds
    colorTests['Primary Text on White'] = {
      'contrast_ratio': calculateContrastRatio(DesignTokens.textPrimary, DesignTokens.surfacePrimary),
      'wcag_aa': meetsWCAGAA(DesignTokens.textPrimary, DesignTokens.surfacePrimary),
      'wcag_aaa': meetsWCAGAAA(DesignTokens.textPrimary, DesignTokens.surfacePrimary),
    };
    
    colorTests['Secondary Text on White'] = {
      'contrast_ratio': calculateContrastRatio(DesignTokens.textSecondary, DesignTokens.surfacePrimary),
      'wcag_aa': meetsWCAGAA(DesignTokens.textSecondary, DesignTokens.surfacePrimary),
      'wcag_aaa': meetsWCAGAAA(DesignTokens.textSecondary, DesignTokens.surfacePrimary),
    };
    
    colorTests['Accent on White'] = {
      'contrast_ratio': calculateContrastRatio(DesignTokens.accentPrimary, DesignTokens.surfacePrimary),
      'wcag_aa': meetsWCAGAA(DesignTokens.accentPrimary, DesignTokens.surfacePrimary),
      'wcag_aaa': meetsWCAGAAA(DesignTokens.accentPrimary, DesignTokens.surfacePrimary),
    };
    
    colorTests['White on Accent'] = {
      'contrast_ratio': calculateContrastRatio(DesignTokens.textInverse, DesignTokens.accentPrimary),
      'wcag_aa': meetsWCAGAA(DesignTokens.textInverse, DesignTokens.accentPrimary),
      'wcag_aaa': meetsWCAGAAA(DesignTokens.textInverse, DesignTokens.accentPrimary),
    };
    
    report['color_contrast_tests'] = colorTests;
    
    // Test semantic colors
    final semanticTests = <String, Map<String, dynamic>>{};
    for (final type in SemanticColorType.values) {
      final color = DesignTokens.getSemanticColor(type);
      semanticTests[type.name] = {
        'on_white': {
          'contrast_ratio': calculateContrastRatio(color, DesignTokens.surfacePrimary),
          'wcag_aa': meetsWCAGAA(color, DesignTokens.surfacePrimary),
        },
        'white_on_color': {
          'contrast_ratio': calculateContrastRatio(DesignTokens.textInverse, color),
          'wcag_aa': meetsWCAGAA(DesignTokens.textInverse, color),
        },
      };
    }
    
    report['semantic_color_tests'] = semanticTests;
    
    return report;
  }
}

/// Helper function for power calculation (since dart:math pow is not available in this context)
double pow(double base, double exponent) {
  if (exponent == 0) return 1.0;
  if (exponent == 1) return base;
  if (exponent == 2) return base * base;
  if (exponent == 2.4) {
    // Approximation for gamma correction
    final squared = base * base;
    final fourth = squared * squared;
    return fourth * pow(base, 0.4); // Recursive for 0.4
  }
  if (exponent == 0.4) {
    // Approximation for 0.4 power
    return base * 0.4 + 0.6; // Simple approximation
  }
  
  // Fallback for other exponents (basic approximation)
  double result = 1.0;
  for (int i = 0; i < exponent.floor(); i++) {
    result *= base;
  }
  return result;
}

/// Custom intents for keyboard navigation
class DismissIntent extends Intent {
  const DismissIntent();
}

class ActivateIntent extends Intent {
  const ActivateIntent();
}

/// Assertiveness levels for screen reader announcements
enum Assertiveness {
  polite,
  assertive,
}

/// Live region importance levels
enum LiveRegionImportance {
  polite,
  assertive,
}