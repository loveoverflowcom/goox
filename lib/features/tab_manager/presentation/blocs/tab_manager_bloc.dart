import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goox/features/tab_manager/data/models/editor_tab.dart';
import 'package:goox/features/tab_manager/presentation/blocs/tab_manager_event.dart';
import 'package:goox/features/tab_manager/presentation/blocs/tab_manager_state.dart';
import 'package:uuid/uuid.dart';

final class TabManagerBloc extends Bloc<TabManagerEvent, TabManagerState> {
  TabManagerBloc() : super(const TabManagerState()) {
    on<OpenTabEvent>(_onOpenTab);
    on<CloseTabEvent>(_onCloseTab);
    on<ActivateTabEvent>(_onActivateTab);
    on<UpdateTabModifiedEvent>(_onUpdateTabModified);
    on<NextTabEvent>(_onNextTab);
    on<PreviousTabEvent>(_onPreviousTab);
  }

  void _onOpenTab(OpenTabEvent event, Emitter<TabManagerState> emit) {
    // Check if tab already exists
    final existingTab = state.tabs.where((tab) => tab.filePath == event.filePath).firstOrNull;
    
    if (existingTab != null) {
      // Activate existing tab
      emit(state.copyWith(activeTabId: existingTab.id));
      return;
    }

    // Create new tab
    final newTab = EditorTab(
      id: const Uuid().v4(),
      filePath: event.filePath,
      fileName: event.fileName,
      openedAt: DateTime.now(),
    );

    final updatedTabs = List<EditorTab>.from(state.tabs)..add(newTab);
    
    emit(state.copyWith(
      tabs: updatedTabs,
      activeTabId: newTab.id,
      status: .loaded,
    ));
  }

  void _onCloseTab(CloseTabEvent event, Emitter<TabManagerState> emit) {
    final tabIndex = state.tabs.indexWhere((tab) => tab.id == event.tabId);
    
    if (tabIndex == -1) return;

    final updatedTabs = List<EditorTab>.from(state.tabs)..removeAt(tabIndex);
    
    String? newActiveTabId;
    
    if (updatedTabs.isNotEmpty && state.activeTabId == event.tabId) {
      // Determine next active tab
      if (tabIndex < updatedTabs.length) {
        newActiveTabId = updatedTabs[tabIndex].id;
      } else {
        newActiveTabId = updatedTabs.last.id;
      }
    } else if (state.activeTabId != event.tabId) {
      newActiveTabId = state.activeTabId;
    }

    emit(state.copyWith(
      tabs: updatedTabs,
      activeTabId: newActiveTabId,
    ));
  }

  void _onActivateTab(ActivateTabEvent event, Emitter<TabManagerState> emit) {
    emit(state.copyWith(activeTabId: event.tabId));
  }

  void _onUpdateTabModified(UpdateTabModifiedEvent event, Emitter<TabManagerState> emit) {
    final updatedTabs = state.tabs.map((tab) {
      if (tab.id == event.tabId) {
        return tab.copyWith(isModified: event.isModified);
      }
      return tab;
    }).toList();

    emit(state.copyWith(tabs: updatedTabs));
  }

  void _onNextTab(NextTabEvent event, Emitter<TabManagerState> emit) {
    if (state.tabs.isEmpty || state.activeTabId == null) return;

    final currentIndex = state.tabs.indexWhere((tab) => tab.id == state.activeTabId);
    final nextIndex = (currentIndex + 1) % state.tabs.length;
    
    emit(state.copyWith(activeTabId: state.tabs[nextIndex].id));
  }

  void _onPreviousTab(PreviousTabEvent event, Emitter<TabManagerState> emit) {
    if (state.tabs.isEmpty || state.activeTabId == null) return;

    final currentIndex = state.tabs.indexWhere((tab) => tab.id == state.activeTabId);
    final previousIndex = (currentIndex - 1 + state.tabs.length) % state.tabs.length;
    
    emit(state.copyWith(activeTabId: state.tabs[previousIndex].id));
  }
}
