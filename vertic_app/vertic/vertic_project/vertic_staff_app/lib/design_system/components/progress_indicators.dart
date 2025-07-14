import 'package:flutter/material.dart';
import '../theme_extensions.dart';
import '../foundations/typography.dart';
import '../foundations/spacing.dart';

/// **📊 VERTIC PROGRESS INDICATOR COMPONENT**
/// 
/// Verschiedene Arten von Fortschrittsanzeigen für Ladezustände und Prozesse.
/// 
/// **Varianten:**
/// - `VerticProgressType.linear` - Lineare Fortschrittsanzeige
/// - `VerticProgressType.circular` - Kreisförmige Fortschrittsanzeige
/// - `VerticProgressType.step` - Schritt-für-Schritt Fortschritt
/// 
/// **Verwendung:**
/// ```dart
/// VerticProgressIndicator.linear(
///   value: 0.6,
///   label: 'Uploading...',
/// )
/// ```

enum VerticProgressType {
  linear,
  circular,
  step,
}

enum VerticProgressSize {
  small,
  medium,
  large,
}

class VerticProgressIndicator extends StatelessWidget {
  final VerticProgressType type;
  final double? value; // 0.0 bis 1.0, null für indeterminate
  final String? label;
  final String? sublabel;
  final VerticProgressSize size;
  final Color? color;
  final Color? backgroundColor;
  final bool showPercentage;

  const VerticProgressIndicator({
    super.key,
    required this.type,
    this.value,
    this.label,
    this.sublabel,
    this.size = VerticProgressSize.medium,
    this.color,
    this.backgroundColor,
    this.showPercentage = false,
  });

  const VerticProgressIndicator.linear({
    super.key,
    this.value,
    this.label,
    this.sublabel,
    this.size = VerticProgressSize.medium,
    this.color,
    this.backgroundColor,
    this.showPercentage = false,
  }) : type = VerticProgressType.linear;

  const VerticProgressIndicator.circular({
    super.key,
    this.value,
    this.label,
    this.sublabel,
    this.size = VerticProgressSize.medium,
    this.color,
    this.backgroundColor,
    this.showPercentage = false,
  }) : type = VerticProgressType.circular;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;

    final progressColor = color ?? colors.primary;
    final bgColor = backgroundColor ?? colors.surfaceVariant;

    switch (type) {
      case VerticProgressType.linear:
        return _buildLinearProgress(context, progressColor, bgColor, spacing, typography);
      case VerticProgressType.circular:
        return _buildCircularProgress(context, progressColor, bgColor, spacing, typography);
      case VerticProgressType.step:
        return _buildStepProgress(context, progressColor, bgColor, spacing, typography);
    }
  }

  Widget _buildLinearProgress(
    BuildContext context,
    Color progressColor,
    Color bgColor,
    AppSpacingTheme spacing,
    AppTypographyTheme typography,
  ) {
    final height = _getLinearHeight();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label!,
                style: typography.labelMedium.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
              if (showPercentage && value != null)
                Text(
                  '${(value! * 100).round()}%',
                  style: typography.labelSmall.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          SizedBox(height: spacing.xs),
        ],
        Container(
          height: height,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ),
        if (sublabel != null) ...[
          SizedBox(height: spacing.xs),
          Text(
            sublabel!,
            style: typography.labelSmall.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCircularProgress(
    BuildContext context,
    Color progressColor,
    Color bgColor,
    AppSpacingTheme spacing,
    AppTypographyTheme typography,
  ) {
    final circularSize = _getCircularSize();
    final strokeWidth = _getStrokeWidth();
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: circularSize,
              height: circularSize,
              child: CircularProgressIndicator(
                value: value,
                backgroundColor: bgColor,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                strokeWidth: strokeWidth,
              ),
            ),
            if (showPercentage && value != null)
              Text(
                '${(value! * 100).round()}%',
                style: typography.labelMedium.copyWith(
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        if (label != null) ...[
          SizedBox(height: spacing.sm),
          Text(
            label!,
            style: typography.labelMedium.copyWith(
              color: context.colors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        if (sublabel != null) ...[
          SizedBox(height: spacing.xs),
          Text(
            sublabel!,
            style: typography.labelSmall.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildStepProgress(
    BuildContext context,
    Color progressColor,
    Color bgColor,
    AppSpacingTheme spacing,
    AppTypographyTheme typography,
  ) {
    // TODO: Implement full step progress indicator using a list of steps as input
    // This is currently a placeholder and needs proper implementation
    return Container(
      padding: spacing.cardPadding,
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(spacing.radiusMd),
      ),
      child: Text(
        'Step Progress - Implementation pending (see TODO)',
        style: typography.bodyMedium,
      ),
    );
  }

  double _getLinearHeight() {
    switch (size) {
      case VerticProgressSize.small:
        return 4.0;
      case VerticProgressSize.medium:
        return 6.0;
      case VerticProgressSize.large:
        return 8.0;
    }
  }

  double _getCircularSize() {
    switch (size) {
      case VerticProgressSize.small:
        return 32.0;
      case VerticProgressSize.medium:
        return 48.0;
      case VerticProgressSize.large:
        return 64.0;
    }
  }

  double _getStrokeWidth() {
    switch (size) {
      case VerticProgressSize.small:
        return 3.0;
      case VerticProgressSize.medium:
        return 4.0;
      case VerticProgressSize.large:
        return 5.0;
    }
  }
}

/// **📊 VERTIC LOADING INDICATOR**
/// 
/// Einfacher Ladeindikator für allgemeine Verwendung
class VerticLoadingIndicator extends StatelessWidget {
  final String? message;
  final VerticProgressSize size;
  final Color? color;

  const VerticLoadingIndicator({
    super.key,
    this.message,
    this.size = VerticProgressSize.medium,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        VerticProgressIndicator.circular(
          size: size,
          color: color,
        ),
        if (message != null) ...[
          SizedBox(height: spacing.md),
          Text(
            message!,
            style: typography.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// **📊 VERTIC SKELETON LOADER**
/// 
/// Skeleton-Loader für Content-Platzhalter
class VerticSkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const VerticSkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  const VerticSkeletonLoader.text({
    super.key,
    this.width = double.infinity,
    this.height = 16.0,
  }) : borderRadius = const BorderRadius.all(Radius.circular(4.0));

  const VerticSkeletonLoader.avatar({
    super.key,
    this.width = 40.0,
    this.height = 40.0,
  }) : borderRadius = const BorderRadius.all(Radius.circular(20.0));

  @override
  State<VerticSkeletonLoader> createState() => _VerticSkeletonLoaderState();
}

class _VerticSkeletonLoaderState extends State<VerticSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(spacing.radiusSm),
            gradient: LinearGradient(
              colors: [
                colors.surfaceVariant,
                colors.surfaceVariant.withValues(alpha: 0.5),
                colors.surfaceVariant,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              transform: GradientRotation(_animation.value * 0.5),
            ),
          ),
        );
      },
    );
  }
} 