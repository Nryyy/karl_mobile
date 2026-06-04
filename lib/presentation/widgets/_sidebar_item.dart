import 'package:flutter/material.dart';

class SidebarItem extends StatelessWidget {
  const SidebarItem({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
    this.tooltip,
    this.showLabel = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;
  final String? tooltip;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: tooltip ?? label,
        child: FocusableActionDetector(
          mouseCursor: SystemMouseCursors.click,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? colors.primary.withOpacity(0.12) : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    icon,
                    color: selected ? colors.primary : colors.onSurface,
                  ),
                  if (showLabel) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: selected ? colors.primary : colors.onSurface,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
