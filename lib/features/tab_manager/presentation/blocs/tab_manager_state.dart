import 'package:equatable/equatable.dart';
import 'package:goox/features/tab_manager/data/models/editor_tab.dart';

enum TabManagerStatus { initial, loaded }

final class TabManagerState extends Equatable {

  const TabManagerState({
    this.tabs = const [],
    this.activeTabId,
    this.status = .initial,
  });
  final List<EditorTab> tabs;
  final String? activeTabId;
  final TabManagerStatus status;

  TabManagerState copyWith({
    List<EditorTab>? tabs,
    String? activeTabId,
    TabManagerStatus? status,
  }) {
    return TabManagerState(
      tabs: tabs ?? this.tabs,
      activeTabId: activeTabId ?? this.activeTabId,
      status: status ?? this.status,
    );
  }

  /// Gets the currently active tab.
  EditorTab? get activeTab {
    if (activeTabId == null) return null;
    return tabs.cast<EditorTab?>().firstWhere(
          (tab) => tab?.id == activeTabId,
          orElse: () => null,
        );
  }

  bool get hasOpenTabs => tabs.isNotEmpty;

  @override
  List<Object?> get props => [tabs, activeTabId, status];
}
