import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'design_tokens.dart';

/// Theme mode enumeration
enum AppThemeMode {
  light,
  dark,
  system,
}

/// Theme state class
class ThemeState {
  final AppThemeMode mode;
  final FluentThemeData lightTheme;
  final FluentThemeData darkTheme;
  
  const ThemeState({
    required this.mode,
    required this.lightTheme,
    required this.darkTheme,
  });
  
  FluentThemeData get currentTheme {
    switch (mode) {
      case AppThemeMode.light:
        return lightTheme;
      case AppThemeMode.dark:
        return darkTheme;
      case AppThemeMode.system:
        // For now, default to light theme
        // In a real implementation, you'd check system theme
        return lightTheme;
    }
  }
  
  ThemeState copyWith({
    AppThemeMode? mode,
    FluentThemeData? lightTheme,
    FluentThemeData? darkTheme,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
      lightTheme: lightTheme ?? this.lightTheme,
      darkTheme: darkTheme ?? this.darkTheme,
    );
  }
}

/// Theme provider notifier
class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(ThemeState(
    mode: AppThemeMode.light,
    lightTheme: _createLightTheme(),
    darkTheme: _createDarkTheme(),
  ));
  
  void setThemeMode(AppThemeMode mode) {
    state = state.copyWith(mode: mode);
  }
  
  void toggleTheme() {
    final newMode = state.mode == AppThemeMode.light 
        ? AppThemeMode.dark 
        : AppThemeMode.light;
    setThemeMode(newMode);
  }
}

/// Theme provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

/// Current theme provider (computed)
final currentThemeProvider = Provider<FluentThemeData>((ref) {
  final themeState = ref.watch(themeProvider);
  return themeState.currentTheme;
});

/// Create light theme using design tokens
FluentThemeData _createLightTheme() {
  return FluentThemeData(
    brightness: Brightness.light,
    
    // Primary colors
    accentColor: DesignTokens.accentColor,
    
    // Background colors
    scaffoldBackgroundColor: DesignTokens.surfacePrimary,
    cardColor: DesignTokens.surfaceSecondary,
    
    // Typography
    typography: Typography.raw(
      display: DesignTextStyles.display,
      title: DesignTextStyles.title,
      titleLarge: DesignTextStyles.titleLarge,
      subtitle: DesignTextStyles.subtitle,
      body: DesignTextStyles.body,
      bodyLarge: DesignTextStyles.bodyLarge,
      caption: DesignTextStyles.caption,
    ),
    
    // Resources (colors for various UI elements)
    resources: ResourceDictionary.light(
      // Card colors
      cardBackgroundFillColorDefault: DesignTokens.surfacePrimary,
      cardBackgroundFillColorSecondary: DesignTokens.surfaceSecondary,
      
      // Text colors
      textFillColorPrimary: DesignTokens.textPrimary,
      textFillColorSecondary: DesignTokens.textSecondary,
      textFillColorTertiary: DesignTokens.textTertiary,
      
      // Border colors
      dividerStrokeColorDefault: DesignTokens.borderSecondary,
      
      // Control colors
      controlFillColorDefault: DesignTokens.surfaceSecondary,
      controlFillColorSecondary: DesignTokens.surfaceTertiary,
      controlStrokeColorDefault: DesignTokens.borderPrimary,
      
      // Accent colors
      textOnAccentFillColorSelectedText: DesignTokens.accentPrimary,
      textOnAccentFillColorPrimary: DesignTokens.accentPrimary,
    ),
    
    // Button theme
    buttonTheme: ButtonThemeData(
      defaultButtonStyle: ButtonStyle(
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
            horizontal: DesignTokens.buttonPadding,
            vertical: DesignTokens.space2,
          ),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          ),
        ),
      ),
      filledButtonStyle: ButtonStyle(
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
            horizontal: DesignTokens.buttonPadding,
            vertical: DesignTokens.space2,
          ),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          ),
        ),
      ),
    ),
    
    // Navigation pane theme
    navigationPaneTheme: NavigationPaneThemeData(
      backgroundColor: DesignTokens.getGlassColor(
        DesignTokens.glassPrimary, 
        DesignTokens.glassOpacityPrimary,
      ),
      highlightColor: DesignTokens.accentPrimary,
      selectedIconColor: WidgetStateProperty.all(DesignTokens.accentPrimary),
      unselectedIconColor: WidgetStateProperty.all(DesignTokens.textSecondary),
      selectedTextStyle: WidgetStateProperty.all(
        DesignTextStyles.body.copyWith(
          color: DesignTokens.accentPrimary,
          fontWeight: DesignTokens.fontWeightSemiBold,
        ),
      ),
      unselectedTextStyle: WidgetStateProperty.all(
        DesignTextStyles.body.copyWith(
          color: DesignTokens.textSecondary,
        ),
      ),
    ),
  );
}

/// Create dark theme using design tokens
FluentThemeData _createDarkTheme() {
  // For now, create a basic dark theme
  // This can be expanded later with proper dark mode colors
  return FluentThemeData(
    brightness: Brightness.dark,
    accentColor: DesignTokens.accentColor,
    scaffoldBackgroundColor: DesignTokens.neutralGray900,
    cardColor: DesignTokens.neutralGray800,
    
    typography: Typography.raw(
      display: DesignTextStyles.display.copyWith(color: DesignTokens.textInverse),
      title: DesignTextStyles.title.copyWith(color: DesignTokens.textInverse),
      titleLarge: DesignTextStyles.titleLarge.copyWith(color: DesignTokens.textInverse),
      subtitle: DesignTextStyles.subtitle.copyWith(color: DesignTokens.textInverse),
      body: DesignTextStyles.body.copyWith(color: DesignTokens.textInverse),
      bodyLarge: DesignTextStyles.bodyLarge.copyWith(color: DesignTokens.textInverse),
      caption: DesignTextStyles.caption.copyWith(color: DesignTokens.neutralGray400),
    ),
  );
}

/// Design system theme extension
extension DesignSystemTheme on FluentThemeData {
  /// Get glassmorphism decoration
  BoxDecoration get glassmorphismDecoration => BoxDecoration(
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
    border: Border.all(
      color: DesignTokens.withOpacity(
        DesignTokens.borderPrimary, 
        0.3,
      ),
      width: 1,
    ),
    boxShadow: DesignTokens.glassmorpismShadow,
  );
  
  /// Get card decoration
  BoxDecoration get cardDecoration => BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
    border: Border.all(
      color: DesignTokens.borderPrimary,
      width: 1,
    ),
    boxShadow: DesignTokens.shadowLow,
  );
  
  /// Get elevated card decoration
  BoxDecoration get elevatedCardDecoration => BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
    border: Border.all(
      color: DesignTokens.borderPrimary,
      width: 1,
    ),
    boxShadow: DesignTokens.shadowMedium,
  );
  
  /// Get accent gradient
  LinearGradient get accentGradient => LinearGradient(
    colors: [
      DesignTokens.accentPrimary,
      DesignTokens.accentSecondary,
    ],
  );
  
  /// Get semantic color
  Color getSemanticColor(SemanticColorType type) {
    return DesignTokens.getSemanticColor(type);
  }
}
