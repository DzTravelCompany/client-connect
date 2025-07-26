import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'navigation_context.dart';

/// Provider for the current navigation state
final navigationStateProvider = StateNotifierProvider<NavigationStateNotifier, NavigationState>((ref) {
  return NavigationStateNotifier();
});

class NavigationStateNotifier extends StateNotifier<NavigationState> {
  NavigationStateNotifier() : super(const NavigationState(
    currentContext: NavigationContext.dashboard,
    currentRoute: '/dashboard',
  ));

  /// Update navigation based on current route
  void updateFromRoute(String route) {
    final context = NavigationContext.fromRoute(route);
    final breadcrumbs = _generateBreadcrumbs(route, context);
    
    // Update recent contexts
    final updatedRecent = _updateRecentContexts(context);
    
    state = state.copyWith(
      currentContext: context,
      currentRoute: route,
      breadcrumbs: breadcrumbs,
      recentContexts: updatedRecent,
    );
  }

  /// Navigate to a specific context
  void navigateToContext(NavigationContext context) {
    final updatedRecent = _updateRecentContexts(context);
    
    state = state.copyWith(
      currentContext: context,
      currentRoute: context.route,
      recentContexts: updatedRecent,
      breadcrumbs: [
        NavigationBreadcrumb(
          label: context.label,
          route: context.route,
          icon: context.icon,
          isActive: true,
        ),
      ],
    );
  }

  /// Toggle pinned context
  void togglePinnedContext(NavigationContext context) {
    final currentPinned = List<NavigationContext>.from(state.pinnedContexts);
    
    if (currentPinned.contains(context)) {
      currentPinned.remove(context);
    } else {
      currentPinned.add(context);
    }
    
    state = state.copyWith(pinnedContexts: currentPinned);
  }

  /// Generate breadcrumbs based on route
  List<NavigationBreadcrumb> _generateBreadcrumbs(String route, NavigationContext context) {
    final breadcrumbs = <NavigationBreadcrumb>[];
    
    // Add main context
    breadcrumbs.add(NavigationBreadcrumb(
      label: context.label,
      route: context.route,
      icon: context.icon,
    ));
    
    // Add sub-routes based on path
    final segments = route.split('/').where((s) => s.isNotEmpty).toList();
    
    if (segments.length > 1) {
      for (int i = 1; i < segments.length; i++) {
        final segment = segments[i];
        final subRoute = '/${segments.sublist(0, i + 1).join('/')}';
        
        breadcrumbs.add(NavigationBreadcrumb(
          label: _formatSegmentLabel(segment),
          route: subRoute,
          isActive: i == segments.length - 1,
        ));
      }
    } else {
      // Mark the main context as active if it's the only breadcrumb
      breadcrumbs[0] = breadcrumbs[0].copyWith(isActive: true);
    }
    
    return breadcrumbs;
  }

  /// Update recent contexts list
  List<NavigationContext> _updateRecentContexts(NavigationContext newContext) {
    final recent = List<NavigationContext>.from(state.recentContexts);
    
    // Remove if already exists
    recent.remove(newContext);
    
    // Add to front
    recent.insert(0, newContext);
    
    // Keep only last 5
    if (recent.length > 5) {
      recent.removeRange(5, recent.length);
    }
    
    return recent;
  }

  /// Format route segment for display
  String _formatSegmentLabel(String segment) {
    switch (segment) {
      case 'add':
        return 'Add New';
      case 'edit':
        return 'Edit';
      case 'create':
        return 'Create';
      case 'analytics':
        return 'Analytics';
      case 'editor':
        return 'Editor';
      default:
        // Try to parse as ID
        if (int.tryParse(segment) != null) {
          return 'Details';
        }
        // Capitalize first letter
        return segment.substring(0, 1).toUpperCase() + segment.substring(1);
    }
  }
}

/// Provider for command palette state
final commandPaletteProvider = StateNotifierProvider<CommandPaletteNotifier, CommandPaletteState>((ref) {
  return CommandPaletteNotifier();
});

class CommandPaletteState {
  final bool isVisible;
  final String query;
  final List<CommandPaletteItem> filteredItems;

  const CommandPaletteState({
    this.isVisible = false,
    this.query = '',
    this.filteredItems = const [],
  });

  CommandPaletteState copyWith({
    bool? isVisible,
    String? query,
    List<CommandPaletteItem>? filteredItems,
  }) {
    return CommandPaletteState(
      isVisible: isVisible ?? this.isVisible,
      query: query ?? this.query,
      filteredItems: filteredItems ?? this.filteredItems,
    );
  }
}

class CommandPaletteItem {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onExecute;
  final List<String> keywords;

  const CommandPaletteItem({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onExecute,
    this.keywords = const [],
  });
}

class CommandPaletteNotifier extends StateNotifier<CommandPaletteState> {
  CommandPaletteNotifier() : super(const CommandPaletteState());

  final List<CommandPaletteItem> _allItems = [
    // Navigation commands
    CommandPaletteItem(
      title: 'Go to Dashboard',
      subtitle: 'Navigate to main dashboard',
      icon: FluentIcons.view_dashboard,
      onExecute: () {}, // Will be set by the UI
      keywords: ['dashboard', 'home', 'overview'],
    ),
    CommandPaletteItem(
      title: 'Go to Clients',
      subtitle: 'Manage client information',
      icon: FluentIcons.people,
      onExecute: () {},
      keywords: ['clients', 'customers', 'contacts'],
    ),
    CommandPaletteItem(
      title: 'Go to Templates',
      subtitle: 'Create and edit templates',
      icon: FluentIcons.page,
      onExecute: () {},
      keywords: ['templates', 'messages', 'content'],
    ),
    CommandPaletteItem(
      title: 'Go to Campaigns',
      subtitle: 'Manage marketing campaigns',
      icon: FluentIcons.send,
      onExecute: () {},
      keywords: ['campaigns', 'marketing', 'messages'],
    ),
    // Action commands
    CommandPaletteItem(
      title: 'Add New Client',
      subtitle: 'Create a new client record',
      icon: FluentIcons.add_friend,
      onExecute: () {},
      keywords: ['add', 'new', 'client', 'create'],
    ),
    CommandPaletteItem(
      title: 'Create Campaign',
      subtitle: 'Start a new marketing campaign',
      icon: FluentIcons.send,
      onExecute: () {},
      keywords: ['create', 'campaign', 'new', 'marketing'],
    ),
    CommandPaletteItem(
      title: 'New Template',
      subtitle: 'Create a new message template',
      icon: FluentIcons.page_add,
      onExecute: () {},
      keywords: ['template', 'new', 'create', 'message'],
    ),
  ];

  void show() {
    state = state.copyWith(
      isVisible: true,
      filteredItems: _allItems,
    );
  }

  void hide() {
    state = state.copyWith(
      isVisible: false,
      query: '',
      filteredItems: [],
    );
  }

  void updateQuery(String query) {
    final filtered = _filterItems(query);
    state = state.copyWith(
      query: query,
      filteredItems: filtered,
    );
  }

  List<CommandPaletteItem> _filterItems(String query) {
    if (query.isEmpty) return _allItems;

    final lowerQuery = query.toLowerCase();
    return _allItems.where((item) {
      return item.title.toLowerCase().contains(lowerQuery) ||
             (item.subtitle?.toLowerCase().contains(lowerQuery) ?? false) ||
             item.keywords.any((keyword) => keyword.toLowerCase().contains(lowerQuery));
    }).toList();
  }
}