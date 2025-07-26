import 'package:flutter_riverpod/flutter_riverpod.dart';

// Sidebar state provider
final sidebarStateProvider = StateNotifierProvider<SidebarStateNotifier, SidebarState>((ref) {
  return SidebarStateNotifier();
});

class SidebarState {
  final bool isCollapsed;
  final bool isHovered;
  
  const SidebarState({
    this.isCollapsed = false,
    this.isHovered = false,
  });
  
  SidebarState copyWith({
    bool? isCollapsed,
    bool? isHovered,
  }) {
    return SidebarState(
      isCollapsed: isCollapsed ?? this.isCollapsed,
      isHovered: isHovered ?? this.isHovered,
    );
  }
}

class SidebarStateNotifier extends StateNotifier<SidebarState> {
  SidebarStateNotifier() : super(const SidebarState());
  
  void toggleCollapse() {
    state = state.copyWith(isCollapsed: !state.isCollapsed);
  }
  
  void setHovered(bool hovered) {
    state = state.copyWith(isHovered: hovered);
  }
}

// Detail panel state provider
final detailPanelStateProvider = StateNotifierProvider<DetailPanelStateNotifier, DetailPanelState>((ref) {
  return DetailPanelStateNotifier();
});

class DetailPanelState {
  final bool isVisible;
  final String? selectedItemId;
  final DetailPanelType type;
  
  const DetailPanelState({
    this.isVisible = false,
    this.selectedItemId,
    this.type = DetailPanelType.none,
  });
  
  DetailPanelState copyWith({
    bool? isVisible,
    String? selectedItemId,
    DetailPanelType? type,
  }) {
    return DetailPanelState(
      isVisible: isVisible ?? this.isVisible,
      selectedItemId: selectedItemId ?? this.selectedItemId,
      type: type ?? this.type,
    );
  }
}

enum DetailPanelType {
  none,
  client,
  campaign,
  template,
}

class DetailPanelStateNotifier extends StateNotifier<DetailPanelState> {
  DetailPanelStateNotifier() : super(const DetailPanelState());
  
  void showPanel(DetailPanelType type, String itemId) {
    state = state.copyWith(
      isVisible: true,
      type: type,
      selectedItemId: itemId,
    );
  }
  
  void hidePanel() {
    state = state.copyWith(
      isVisible: false,
      type: DetailPanelType.none,
      selectedItemId: null,
    );
  }
}

// Layout breakpoint provider
final layoutBreakpointProvider = Provider<LayoutBreakpoint>((ref) {
  // This would typically be updated based on screen size
  // For now, returning desktop as default
  return LayoutBreakpoint.desktop;
});

enum LayoutBreakpoint {
  mobile,
  tablet,
  desktop,
}