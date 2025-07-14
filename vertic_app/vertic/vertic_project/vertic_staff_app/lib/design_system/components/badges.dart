import 'package:flutter/material.dart';
import '../theme_extensions.dart';
import '../foundations/colors.dart';
import '../foundations/typography.dart';
import '../foundations/spacing.dart';

/// **🏅 VERTIC BADGE COMPONENT**
/// 
/// Kleine Indikatoren für Benachrichtigungen, Status oder Zähler.
/// 
/// **Varianten:**
/// - `VerticBadgeVariant.filled` - Gefüllter Badge (Standard)
/// - `VerticBadgeVariant.outlined` - Umrandeter Badge
/// - `VerticBadgeVariant.dot` - Punkt-Badge ohne Text
/// 
/// **Größen:**
/// - `VerticBadgeSize.small` - Kompakte Größe
/// - `VerticBadgeSize.medium` - Standard Größe
/// - `VerticBadgeSize.large` - Große Größe
/// 
/// **Verwendung:**
/// ```dart
/// VerticBadge(
///   count: 5,
///   child: Icon(Icons.notifications),
/// )
/// ```

enum VerticBadgeVariant {
  filled,
  outlined,
  dot,
}

enum VerticBadgeSize {
  small,
  medium,
  large,
}

enum VerticBadgeColor {
  primary,
  secondary,
  error,
  warning,
  success,
  info,
}

/// **🛠️ BADGE UTILITIES**
/// 
/// Gemeinsame Helper-Methoden für alle Badge-Komponenten
/// um Code-Duplizierung zu vermeiden
class VerticBadgeUtils {
  static Color getBadgeColor(VerticBadgeColor color, AppColorsTheme colors) {
    switch (color) {
      case VerticBadgeColor.primary:
        return colors.primary;
      case VerticBadgeColor.secondary:
        return colors.secondary;
      case VerticBadgeColor.error:
        return colors.error;
      case VerticBadgeColor.warning:
        return colors.warning;
      case VerticBadgeColor.success:
        return colors.success;
      case VerticBadgeColor.info:
        return colors.info;
    }
  }

  static Color getTextColor(VerticBadgeColor color, AppColorsTheme colors) {
    switch (color) {
      case VerticBadgeColor.primary:
        return colors.onPrimary;
      case VerticBadgeColor.secondary:
        return colors.onSecondary;
      case VerticBadgeColor.error:
        return colors.onError;
      case VerticBadgeColor.warning:
        return colors.onWarning;
      case VerticBadgeColor.success:
        return colors.onSuccess;
      case VerticBadgeColor.info:
        return colors.onInfo;
    }
  }

  static TextStyle getTextStyle(VerticBadgeSize size, AppTypographyTheme typography) {
    switch (size) {
      case VerticBadgeSize.small:
        return typography.labelSmall;
      case VerticBadgeSize.medium:
        return typography.labelMedium;
      case VerticBadgeSize.large:
        return typography.labelLarge;
    }
  }
}

class VerticBadge extends StatelessWidget {
  final Widget child;
  final int? count;
  final String? label;
  final VerticBadgeVariant variant;
  final VerticBadgeSize size;
  final VerticBadgeColor color;
  final bool showZero;
  final int? maxCount;

  const VerticBadge({
    super.key,
    required this.child,
    this.count,
    this.label,
    this.variant = VerticBadgeVariant.filled,
    this.size = VerticBadgeSize.medium,
    this.color = VerticBadgeColor.error,
    this.showZero = false,
    this.maxCount = 99,
  });

  const VerticBadge.dot({
    super.key,
    required this.child,
    this.color = VerticBadgeColor.error,
    this.size = VerticBadgeSize.small,
  }) : count = null,
       label = null,
       variant = VerticBadgeVariant.dot,
       showZero = false,
       maxCount = null;

  @override
  Widget build(BuildContext context) {
    final shouldShow = _shouldShowBadge();
    
    if (!shouldShow) {
      return child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -4,
          top: -4,
          child: _buildBadge(context),
        ),
      ],
    );
  }

  bool _shouldShowBadge() {
    if (variant == VerticBadgeVariant.dot) return true;
    if (label != null && label!.isNotEmpty) return true;
    if (count != null && (count! > 0 || showZero)) return true;
    return false;
  }

  Widget _buildBadge(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;

    final badgeColor = _getBadgeColor(colors);
    final textColor = _getTextColor(colors);
    final badgeSize = _getBadgeSize(spacing);
    final textStyle = _getTextStyle(typography);

    if (variant == VerticBadgeVariant.dot) {
      return Container(
        width: badgeSize.width,
        height: badgeSize.height,
        decoration: BoxDecoration(
          color: badgeColor,
          shape: BoxShape.circle,
          border: variant == VerticBadgeVariant.dot
              ? Border.all(color: textColor, width: 1)
              : null,
        ),
      );
    }

    final displayText = _getDisplayText();
    
    return Container(
      constraints: BoxConstraints(
        minWidth: badgeSize.width,
        minHeight: badgeSize.height,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: spacing.xs,
        vertical: spacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: variant == VerticBadgeVariant.outlined 
            ? Colors.transparent 
            : badgeColor,
        borderRadius: BorderRadius.circular(badgeSize.height / 2),
        border: variant == VerticBadgeVariant.outlined
            ? Border.all(color: badgeColor, width: 1)
            : null,
      ),
      child: Text(
        displayText,
        style: textStyle.copyWith(
          color: variant == VerticBadgeVariant.outlined 
              ? badgeColor 
              : textColor,
          height: 1.0,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _getDisplayText() {
    if (label != null) return label!;
    if (count != null) {
      if (maxCount != null && count! > maxCount!) {
        return '$maxCount+';
      }
      return count.toString();
    }
    return '';
  }

  Size _getBadgeSize(AppSpacingTheme spacing) {
    switch (size) {
      case VerticBadgeSize.small:
        return const Size(16, 16);
      case VerticBadgeSize.medium:
        return const Size(20, 20);
      case VerticBadgeSize.large:
        return const Size(24, 24);
    }
  }

  TextStyle _getTextStyle(AppTypographyTheme typography) {
    // Spezielle Logik für VerticBadge: kleine und mittlere Badges verwenden labelSmall
    switch (size) {
      case VerticBadgeSize.small:
        return typography.labelSmall;
      case VerticBadgeSize.medium:
        return typography.labelSmall;
      case VerticBadgeSize.large:
        return typography.labelMedium;
    }
  }

  Color _getBadgeColor(AppColorsTheme colors) {
    return VerticBadgeUtils.getBadgeColor(color, colors);
  }

  Color _getTextColor(AppColorsTheme colors) {
    return VerticBadgeUtils.getTextColor(color, colors);
  }
}

/// **🏅 VERTIC STATUS BADGE**
/// 
/// Spezialisierter Badge für Status-Anzeigen
class VerticStatusBadge extends StatelessWidget {
  final String label;
  final VerticBadgeColor color;
  final VerticBadgeSize size;
  final VerticBadgeVariant variant;

  const VerticStatusBadge({
    super.key,
    required this.label,
    this.color = VerticBadgeColor.primary,
    this.size = VerticBadgeSize.medium,
    this.variant = VerticBadgeVariant.filled,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;

    final badgeColor = _getBadgeColor(colors);
    final textColor = _getTextColor(colors);
    final textStyle = _getTextStyle(typography);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.sm,
        vertical: spacing.xs,
      ),
      decoration: BoxDecoration(
        color: variant == VerticBadgeVariant.outlined 
            ? Colors.transparent 
            : badgeColor,
        borderRadius: BorderRadius.circular(spacing.radiusSm),
        border: variant == VerticBadgeVariant.outlined
            ? Border.all(color: badgeColor, width: 1)
            : null,
      ),
      child: Text(
        label,
        style: textStyle.copyWith(
          color: variant == VerticBadgeVariant.outlined 
              ? badgeColor 
              : textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  TextStyle _getTextStyle(AppTypographyTheme typography) {
    return VerticBadgeUtils.getTextStyle(size, typography);
  }

  Color _getBadgeColor(AppColorsTheme colors) {
    return VerticBadgeUtils.getBadgeColor(color, colors);
  }

  Color _getTextColor(AppColorsTheme colors) {
    return VerticBadgeUtils.getTextColor(color, colors);
  }
} 