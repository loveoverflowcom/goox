import 'package:flutter/material.dart';

class GooxStatusBar extends StatelessWidget {
  const GooxStatusBar({
    super.key,
    required this.revision,
    required this.line,
    required this.column,
  });

  final int revision;
  final int line;
  final int column;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: colorScheme.primary,
      child: Row(
        children: [
          Icon(Icons.sync_rounded, size: 12, color: colorScheme.onPrimary),
          const SizedBox(width: 4),
          Text(
            'rev:$revision',
            style: TextStyle(color: colorScheme.onPrimary, fontSize: 11),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.edit_location_alt_outlined,
            size: 12,
            color: colorScheme.onPrimary,
          ),
          const SizedBox(width: 4),
          Text(
            'Ln $line, Col $column',
            style: TextStyle(color: colorScheme.onPrimary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
