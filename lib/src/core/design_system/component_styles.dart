import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show InputDecoration, OutlineInputBorder;
import 'design_tokens.dart';

/// Centralized component styles using design tokens
class ComponentStyles {
  ComponentStyles._();
  
  // =============================================================================
  // BUTTON STYLES
  // =============================================================================
  
  /// Primary button style
  static ButtonStyle get primaryButton => ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return DesignTokens.neutralGray300;
      }
      if (states.contains(WidgetState.pressed)) {
        return DesignTokens.accentTertiary;
      }
      if (states.contains(WidgetState.hovered)) {
        return DesignTokens.accentSecondary;
      }
      return DesignTokens.accentPrimary;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return DesignTokens.textTertiary;
      }
      return DesignTokens.textInverse;
    }),
    padding: WidgetStateProperty.all(
      const EdgeInsets.symmetric(
        horizontal: DesignTokens.space4,
        vertical: DesignTokens.space3,
      ),
    ),
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      ),
    ),
    elevation: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.hovered)) {
        return DesignTokens.elevationMedium;
      }
      return DesignTokens.elevationLow;
    }),
  );
  
  /// Secondary button style
  static ButtonStyle get secondaryButton => ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return DesignTokens.neutralGray200;
      }
      if (states.contains(WidgetState.pressed)) {
        return DesignTokens.neutralGray300;
      }
      if (states.contains(WidgetState.hovered)) {
        return DesignTokens.neutralGray100;
      }
      return DesignTokens.surfacePrimary;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return DesignTokens.textTertiary;
      }
      return DesignTokens.textPrimary;
    }),
    padding: WidgetStateProperty.all(
      const EdgeInsets.symmetric(
        horizontal: DesignTokens.space4,
        vertical: DesignTokens.space3,
      ),
    ),
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      ),
    ),
  );
  
  /// Ghost button style
  static ButtonStyle get ghostButton => ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return DesignTokens.withOpacity(DesignTokens.accentPrimary, 0.1);
      }
      if (states.contains(WidgetState.hovered)) {
        return DesignTokens.withOpacity(DesignTokens.accentPrimary, 0.05);
      }
      return Colors.transparent;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return DesignTokens.textTertiary;
      }
      return DesignTokens.accentPrimary;
    }),
    padding: WidgetStateProperty.all(
      const EdgeInsets.symmetric(
        horizontal: DesignTokens.space4,
        vertical: DesignTokens.space3,
      ),
    ),
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      ),
    ),
  );
  
  /// Danger button style
  static ButtonStyle get dangerButton => ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return DesignTokens.neutralGray300;
      }
      if (states.contains(WidgetState.pressed)) {
        return DesignTokens.semanticErrorDark;
      }
      if (states.contains(WidgetState.hovered)) {
        return DesignTokens.semanticError;
      }
      return DesignTokens.semanticError;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return DesignTokens.textTertiary;
      }
      return DesignTokens.textInverse;
    }),
    padding: WidgetStateProperty.all(
      const EdgeInsets.symmetric(
        horizontal: DesignTokens.space4,
        vertical: DesignTokens.space3,
      ),
    ),
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      ),
    ),
  );
  
  /// Small button style
  static ButtonStyle get smallButton => primaryButton.copyWith(
    padding: WidgetStateProperty.all(
      const EdgeInsets.symmetric(
        horizontal: DesignTokens.space3,
        vertical: DesignTokens.space2,
      ),
    ),
    textStyle: WidgetStateProperty.all(
      DesignTextStyles.caption.copyWith(
        fontWeight: DesignTokens.fontWeightMedium,
      ),
    ),
  );
  
  /// Icon button style
  static ButtonStyle get iconButton => ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return DesignTokens.withOpacity(DesignTokens.accentPrimary, 0.1);
      }
      if (states.contains(WidgetState.hovered)) {
        return DesignTokens.withOpacity(DesignTokens.accentPrimary, 0.05);
      }
      return Colors.transparent;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return DesignTokens.textTertiary;
      }
      return DesignTokens.textSecondary;
    }),
    padding: WidgetStateProperty.all(
      const EdgeInsets.all(DesignTokens.space2),
    ),
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
      ),
    ),
  );
  
  // =============================================================================
  // CARD STYLES
  // =============================================================================
  
  /// Standard card decoration
  static BoxDecoration get standardCard => BoxDecoration(
    color: DesignTokens.surfacePrimary,
    borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
    border: Border.all(
      color: DesignTokens.borderPrimary,
      width: 1,
    ),
    boxShadow: DesignTokens.shadowLow,
  );
  
  /// Elevated card decoration
  static BoxDecoration get elevatedCard => BoxDecoration(
    color: DesignTokens.surfacePrimary,
    borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
    border: Border.all(
      color: DesignTokens.borderPrimary,
      width: 1,
    ),
    boxShadow: DesignTokens.shadowMedium,
  );
  
  /// Interactive card decoration (with hover state)
  static BoxDecoration getInteractiveCard({bool isHovered = false, bool isSelected = false}) {
    return BoxDecoration(
      color: isSelected 
          ? DesignTokens.withOpacity(DesignTokens.accentPrimary, 0.05)
          : DesignTokens.surfacePrimary,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      border: Border.all(
        color: isSelected 
            ? DesignTokens.accentPrimary
            : isHovered 
                ? DesignTokens.withOpacity(DesignTokens.accentPrimary, 0.5)
                : DesignTokens.borderPrimary,
        width: isSelected ? 2 : 1,
      ),
      boxShadow: isHovered ? DesignTokens.shadowMedium : DesignTokens.shadowLow,
    );
  }
  
  /// Glassmorphism card decoration
  static BoxDecoration get glassmorphismCard => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        DesignTokens.getGlassColor(
          DesignTokens.glassPrimary, 
          DesignTokens.glassOpacityPrimary,
        ),
        DesignTokens.getGlassColor(
          DesignTokens.glassSecondary, 
          DesignTokens.glassOpacitySecondary,
        ),
      ],
    ),
    borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
    border: Border.all(
      color: DesignTokens.withOpacity(DesignTokens.borderPrimary, 0.3),
      width: 1,
    ),
    boxShadow: DesignTokens.glassmorpismShadow,
  );
  
  // =============================================================================
  // INPUT STYLES
  // =============================================================================
  
  /// Standard text input decoration
  static InputDecoration get standardInput => InputDecoration(
    filled: true,
    fillColor: DesignTokens.surfaceSecondary,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      borderSide: const BorderSide(
        color: DesignTokens.borderPrimary,
        width: 1,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      borderSide: const BorderSide(
        color: DesignTokens.borderPrimary,
        width: 1,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      borderSide: const BorderSide(
        color: DesignTokens.accentPrimary,
        width: 2,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      borderSide: const BorderSide(
        color: DesignTokens.semanticError,
        width: 1,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      borderSide: const BorderSide(
        color: DesignTokens.semanticError,
        width: 2,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: DesignTokens.space4,
      vertical: DesignTokens.space3,
    ),
    hintStyle: DesignTextStyles.body.copyWith(
      color: DesignTokens.textTertiary,
    ),
    labelStyle: DesignTextStyles.body.copyWith(
      color: DesignTokens.textSecondary,
    ),
  );
  
  // =============================================================================
  // STATUS INDICATORS
  // =============================================================================
  
  /// Status badge decoration
  static BoxDecoration getStatusBadge(SemanticColorType type) {
    final color = DesignTokens.getSemanticColor(type);
    return BoxDecoration(
      color: DesignTokens.withOpacity(color, 0.1),
      borderRadius: BorderRadius.circular(DesignTokens.radiusRound),
      border: Border.all(
        color: DesignTokens.withOpacity(color, 0.3),
        width: 1,
      ),
    );
  }
  
  /// Status dot decoration
  static BoxDecoration getStatusDot(SemanticColorType type) {
    final color = DesignTokens.getSemanticColor(type);
    return BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: DesignTokens.withOpacity(color, 0.3),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
  
  // =============================================================================
  // NAVIGATION STYLES
  // =============================================================================
  
  /// Navigation item style
  static BoxDecoration getNavigationItem({
    bool isActive = false,
    bool isHovered = false,
  }) {
    return BoxDecoration(
      color: isActive
          ? DesignTokens.withOpacity(DesignTokens.accentPrimary, 0.1)
          : isHovered
              ? DesignTokens.withOpacity(DesignTokens.accentPrimary, 0.05)
              : Colors.transparent,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      border: isActive
          ? Border.all(
              color: DesignTokens.withOpacity(DesignTokens.accentPrimary, 0.3),
              width: 1,
            )
          : null,
    );
  }
  
  // =============================================================================
  // UTILITY METHODS
  // =============================================================================
  
  /// Get button style by variant
  static ButtonStyle getButtonStyle(ButtonVariant variant) {
    switch (variant) {
      case ButtonVariant.primary:
        return primaryButton;
      case ButtonVariant.secondary:
        return secondaryButton;
      case ButtonVariant.ghost:
        return ghostButton;
      case ButtonVariant.danger:
        return dangerButton;
      case ButtonVariant.small:
        return smallButton;
      case ButtonVariant.icon:
        return iconButton;
    }
  }
  
  /// Get card decoration by variant
  static BoxDecoration getCardDecoration(CardVariant variant) {
    switch (variant) {
      case CardVariant.standard:
        return standardCard;
      case CardVariant.elevated:
        return elevatedCard;
      case CardVariant.glassmorphism:
        return glassmorphismCard;
    }
  }
}

/// Button variant enumeration
enum ButtonVariant {
  primary,
  secondary,
  ghost,
  danger,
  small,
  icon,
}

/// Card variant enumeration
enum CardVariant {
  standard,
  elevated,
  glassmorphism,
}
