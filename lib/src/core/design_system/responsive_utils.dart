import 'package:flutter/widgets.dart';
import 'design_tokens.dart';

/// Responsive utility class for handling different screen sizes
class ResponsiveUtils {
  ResponsiveUtils._();
  
  /// Check if screen is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < DesignTokens.breakpointMobile;
  }
  
  /// Check if screen is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= DesignTokens.breakpointMobile && 
           width < DesignTokens.breakpointDesktop;
  }
  
  /// Check if screen is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= DesignTokens.breakpointDesktop;
  }
  
  /// Check if screen is large desktop
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= DesignTokens.breakpointLargeDesktop;
  }
  
  /// Get responsive value based on screen size
  static T getResponsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    if (isLargeDesktop(context) && largeDesktop != null) {
      return largeDesktop;
    }
    if (isDesktop(context) && desktop != null) {
      return desktop;
    }
    if (isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }
  
  /// Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    return EdgeInsets.all(
      getResponsiveValue(
        context,
        mobile: DesignTokens.space4,
        tablet: DesignTokens.space5,
        desktop: DesignTokens.space6,
        largeDesktop: DesignTokens.space8,
      ),
    );
  }
  
  /// Get responsive margin
  static EdgeInsets getResponsiveMargin(BuildContext context) {
    return EdgeInsets.all(
      getResponsiveValue(
        context,
        mobile: DesignTokens.space3,
        tablet: DesignTokens.space4,
        desktop: DesignTokens.space5,
        largeDesktop: DesignTokens.space6,
      ),
    );
  }
  
  /// Get responsive font size
  static double getResponsiveFontSize(
    BuildContext context,
    double baseFontSize,
  ) {
    final scaleFactor = getResponsiveValue(
      context,
      mobile: 0.9,
      tablet: 1.0,
      desktop: 1.0,
      largeDesktop: 1.1,
    );
    return baseFontSize * scaleFactor;
  }
  
  /// Get responsive icon size
  static double getResponsiveIconSize(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: DesignTokens.iconSizeSmall,
      tablet: DesignTokens.iconSizeMedium,
      desktop: DesignTokens.iconSizeMedium,
      largeDesktop: DesignTokens.iconSizeLarge,
    );
  }
  
  /// Get responsive card width
  static double getResponsiveCardWidth(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: double.infinity,
      tablet: 300.0,
      desktop: 320.0,
      largeDesktop: 360.0,
    );
  }
  
  /// Get responsive grid columns
  static int getResponsiveGridColumns(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
      largeDesktop: 4,
    );
  }
  
  /// Get responsive sidebar width
  static double getResponsiveSidebarWidth(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: 280.0,
      tablet: 300.0,
      desktop: 320.0,
      largeDesktop: 340.0,
    );
  }
  
  /// Get responsive detail panel width
  static double getResponsiveDetailPanelWidth(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: double.infinity,
      tablet: 350.0,
      desktop: 400.0,
      largeDesktop: 450.0,
    );
  }
}

/// Responsive widget that rebuilds based on screen size changes
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ResponsiveInfo info) builder;
  
  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });
  
  @override
  Widget build(BuildContext context) {
    final info = ResponsiveInfo.fromContext(context);
    return builder(context, info);
  }
}

/// Information about current responsive state
class ResponsiveInfo {
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;
  final bool isLargeDesktop;
  final double screenWidth;
  final double screenHeight;
  
  const ResponsiveInfo({
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
    required this.isLargeDesktop,
    required this.screenWidth,
    required this.screenHeight,
  });
  
  factory ResponsiveInfo.fromContext(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return ResponsiveInfo(
      isMobile: ResponsiveUtils.isMobile(context),
      isTablet: ResponsiveUtils.isTablet(context),
      isDesktop: ResponsiveUtils.isDesktop(context),
      isLargeDesktop: ResponsiveUtils.isLargeDesktop(context),
      screenWidth: size.width,
      screenHeight: size.height,
    );
  }
  
  /// Get device type as string
  String get deviceType {
    if (isLargeDesktop) return 'largeDesktop';
    if (isDesktop) return 'desktop';
    if (isTablet) return 'tablet';
    return 'mobile';
  }
}