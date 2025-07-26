import 'package:fluent_ui/fluent_ui.dart';

/// Comprehensive design token system for Client Connect CRM
/// Implements professional Command Center design philosophy
class DesignTokens {
  // Private constructor to prevent instantiation
  DesignTokens._();

  static final AccentColor accentColor = AccentColor.swatch(
    {
      // The 'normal' swatch is the default accent color.
      'normal': accentPrimary,

      // Lighter shades are used for hover effects or backgrounds.
      // Since you haven't defined them, we can reuse the primary or generate them.
      // Let's reuse the primary for a simple, working setup.
      'lightest': accentPrimary.withValues(alpha: 0.6),
      'lighter': accentPrimary.withValues(alpha: 0.8),
      'light': accentPrimary,

      // Darker shades are used for press effects or borders.
      'dark': accentSecondary,
      'darker': accentTertiary,
      'darkest': accentTertiary, // Fallback for the darkest shade
    },
  );

  // =============================================================================
  // COLOR SYSTEM
  // =============================================================================
  
  /// Primary color palette - Professional blues and grays
  static const Color primaryBlue = Color(0xFF0F4C75);
  static const Color primaryBlueLight = Color(0xFF3282B8);
  static const Color primaryBlueDark = Color(0xFF0B3A5C);
  
  /// Accent color - Single vibrant color for CTAs and highlights
  static const Color accentPrimary = Color(0xFF00D4AA);   // This is our 'normal' shade
  static const Color accentSecondary = Color(0xFF00B894); // This is our 'dark' shade
  static const Color accentTertiary = Color(0xFF00A085);  // This is our 'darker' shade
  
  /// Neutral color palette
  static const Color neutralWhite = Color(0xFFFFFFFF);
  static const Color neutralGray50 = Color(0xFFFAFAFA);
  static const Color neutralGray100 = Color(0xFFF5F5F5);
  static const Color neutralGray200 = Color(0xFFEEEEEE);
  static const Color neutralGray300 = Color(0xFFE0E0E0);
  static const Color neutralGray400 = Color(0xFFBDBDBD);
  static const Color neutralGray500 = Color(0xFF9E9E9E);
  static const Color neutralGray600 = Color(0xFF757575);
  static const Color neutralGray700 = Color(0xFF616161);
  static const Color neutralGray800 = Color(0xFF424242);
  static const Color neutralGray900 = Color(0xFF212121);
  static const Color neutralBlack = Color(0xFF000000);
  
  /// Semantic colors
  static const Color semanticSuccess = Color(0xFF00C851);
  static const Color semanticSuccessLight = Color(0xFF69F0AE);
  static const Color semanticSuccessDark = Color(0xFF00A043);
  
  static const Color semanticWarning = Color(0xFFFFBB33);
  static const Color semanticWarningLight = Color(0xFFFFD54F);
  static const Color semanticWarningDark = Color(0xFFFF8F00);
  
  static const Color semanticError = Color(0xFFFF4444);
  static const Color semanticErrorLight = Color(0xFFFF8A80);
  static const Color semanticErrorDark = Color(0xFFD32F2F);
  
  static const Color semanticInfo = Color(0xFF33B5E5);
  static const Color semanticInfoLight = Color(0xFF81D4FA);
  static const Color semanticInfoDark = Color(0xFF0288D1);
  
  /// Surface colors for glassmorphism and layering
  static const Color surfacePrimary = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFFAFAFA);
  static const Color surfaceTertiary = Color(0xFFF5F5F5);
  
  /// Glassmorphism specific colors
  static const Color glassPrimary = Color(0xFFFFFFFF);
  static const Color glassSecondary = Color(0xFFF8F9FA);
  static const Color glassTertiary = Color(0xFFE9ECEF);
  
  /// Border colors
  static const Color borderPrimary = Color(0xFFE0E0E0);
  static const Color borderSecondary = Color(0xFFBDBDBD);
  static const Color borderAccent = accentPrimary;
  
  /// Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color textInverse = Color(0xFFFFFFFF);
  static const Color textAccent = accentPrimary;
  
  // =============================================================================
  // OPACITY VALUES
  // =============================================================================
  
  /// Standard opacity values for consistent transparency
  static const double opacityDisabled = 0.38;
  static const double opacityMedium = 0.60;
  static const double opacityHigh = 0.87;
  static const double opacityFull = 1.0;
  
  /// Glassmorphism opacity values
  static const double glassOpacityPrimary = 0.95;
  static const double glassOpacitySecondary = 0.85;
  static const double glassOpacityTertiary = 0.75;
  
  // =============================================================================
  // SPACING SYSTEM
  // =============================================================================
  
  /// Base spacing unit (4px) - All spacing should be multiples of this
  static const double spaceUnit = 4.0;
  
  /// Spacing scale
  static const double space1 = spaceUnit * 1; // 4px
  static const double space2 = spaceUnit * 2; // 8px
  static const double space3 = spaceUnit * 3; // 12px
  static const double space4 = spaceUnit * 4; // 16px
  static const double space5 = spaceUnit * 5; // 20px
  static const double space6 = spaceUnit * 6; // 24px
  static const double space8 = spaceUnit * 8; // 32px
  static const double space10 = spaceUnit * 10; // 40px
  static const double space12 = spaceUnit * 12; // 48px
  static const double space16 = spaceUnit * 16; // 64px
  static const double space20 = spaceUnit * 20; // 80px
  
  /// Component-specific spacing
  static const double cardPadding = space4; // 16px
  static const double cardMargin = space3; // 12px
  static const double buttonPadding = space3; // 12px
  static const double formFieldSpacing = space4; // 16px
  static const double sectionSpacing = space6; // 24px
  static const double pageMargin = space5; // 20px
  
  // =============================================================================
  // TYPOGRAPHY SYSTEM
  // =============================================================================
  
  /// Font families
  static const String fontFamilyPrimary = 'Segoe UI';
  static const String fontFamilySecondary = 'system-ui';
  static const String fontFamilyMonospace = 'Consolas';
  
  /// Font weights
  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  
  /// Font sizes
  static const double fontSizeCaption = 11.0;
  static const double fontSizeBody = 14.0;
  static const double fontSizeBodyLarge = 16.0;
  static const double fontSizeSubtitle = 18.0;
  static const double fontSizeTitle = 20.0;
  static const double fontSizeTitleLarge = 24.0;
  static const double fontSizeDisplay = 32.0;
  static const double fontSizeDisplayLarge = 40.0;
  
  /// Line heights
  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.4;
  static const double lineHeightRelaxed = 1.6;
  
  /// Letter spacing
  static const double letterSpacingTight = -0.5;
  static const double letterSpacingNormal = 0.0;
  static const double letterSpacingWide = 0.5;
  
  // =============================================================================
  // ELEVATION AND SHADOWS
  // =============================================================================
  
  /// Elevation levels
  static const double elevationNone = 0.0;
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
  static const double elevationVeryHigh = 16.0;
  
  /// Shadow definitions
  static List<BoxShadow> get shadowLow => [
    BoxShadow(
      color: neutralBlack.withValues(alpha: 0.08),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: neutralBlack.withValues(alpha: 0.12),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get shadowHigh => [
    BoxShadow(
      color: neutralBlack.withValues(alpha: 0.16),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
  
  /// Glassmorphism shadows
  static List<BoxShadow> get glassmorpismShadow => [
    BoxShadow(
      color: neutralBlack.withValues(alpha: 0.1),
      blurRadius: 20,
      offset: const Offset(0, 0),
    ),
  ];
  
  // =============================================================================
  // BORDER RADIUS
  // =============================================================================
  
  static const double radiusNone = 0.0;
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 16.0;
  static const double radiusRound = 50.0;
  
  // =============================================================================
  // ANIMATION DURATIONS
  // =============================================================================
  
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 200);
  static const Duration animationSlow = Duration(milliseconds: 300);
  static const Duration animationVerySlow = Duration(milliseconds: 500);
  
  // =============================================================================
  // BREAKPOINTS
  // =============================================================================
  
  static const double breakpointMobile = 480.0;
  static const double breakpointTablet = 768.0;
  static const double breakpointDesktop = 1024.0;
  static const double breakpointLargeDesktop = 1440.0;
  
  // =============================================================================
  // COMPONENT SIZES
  // =============================================================================
  
  /// Button sizes
  static const double buttonHeightSmall = 28.0;
  static const double buttonHeightMedium = 32.0;
  static const double buttonHeightLarge = 40.0;
  
  /// Icon sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 20.0;
  static const double iconSizeLarge = 24.0;
  static const double iconSizeXLarge = 32.0;
  
  /// Avatar sizes
  static const double avatarSizeSmall = 24.0;
  static const double avatarSizeMedium = 32.0;
  static const double avatarSizeLarge = 48.0;
  static const double avatarSizeXLarge = 64.0;
  
  // =============================================================================
  // UTILITY METHODS
  // =============================================================================
  
  /// Get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }
  
  /// Get glassmorphism color
  static Color getGlassColor(Color baseColor, double opacity) {
    return baseColor.withValues(alpha: opacity);
  }
  
  /// Get semantic color by type
  static Color getSemanticColor(SemanticColorType type) {
    switch (type) {
      case SemanticColorType.success:
        return semanticSuccess;
      case SemanticColorType.warning:
        return semanticWarning;
      case SemanticColorType.error:
        return semanticError;
      case SemanticColorType.info:
        return semanticInfo;
    }
  }
  
  /// Get text color based on background
  static Color getContrastTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? textPrimary : textInverse;
  }
  
  /// Validate color contrast ratio
  static bool hasValidContrast(Color foreground, Color background) {
    final foregroundLuminance = foreground.computeLuminance();
    final backgroundLuminance = background.computeLuminance();
    
    final lighter = foregroundLuminance > backgroundLuminance 
        ? foregroundLuminance 
        : backgroundLuminance;
    final darker = foregroundLuminance > backgroundLuminance 
        ? backgroundLuminance 
        : foregroundLuminance;
    
    final contrastRatio = (lighter + 0.05) / (darker + 0.05);
    return contrastRatio >= 4.5; // WCAG AA standard
  }
}

/// Semantic color types for consistent usage
enum SemanticColorType {
  success,
  warning,
  error,
  info,
}

/// Text style definitions using design tokens
class DesignTextStyles {
  DesignTextStyles._();
  
  /// Display styles
  static const TextStyle displayLarge = TextStyle(
    fontSize: DesignTokens.fontSizeDisplayLarge,
    fontWeight: DesignTokens.fontWeightBold,
    color: DesignTokens.textPrimary,
    height: DesignTokens.lineHeightTight,
    letterSpacing: DesignTokens.letterSpacingTight,
  );
  
  static const TextStyle display = TextStyle(
    fontSize: DesignTokens.fontSizeDisplay,
    fontWeight: DesignTokens.fontWeightBold,
    color: DesignTokens.textPrimary,
    height: DesignTokens.lineHeightTight,
    letterSpacing: DesignTokens.letterSpacingTight,
  );
  
  /// Title styles
  static const TextStyle titleLarge = TextStyle(
    fontSize: DesignTokens.fontSizeTitleLarge,
    fontWeight: DesignTokens.fontWeightSemiBold,
    color: DesignTokens.textPrimary,
    height: DesignTokens.lineHeightNormal,
  );
  
  static const TextStyle title = TextStyle(
    fontSize: DesignTokens.fontSizeTitle,
    fontWeight: DesignTokens.fontWeightSemiBold,
    color: DesignTokens.textPrimary,
    height: DesignTokens.lineHeightNormal,
  );
  
  static const TextStyle subtitle = TextStyle(
    fontSize: DesignTokens.fontSizeSubtitle,
    fontWeight: DesignTokens.fontWeightMedium,
    color: DesignTokens.textPrimary,
    height: DesignTokens.lineHeightNormal,
  );
  
  /// Body styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: DesignTokens.fontSizeBodyLarge,
    fontWeight: DesignTokens.fontWeightRegular,
    color: DesignTokens.textPrimary,
    height: DesignTokens.lineHeightNormal,
  );
  
  static const TextStyle body = TextStyle(
    fontSize: DesignTokens.fontSizeBody,
    fontWeight: DesignTokens.fontWeightRegular,
    color: DesignTokens.textPrimary,
    height: DesignTokens.lineHeightNormal,
  );
  
  static const TextStyle bodySecondary = TextStyle(
    fontSize: DesignTokens.fontSizeBody,
    fontWeight: DesignTokens.fontWeightRegular,
    color: DesignTokens.textSecondary,
    height: DesignTokens.lineHeightNormal,
  );
  
  /// Caption and small text
  static const TextStyle caption = TextStyle(
    fontSize: DesignTokens.fontSizeCaption,
    fontWeight: DesignTokens.fontWeightRegular,
    color: DesignTokens.textSecondary,
    height: DesignTokens.lineHeightNormal,
  );
  
  static const TextStyle captionStrong = TextStyle(
    fontSize: DesignTokens.fontSizeCaption,
    fontWeight: DesignTokens.fontWeightMedium,
    color: DesignTokens.textPrimary,
    height: DesignTokens.lineHeightNormal,
  );
  
  /// Accent styles
  static const TextStyle accent = TextStyle(
    fontSize: DesignTokens.fontSizeBody,
    fontWeight: DesignTokens.fontWeightMedium,
    color: DesignTokens.textAccent,
    height: DesignTokens.lineHeightNormal,
  );
  
  static const TextStyle accentLarge = TextStyle(
    fontSize: DesignTokens.fontSizeBodyLarge,
    fontWeight: DesignTokens.fontWeightSemiBold,
    color: DesignTokens.textAccent,
    height: DesignTokens.lineHeightNormal,
  );
  
  /// Monospace styles
  static const TextStyle code = TextStyle(
    fontSize: DesignTokens.fontSizeBody,
    fontWeight: DesignTokens.fontWeightRegular,
    color: DesignTokens.textPrimary,
    fontFamily: DesignTokens.fontFamilyMonospace,
    height: DesignTokens.lineHeightNormal,
  );
  
  static const TextStyle codeSmall = TextStyle(
    fontSize: DesignTokens.fontSizeCaption,
    fontWeight: DesignTokens.fontWeightRegular,
    color: DesignTokens.textSecondary,
    fontFamily: DesignTokens.fontFamilyMonospace,
    height: DesignTokens.lineHeightNormal,
  );
}