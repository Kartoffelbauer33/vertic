import 'package:flutter/material.dart';
import '../theme_extensions.dart';
import '../foundations/colors.dart';
import '../foundations/typography.dart';
import '../foundations/spacing.dart';

/// **🏷️ VERTIC CHIP COMPONENT**
/// 
/// Kompakte, interaktive Elemente zur Darstellung von Informationen,
/// Attributen oder Aktionen.
/// 
/// **Varianten:**
/// - `VerticChipVariant.filled` - Gefüllter Chip (Standard)
/// - `VerticChipVariant.outlined` - Umrandeter Chip
/// - `VerticChipVariant.elevated` - Erhöhter Chip
/// 
/// **Größen:**
/// - `VerticChipSize.small` - Kompakte Größe
/// - `VerticChipSize.medium` - Standard Größe
/// - `VerticChipSize.large` - Große Größe
/// 
/// **Verwendung:**
/// ```dart
/// VerticChip(
///   label: 'Filter',
///   variant: VerticChipVariant.filled,
///   size: VerticChipSize.medium,
///   onPressed: () => print('Chip pressed'),
/// )
/// ```

enum VerticChipVariant {
  filled,
  outlined,
  elevated,
}

enum VerticChipSize {
  small,
  medium,
  large,
}

class VerticChip extends StatelessWidget {
  final String label;
  final VerticChipVariant variant;
  final VerticChipSize size;
  final IconData? icon;
  final VoidCallback? onPressed;
  final VoidCallback? onDeleted;
  final bool selected;
  final bool disabled;

  const VerticChip({
    super.key,
    required this.label,
    this.variant = VerticChipVariant.filled,
    this.size = VerticChipSize.medium,
    this.icon,
    this.onPressed,
    this.onDeleted,
    this.selected = false,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;

    final chipHeight = _getChipHeight(spacing);
    final chipPadding = _getChipPadding(spacing);
    final textStyle = _getTextStyle(typography);
    final iconSize = _getIconSize(spacing);

    return Material(
      color: _getBackgroundColor(colors),
      elevation: _getElevation(),
      borderRadius: BorderRadius.circular(chipHeight / 2),
      child: InkWell(
        onTap: disabled ? null : onPressed,
        borderRadius: BorderRadius.circular(chipHeight / 2),
        child: Container(
          height: chipHeight,
          padding: chipPadding,
          decoration: _getDecoration(colors, spacing),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: iconSize,
                  color: _getContentColor(colors),
                ),
                SizedBox(width: spacing.xs),
              ],
              Text(
                label,
                style: textStyle.copyWith(
                  color: _getContentColor(colors),
                ),
              ),
              if (onDeleted != null) ...[
                SizedBox(width: spacing.xs),
                GestureDetector(
                  onTap: disabled ? null : onDeleted,
                  child: Icon(
                    Icons.close,
                    size: iconSize,
                    color: _getContentColor(colors),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  double _getChipHeight(AppSpacingTheme spacing) {
    switch (size) {
      case VerticChipSize.small:
        return 24.0;
      case VerticChipSize.medium:
        return 32.0;
      case VerticChipSize.large:
        return 40.0;
    }
  }

  EdgeInsetsGeometry _getChipPadding(AppSpacingTheme spacing) {
    switch (size) {
      case VerticChipSize.small:
        return EdgeInsets.symmetric(horizontal: spacing.sm);
      case VerticChipSize.medium:
        return EdgeInsets.symmetric(horizontal: spacing.md);
      case VerticChipSize.large:
        return EdgeInsets.symmetric(horizontal: spacing.lg);
    }
  }

  TextStyle _getTextStyle(AppTypographyTheme typography) {
    switch (size) {
      case VerticChipSize.small:
        return typography.labelSmall;
      case VerticChipSize.medium:
        return typography.labelMedium;
      case VerticChipSize.large:
        return typography.labelLarge;
    }
  }

  double _getIconSize(AppSpacingTheme spacing) {
    switch (size) {
      case VerticChipSize.small:
        return spacing.iconSm;
      case VerticChipSize.medium:
        return spacing.iconMd;
      case VerticChipSize.large:
        return spacing.iconLg;
    }
  }

  Color _getBackgroundColor(AppColorsTheme colors) {
    if (disabled) {
      return colors.surfaceVariant.withValues(alpha: 0.5);
    }

    switch (variant) {
      case VerticChipVariant.filled:
        return selected ? colors.primaryContainer : colors.surfaceVariant;
      case VerticChipVariant.outlined:
        return selected ? colors.primaryContainer : Colors.transparent;
      case VerticChipVariant.elevated:
        return selected ? colors.primaryContainer : colors.surface;
    }
  }

  Color _getContentColor(AppColorsTheme colors) {
    if (disabled) {
      return colors.onSurfaceVariant.withValues(alpha: 0.5);
    }

    switch (variant) {
      case VerticChipVariant.filled:
        return selected ? colors.onPrimaryContainer : colors.onSurfaceVariant;
      case VerticChipVariant.outlined:
        return selected ? colors.onPrimaryContainer : colors.onSurfaceVariant;
      case VerticChipVariant.elevated:
        return selected ? colors.onPrimaryContainer : colors.onSurface;
    }
  }

  Decoration? _getDecoration(AppColorsTheme colors, AppSpacingTheme spacing) {
    if (variant == VerticChipVariant.outlined) {
      return BoxDecoration(
        border: Border.all(
          color: selected ? colors.primary : colors.outline,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(_getChipHeight(spacing) / 2),
      );
    }
    return null;
  }

  double _getElevation() {
    switch (variant) {
      case VerticChipVariant.filled:
      case VerticChipVariant.outlined:
        return 0.0;
      case VerticChipVariant.elevated:
        return 1.0;
    }
  }
}

/// **🏷️ VERTIC FILTER CHIP**
/// 
/// Spezialisierter Chip für Filter-Funktionalität
class VerticFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final IconData? icon;
  final VerticChipSize size;
  final bool disabled;

  const VerticFilterChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
    this.icon,
    this.size = VerticChipSize.medium,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return VerticChip(
      label: label,
      variant: VerticChipVariant.outlined,
      size: size,
      icon: icon,
      selected: selected,
      disabled: disabled,
      onPressed: disabled ? null : () => onSelected?.call(!selected),
    );
  }
}

/// **🏷️ VERTIC ACTION CHIP**
/// 
/// Spezialisierter Chip für Aktionen
class VerticActionChip extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final VerticChipSize size;
  final bool disabled;

  const VerticActionChip({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.size = VerticChipSize.medium,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return VerticChip(
      label: label,
      variant: VerticChipVariant.filled,
      size: size,
      icon: icon,
      disabled: disabled,
      onPressed: onPressed,
    );
  }
} 