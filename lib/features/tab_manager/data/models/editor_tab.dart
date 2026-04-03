import 'package:equatable/equatable.dart';

final class EditorTab extends Equatable {

  const EditorTab({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.openedAt, this.isModified = false,
    this.isActive = false,
  });
  final String id;
  final String filePath;
  final String fileName;
  final bool isModified;
  final bool isActive;
  final DateTime openedAt;

  EditorTab copyWith({
    String? id,
    String? filePath,
    String? fileName,
    bool? isModified,
    bool? isActive,
    DateTime? openedAt,
  }) {
    return EditorTab(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      isModified: isModified ?? this.isModified,
      isActive: isActive ?? this.isActive,
      openedAt: openedAt ?? this.openedAt,
    );
  }

  @override
  List<Object?> get props => [id, filePath, fileName, isModified, isActive, openedAt];
}
