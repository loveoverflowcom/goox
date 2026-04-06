part of 'tab_manager_bloc.dart';

abstract class TabManagerEvent extends Equatable {
  const TabManagerEvent();

  @override
  List<Object?> get props => [];
}

final class OpenTabEvent extends TabManagerEvent {

  const OpenTabEvent({
    required this.filePath,
    required this.fileName,
  });
  final String filePath;
  final String fileName;

  @override
  List<Object?> get props => [filePath, fileName];
}

final class CloseTabEvent extends TabManagerEvent {

  const CloseTabEvent(this.tabId);
  final String tabId;

  @override
  List<Object?> get props => [tabId];
}

final class ActivateTabEvent extends TabManagerEvent {

  const ActivateTabEvent(this.tabId);
  final String tabId;

  @override
  List<Object?> get props => [tabId];
}

final class UpdateTabModifiedEvent extends TabManagerEvent {

  const UpdateTabModifiedEvent({
    required this.tabId,
    required this.isModified,
  });
  final String tabId;
  final bool isModified;

  @override
  List<Object?> get props => [tabId, isModified];
}

final class NextTabEvent extends TabManagerEvent {
  const NextTabEvent();
}

final class PreviousTabEvent extends TabManagerEvent {
  const PreviousTabEvent();
}
