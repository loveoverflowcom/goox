import 'package:flutter/material.dart';
import 'package:goox/features/file_explorer/data/validators/file_name_validator.dart';
import 'package:goox_ui/goox_ui.dart';

/// Dialog for renaming a file or folder.
///
/// Provides:
/// - TextField pre-filled with current name
/// - Real-time validation
/// - Cancel and Rename buttons
/// - Error message display
final class RenameDialog extends StatefulWidget {
  /// Creates a rename dialog.
  const RenameDialog({
    required this.currentName,
    required this.nodePath,
    super.key,
  });

  /// The current name of the file or folder.
  final String currentName;

  /// The full path of the node being renamed.
  final String nodePath;

  @override
  State<RenameDialog> createState() => _RenameDialogState();
}

final class _RenameDialogState extends State<RenameDialog> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Pre-fill with current name
    _controller = TextEditingController(text: widget.currentName);
    
    // Select all text for easy replacement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _validateInput(String value) {
    setState(() {
      final result = FileNameValidator.validate(value);
      result.fold(
        (failure) => _errorMessage = failure.message,
        (_) => _errorMessage = null,
      );
    });
  }

  void _handleRename() {
    final newName = _controller.text;
    
    // Don't allow renaming to the same name
    if (newName == widget.currentName) {
      Navigator.of(context).pop();
      return;
    }
    
    final result = FileNameValidator.validate(newName);
    
    result.fold(
      (failure) {
        setState(() {
          _errorMessage = failure.message;
        });
      },
      (validName) {
        Navigator.of(context).pop(validName);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final editorTheme = Theme.of(context).extension<EditorThemeExtension>()!;
    
    return AlertDialog(
      backgroundColor: editorTheme.sidebarBackground,
      title: Text(
        'Rename',
        style: TextStyle(
          color: editorTheme.textColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Path: ${widget.nodePath}',
              style: TextStyle(
                color: editorTheme.textColorDimmed,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _validateInput,
              onSubmitted: (_) => _handleRename(),
              style: TextStyle(
                color: editorTheme.textColor,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Enter new name',
                hintStyle: TextStyle(
                  color: editorTheme.textColorDimmed,
                ),
                filled: true,
                fillColor: editorTheme.editorBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  borderSide: BorderSide(
                    color: editorTheme.borderColor,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  borderSide: BorderSide(
                    color: editorTheme.borderColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  borderSide: BorderSide(
                    color: editorTheme.selectedItemColor,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  borderSide: const BorderSide(
                    color: Colors.red,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: editorTheme.textColorDimmed,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _errorMessage == null && _controller.text.isNotEmpty
              ? _handleRename
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: editorTheme.statusBarBackground,
            foregroundColor: Colors.white,
            disabledBackgroundColor: editorTheme.textColorDimmed.withValues(alpha: 0.3),
            disabledForegroundColor: editorTheme.textColorDimmed,
          ),
          child: const Text('Rename'),
        ),
      ],
    );
  }
}
