import 'package:flutter/material.dart';
import 'package:goox_ui/goox_ui.dart';

/// Alignment for navigation rail destinations.
enum GooxTabAlignment {
  /// Align to the top of the rail.
  top,

  /// Align to the bottom of the rail.
  bottom,
}

/// A destination tab in the navigation rail.
final class GooxDestinationTab {
  /// Creates a destination tab.
  const GooxDestinationTab({
    required this.id,
    required this.title,
    required this.icon,
    required this.builder,
    this.trailing,
    this.alignment = GooxTabAlignment.top,
  });

  /// Unique identifier for this tab.
  final String id;

  /// Title displayed in tooltip.
  final String title;

  /// Icon for the tab.
  final IconData icon;

  /// Builder for the tab content.
  final WidgetBuilder builder;

  /// Optional trailing widget (e.g., badge, action button).
  final WidgetBuilder? trailing;

  /// Alignment of the tab in the rail.
  final GooxTabAlignment alignment;
}

/// A navigation rail for the Goox editor.
final class GooxNavigationRail extends StatefulWidget {
  /// Creates a navigation rail.
  const GooxNavigationRail({
    required this.destinations,
    this.initialSelectedId,
    super.key,
  });

  /// List of destination tabs.
  final List<GooxDestinationTab> destinations;

  /// Initially selected tab ID.
  final String? initialSelectedId;

  @override
  State<GooxNavigationRail> createState() => _GooxNavigationRailState();
}

final class _GooxNavigationRailState extends State<GooxNavigationRail> {
  late String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialSelectedId ?? widget.destinations.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final topDestinations = widget.destinations
        .where((d) => d.alignment == GooxTabAlignment.top)
        .toList();
    final bottomDestinations = widget.destinations
        .where((d) => d.alignment == GooxTabAlignment.bottom)
        .toList();

    final selectedDestination = widget.destinations
        .where((d) => d.id == _selectedId)
        .firstOrNull;

    return Row(
      children: [
        // Navigation rail
        Container(
          width: AppSpacing.activityBarWidth,
          decoration: const BoxDecoration(
            color: AppColors.activityBarBackground,
            border: Border(
              right: BorderSide(color: AppColors.borderColor),
            ),
          ),
          child: Column(
            children: [
              // Top aligned destinations
              for (final destination in topDestinations)
                _buildDestinationButton(destination),
              const Spacer(),
              // Bottom aligned destinations
              for (final destination in bottomDestinations)
                _buildDestinationButton(destination),
            ],
          ),
        ),
        // Content area
        if (selectedDestination != null)
          Expanded(
            child: selectedDestination.builder(context),
          ),
      ],
    );
  }

  Widget _buildDestinationButton(GooxDestinationTab destination) {
    final isSelected = _selectedId == destination.id;

    return Tooltip(
      message: destination.title,
      waitDuration: const Duration(milliseconds: 500),
      child: Stack(
        children: [
          // Selection indicator
          if (isSelected)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 2,
                color: AppColors.accentColor,
              ),
            ),
          // Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  // Toggle: if already selected, deselect
                  if (_selectedId == destination.id) {
                    _selectedId = null;
                  } else {
                    _selectedId = destination.id;
                  }
                });
              },
              child: Container(
                width: AppSpacing.activityBarWidth,
                height: AppSpacing.activityBarWidth,
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      destination.icon,
                      color: isSelected
                          ? AppColors.textColor
                          : AppColors.textColorDimmed,
                      size: AppSpacing.xlg,
                    ),
                    if (destination.trailing != null)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: destination.trailing!(context),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
