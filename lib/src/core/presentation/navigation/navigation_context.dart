import 'package:fluent_ui/fluent_ui.dart';

/// Defines the main navigation contexts in the application
enum NavigationContext {
  dashboard('Dashboard', FluentIcons.view_dashboard, '/dashboard'),
  clients('Clients', FluentIcons.people, '/clients'),
  templates('Templates', FluentIcons.page, '/templates'),
  campaigns('Campaigns', FluentIcons.send, '/campaigns'),
  analytics('Analytics', FluentIcons.chart_template, '/analytics'),
  importExport('Import/Export', FluentIcons.sync, '/import-export'),
  tags('Tags', FluentIcons.tag, '/tags'),
  settings('Settings', FluentIcons.settings, '/settings');

  const NavigationContext(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;

  /// Get context from route path
  static NavigationContext fromRoute(String route) {
    for (final context in NavigationContext.values) {
      if (route.startsWith(context.route)) {
        return context;
      }
    }
    return NavigationContext.dashboard;
  }

  /// Get display color for context
  Color getContextColor() {
    switch (this) {
      case NavigationContext.dashboard:
        return const Color(0xFF6366F1); // Indigo
      case NavigationContext.clients:
        return const Color(0xFF10B981); // Emerald
      case NavigationContext.templates:
        return const Color(0xFFF59E0B); // Amber
      case NavigationContext.campaigns:
        return const Color(0xFF3B82F6); // Blue
      case NavigationContext.analytics:
        return const Color(0xFF8B5CF6); // Violet
      case NavigationContext.importExport:
        return const Color(0xFF06B6D4); // Cyan
      case NavigationContext.tags:
        return const Color(0xFFEC4899); // Pink
      case NavigationContext.settings:
        return const Color(0xFF6B7280); // Gray
    }
  }
}

/// Represents a breadcrumb item in the navigation
class NavigationBreadcrumb {
  final String label;
  final String? route;
  final IconData? icon;
  final bool isActive;

  const NavigationBreadcrumb({
    required this.label,
    this.route,
    this.icon,
    this.isActive = false,
  });

  NavigationBreadcrumb copyWith({
    String? label,
    String? route,
    IconData? icon,
    bool? isActive,
  }) {
    return NavigationBreadcrumb(
      label: label ?? this.label,
      route: route ?? this.route,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Navigation state for the adaptive toolbar
class NavigationState {
  final NavigationContext currentContext;
  final List<NavigationBreadcrumb> breadcrumbs;
  final List<NavigationContext> recentContexts;
  final List<NavigationContext> pinnedContexts;
  final String currentRoute;

  const NavigationState({
    required this.currentContext,
    this.breadcrumbs = const [],
    this.recentContexts = const [],
    this.pinnedContexts = const [],
    required this.currentRoute,
  });

  NavigationState copyWith({
    NavigationContext? currentContext,
    List<NavigationBreadcrumb>? breadcrumbs,
    List<NavigationContext>? recentContexts,
    List<NavigationContext>? pinnedContexts,
    String? currentRoute,
  }) {
    return NavigationState(
      currentContext: currentContext ?? this.currentContext,
      breadcrumbs: breadcrumbs ?? this.breadcrumbs,
      recentContexts: recentContexts ?? this.recentContexts,
      pinnedContexts: pinnedContexts ?? this.pinnedContexts,
      currentRoute: currentRoute ?? this.currentRoute,
    );
  }
}