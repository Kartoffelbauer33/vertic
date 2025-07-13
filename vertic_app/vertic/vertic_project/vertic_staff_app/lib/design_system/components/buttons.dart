import 'package:flutter/material.dart';
import '../theme_extensions.dart';

/// **🔘 VERTIC DESIGN SYSTEM - BUTTONS**
/// 
/// Umfassende Button-Komponenten mit:
/// - Alle Button-Varianten (Primary, Secondary, Destructive, etc.)
/// - Icon-Unterstützung
/// - Loading-States
/// - Accessibility-Features
/// - Responsive Größen

// ═══════════════════════════════════════════════════════════════
// 🎯 BUTTON VARIANTS ENUM
// ═══════════════════════════════════════════════════════════════

enum VerticButtonVariant {
  primary,
  secondary,
  destructive,
  outline,
  ghost,
  link,
}

enum VerticButtonSize {
  small,
  medium,
  large,
}

// ═══════════════════════════════════════════════════════════════
// 🔘 PRIMARY BUTTON COMPONENT
// ═══════════════════════════════════════════════════════════════

class VerticButton extends StatefulWidget {
  final String? text;
  final Widget? child;
  final VoidCallback? onPressed;
  final VerticButtonVariant variant;
  final VerticButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isExpanded;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final String? tooltip;
  
  const VerticButton({
    super.key,
    this.text,
    this.child,
    this.onPressed,
    this.variant = VerticButtonVariant.primary,
    this.size = VerticButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isExpanded = false,
    this.padding,
    this.width,
    this.tooltip,
  }) : assert(text != null || child != null, 'Either text or child must be provided');
  
  @override
  State<VerticButton> createState() => _VerticButtonState();
}

class _VerticButtonState extends State<VerticButton> 
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _scaleAnimation = Tween<double>(
        begin: 1.0,
        end: 0.95,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: context.animations.easeOut,
      ));
      _isInitialized = true;
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }
  
  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }
  
  void _handleTapCancel() {
    _controller.reverse();
  }
  
  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle(context);
    final buttonChild = _buildButtonChild(context);
    
    Widget button = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: _buildButton(context, buttonStyle, buttonChild),
    );
    
    if (widget.isExpanded) {
      button = SizedBox(
        width: double.infinity,
        child: button,
      );
    } else if (widget.width != null) {
      button = SizedBox(
        width: widget.width,
        child: button,
      );
    }
    
    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }
    
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: button,
    );
  }
  
  Widget _buildButton(BuildContext context, ButtonStyle style, Widget child) {
    switch (widget.variant) {
      case VerticButtonVariant.primary:
        return ElevatedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: style,
          child: child,
        );
      case VerticButtonVariant.secondary:
      case VerticButtonVariant.outline:
        return OutlinedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: style,
          child: child,
        );
      case VerticButtonVariant.destructive:
        return ElevatedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: style,
          child: child,
        );
      case VerticButtonVariant.ghost:
      case VerticButtonVariant.link:
        return TextButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: style,
          child: child,
        );
    }
  }
  
  ButtonStyle _getButtonStyle(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    // final shadows = context.shadows;
    
    // Größen-spezifische Werte
    final double height;
    final EdgeInsetsGeometry padding;
    final TextStyle textStyle;
    
    switch (widget.size) {
      case VerticButtonSize.small:
        height = spacing.buttonHeightSmall;
        padding = widget.padding ?? EdgeInsets.symmetric(
          horizontal: spacing.md,
          vertical: spacing.xs,
        );
        textStyle = typography.labelMedium;
        break;
      case VerticButtonSize.medium:
        height = spacing.buttonHeight;
        padding = widget.padding ?? spacing.buttonPadding;
        textStyle = typography.buttonText;
        break;
      case VerticButtonSize.large:
        height = spacing.buttonHeightLarge;
        padding = widget.padding ?? EdgeInsets.symmetric(
          horizontal: spacing.xl,
          vertical: spacing.md,
        );
        textStyle = typography.labelLarge;
        break;
    }
    
    // Varianten-spezifische Styles
    switch (widget.variant) {
      case VerticButtonVariant.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          disabledBackgroundColor: colors.surfaceVariant,
          disabledForegroundColor: colors.onSurfaceVariant,
          textStyle: textStyle,
          padding: padding,
          minimumSize: Size(0, height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.radiusMd),
          ),
          elevation: 1,
          shadowColor: colors.shadow,
        );
        
      case VerticButtonVariant.secondary:
        return OutlinedButton.styleFrom(
          backgroundColor: colors.secondaryContainer,
          foregroundColor: colors.onSecondaryContainer,
          disabledBackgroundColor: colors.surfaceVariant,
          disabledForegroundColor: colors.onSurfaceVariant,
          textStyle: textStyle,
          padding: padding,
          minimumSize: Size(0, height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.radiusMd),
          ),
          side: BorderSide(color: colors.secondary),
        );
        
      case VerticButtonVariant.destructive:
        return ElevatedButton.styleFrom(
          backgroundColor: colors.error,
          foregroundColor: colors.onError,
          disabledBackgroundColor: colors.surfaceVariant,
          disabledForegroundColor: colors.onSurfaceVariant,
          textStyle: textStyle,
          padding: padding,
          minimumSize: Size(0, height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.radiusMd),
          ),
          elevation: 1,
          shadowColor: colors.shadow,
        );
        
      case VerticButtonVariant.outline:
        return OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: colors.primary,
          disabledForegroundColor: colors.onSurfaceVariant,
          textStyle: textStyle,
          padding: padding,
          minimumSize: Size(0, height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.radiusMd),
          ),
          side: BorderSide(color: colors.outline),
        );
        
      case VerticButtonVariant.ghost:
        return TextButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: colors.primary,
          disabledForegroundColor: colors.onSurfaceVariant,
          textStyle: textStyle,
          padding: padding,
          minimumSize: Size(0, height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.radiusMd),
          ),
        );
        
      case VerticButtonVariant.link:
        return TextButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: colors.primary,
          disabledForegroundColor: colors.onSurfaceVariant,
          textStyle: textStyle.copyWith(
            decoration: TextDecoration.underline,
          ),
          padding: padding,
          minimumSize: Size(0, height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.radiusSm),
          ),
        );
    }
  }
  
  Widget _buildButtonChild(BuildContext context) {
    final spacing = context.spacing;
    
    if (widget.isLoading) {
      return _buildLoadingChild(context);
    }
    
    final List<Widget> children = [];
    
    // Leading Icon
    if (widget.icon != null) {
      children.add(Icon(
        widget.icon,
        size: _getIconSize(context),
      ));
      if (widget.text != null || widget.child != null) {
        children.add(SizedBox(width: spacing.sm));
      }
    }
    
    // Content
    if (widget.text != null) {
      children.add(Text(widget.text!));
    } else if (widget.child != null) {
      children.add(widget.child!);
    }
    
    // Trailing Icon
    if (widget.trailingIcon != null) {
      if (widget.text != null || widget.child != null) {
        children.add(SizedBox(width: spacing.sm));
      }
      children.add(Icon(
        widget.trailingIcon,
        size: _getIconSize(context),
      ));
    }
    
    if (children.length == 1) {
      return children.first;
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }
  
  Widget _buildLoadingChild(BuildContext context) {
    final spacing = context.spacing;
    // final colors = context.colors;
    
    final indicatorSize = _getIconSize(context);
    final indicatorColor = _getLoadingIndicatorColor(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: indicatorSize,
          height: indicatorSize,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
          ),
        ),
        if (widget.text != null) ...[
          SizedBox(width: spacing.sm),
          Text(widget.text!),
        ],
      ],
    );
  }
  
  double _getIconSize(BuildContext context) {
    final spacing = context.spacing;
    switch (widget.size) {
      case VerticButtonSize.small:
        return spacing.iconSm;
      case VerticButtonSize.medium:
        return spacing.iconMd;
      case VerticButtonSize.large:
        return spacing.iconLg;
    }
  }
  
  Color _getLoadingIndicatorColor(BuildContext context) {
    final colors = context.colors;
    switch (widget.variant) {
      case VerticButtonVariant.primary:
      case VerticButtonVariant.destructive:
        return colors.onPrimary;
      case VerticButtonVariant.secondary:
        return colors.onSecondaryContainer;
      case VerticButtonVariant.outline:
      case VerticButtonVariant.ghost:
      case VerticButtonVariant.link:
        return colors.primary;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// 🎯 CONVENIENCE CONSTRUCTORS
// ═══════════════════════════════════════════════════════════════

class PrimaryButton extends VerticButton {
  const PrimaryButton({
    super.key,
    super.text,
    super.child,
    super.onPressed,
    super.size,
    super.icon,
    super.trailingIcon,
    super.isLoading,
    super.isExpanded,
    super.padding,
    super.width,
    super.tooltip,
  }) : super(variant: VerticButtonVariant.primary);
}

class SecondaryButton extends VerticButton {
  const SecondaryButton({
    super.key,
    super.text,
    super.child,
    super.onPressed,
    super.size,
    super.icon,
    super.trailingIcon,
    super.isLoading,
    super.isExpanded,
    super.padding,
    super.width,
    super.tooltip,
  }) : super(variant: VerticButtonVariant.secondary);
}

class DestructiveButton extends VerticButton {
  const DestructiveButton({
    super.key,
    super.text,
    super.child,
    super.onPressed,
    super.size,
    super.icon,
    super.trailingIcon,
    super.isLoading,
    super.isExpanded,
    super.padding,
    super.width,
    super.tooltip,
  }) : super(variant: VerticButtonVariant.destructive);
}

class VerticOutlineButton extends VerticButton {
  const VerticOutlineButton({
    super.key,
    super.text,
    super.child,
    super.onPressed,
    super.size,
    super.icon,
    super.trailingIcon,
    super.isLoading,
    super.isExpanded,
    super.padding,
    super.width,
    super.tooltip,
  }) : super(variant: VerticButtonVariant.outline);
}

class GhostButton extends VerticButton {
  const GhostButton({
    super.key,
    super.text,
    super.child,
    super.onPressed,
    super.size,
    super.icon,
    super.trailingIcon,
    super.isLoading,
    super.isExpanded,
    super.padding,
    super.width,
    super.tooltip,
  }) : super(variant: VerticButtonVariant.ghost);
}

class LinkButton extends VerticButton {
  const LinkButton({
    super.key,
    super.text,
    super.child,
    super.onPressed,
    super.size,
    super.icon,
    super.trailingIcon,
    super.isLoading,
    super.isExpanded,
    super.padding,
    super.width,
    super.tooltip,
  }) : super(variant: VerticButtonVariant.link);
}

// ═══════════════════════════════════════════════════════════════
// 🎯 ICON BUTTON COMPONENT
// ═══════════════════════════════════════════════════════════════

class VerticIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final VerticButtonVariant variant;
  final VerticButtonSize size;
  final bool isLoading;
  final String? tooltip;
  final Color? iconColor;
  
  const VerticIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.variant = VerticButtonVariant.ghost,
    this.size = VerticButtonSize.medium,
    this.isLoading = false,
    this.tooltip,
    this.iconColor,
  });
  
  @override
  State<VerticIconButton> createState() => _VerticIconButtonState();
}

class _VerticIconButtonState extends State<VerticIconButton> 
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _scaleAnimation = Tween<double>(
        begin: 1.0,
        end: 0.9,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: context.animations.easeOut,
      ));
      _isInitialized = true;
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final colors = context.colors;
    
    final double size;
    final double iconSize;
    
    switch (widget.size) {
      case VerticButtonSize.small:
        size = spacing.buttonHeightSmall;
        iconSize = spacing.iconSm;
        break;
      case VerticButtonSize.medium:
        size = spacing.buttonHeight;
        iconSize = spacing.iconMd;
        break;
      case VerticButtonSize.large:
        size = spacing.buttonHeightLarge;
        iconSize = spacing.iconLg;
        break;
    }
    
    Widget child = widget.isLoading
        ? SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.iconColor ?? colors.primary,
              ),
            ),
          )
        : Icon(
            widget.icon,
            size: iconSize,
            color: widget.iconColor,
          );
    
    Widget button = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: IconButton(
        onPressed: widget.isLoading ? null : widget.onPressed,
        icon: child,
        iconSize: iconSize,
        constraints: BoxConstraints(
          minWidth: size,
          minHeight: size,
        ),
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.radiusMd),
          ),
        ),
      ),
    );
    
    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }
    
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onPressed != null && !widget.isLoading) {
          _controller.forward();
        }
      },
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: button,
    );
  }
} 