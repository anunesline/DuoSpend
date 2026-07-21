import 'package:flutter/material.dart';

class WalletViewSwitcher extends StatelessWidget {
  final bool isSharedSelected;
  final bool sharedEnabled;
  final ValueChanged<bool> onChanged;

  const WalletViewSwitcher({
    super.key,
    required this.isSharedSelected,
    required this.sharedEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / 2;

          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: isSharedSelected
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    width: itemWidth - 8,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _WalletTab(
                      icon: Icons.person_rounded,
                      label: 'Eu',
                      selected: !isSharedSelected,
                      enabled: true,
                      onTap: () => onChanged(false),
                    ),
                  ),
                  Expanded(
                    child: _WalletTab(
                      icon: Icons.groups_rounded,
                      label: 'Nós',
                      selected: isSharedSelected,
                      enabled: sharedEnabled,
                      onTap: sharedEnabled
                          ? () => onChanged(true)
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WalletTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  const _WalletTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final foregroundColor = !enabled
        ? colorScheme.onSurface.withValues(alpha: .35)
        : selected
            ? colorScheme.onPrimary
            : colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: enabled ? 1 : .45,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                color: foregroundColor,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 15,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: foregroundColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}