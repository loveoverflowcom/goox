import 'package:equatable/equatable.dart';

enum FileNodeType { file, directory }

final class FileNode extends Equatable {

  const FileNode({
    required this.name,
    required this.path,
    required this.type,
    this.children = const [],
    this.isExpanded = false,
    this.lastModified,
    this.size,
  });
  final String name;
  final String path;
  final FileNodeType type;
  final List<FileNode> children;
  final bool isExpanded;
  final DateTime? lastModified;
  final int? size;

  FileNode copyWith({
    String? name,
    String? path,
    FileNodeType? type,
    List<FileNode>? children,
    bool? isExpanded,
    DateTime? lastModified,
    int? size,
  }) {
    return FileNode(
      name: name ?? this.name,
      path: path ?? this.path,
      type: type ?? this.type,
      children: children ?? this.children,
      isExpanded: isExpanded ?? this.isExpanded,
      lastModified: lastModified ?? this.lastModified,
      size: size ?? this.size,
    );
  }

  @override
  List<Object?> get props => [name, path, type, children, isExpanded, lastModified, size];
}
