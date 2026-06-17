import 'package:flutter_riverpod/flutter_riverpod.dart';

class UIState {
  final String activeView;
  final bool sidebarCollapsed;
  final bool showSidebarOverlay;

  const UIState({
    this.activeView = 'dashboard',
    this.sidebarCollapsed = false,
    this.showSidebarOverlay = false,
  });

  UIState copyWith({String? activeView, bool? sidebarCollapsed, bool? showSidebarOverlay}) {
    return UIState(
      activeView: activeView ?? this.activeView,
      sidebarCollapsed: sidebarCollapsed ?? this.sidebarCollapsed,
      showSidebarOverlay: showSidebarOverlay ?? this.showSidebarOverlay,
    );
  }
}

class UINotifier extends Notifier<UIState> {
  @override
  UIState build() => const UIState();

  void setActiveView(String view) => state = state.copyWith(activeView: view);
  void toggleSidebar() => state = state.copyWith(sidebarCollapsed: !state.sidebarCollapsed);
  void toggleSidebarOverlay() => state = state.copyWith(showSidebarOverlay: !state.showSidebarOverlay);
}

final uiProvider = NotifierProvider<UINotifier, UIState>(UINotifier.new);
