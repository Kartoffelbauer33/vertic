import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme_extensions.dart';

/// **📝 VERTIC DESIGN SYSTEM - INPUTS**
/// 
/// Umfassende Input-Komponenten mit:
/// - Verschiedene Input-Typen (Text, Email, Password, etc.)
/// - Validation States
/// - Icon-Unterstützung
/// - Helper Text & Error Messages
/// - Accessibility-Features

// ═══════════════════════════════════════════════════════════════
// 🎯 INPUT VARIANTS ENUM
// ═══════════════════════════════════════════════════════════════

enum VerticInputType {
  text,
  email,
  password,
  phone,
  number,
  multiline,
  search,
}

enum VerticInputState {
  normal,
  error,
  success,
  warning,
  disabled,
}

// ═══════════════════════════════════════════════════════════════
// 📝 PRIMARY INPUT COMPONENT
// ═══════════════════════════════════════════════════════════════

class VerticInput extends StatefulWidget {
  final String? label;
  final String? placeholder;
  final String? helperText;
  final String? errorText;
  final String? successText;
  final String? warningText;
  final VerticInputType type;
  final VerticInputState state;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool required;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? tooltip;
  
  const VerticInput({
    super.key,
    this.label,
    this.placeholder,
    this.helperText,
    this.errorText,
    this.successText,
    this.warningText,
    this.type = VerticInputType.text,
    this.state = VerticInputState.normal,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.required = false,
    this.maxLines,
    this.maxLength,
    this.inputFormatters,
    this.textInputAction,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
    this.tooltip,
  });
  
  @override
  State<VerticInput> createState() => _VerticInputState();
}

class _VerticInputState extends State<VerticInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _obscureText = false;
  bool _hasFocus = false;
  
  @override
  void initState() {
    super.initState();
    
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _focusNode = widget.focusNode ?? FocusNode();
    _obscureText = widget.type == VerticInputType.password;
    
    _focusNode.addListener(_onFocusChanged);
  }
  
  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }
  
  void _onFocusChanged() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;
    
    Widget input = TextField(
      controller: _controller,
      focusNode: _focusNode,
      onChanged: widget.onChanged,
      onTap: widget.onTap,
      onSubmitted: widget.onSubmitted,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      obscureText: _obscureText,
      maxLines: _getMaxLines(),
      maxLength: widget.maxLength,
      inputFormatters: _getInputFormatters(),
      keyboardType: _getKeyboardType(),
      textInputAction: widget.textInputAction,
      enabled: widget.state != VerticInputState.disabled,
      style: typography.bodyMedium,
      decoration: _buildInputDecoration(context),
    );
    
    if (widget.tooltip != null) {
      input = Tooltip(
        message: widget.tooltip!,
        child: input,
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          _buildLabel(context),
          SizedBox(height: spacing.xs),
        ],
        input,
        if (_getStatusText() != null) ...[
          SizedBox(height: spacing.xs),
          _buildStatusText(context),
        ],
      ],
    );
  }
  
  Widget _buildLabel(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    
    return RichText(
      text: TextSpan(
        style: typography.labelMedium.copyWith(
          color: colors.onSurfaceVariant,
        ),
        children: [
          TextSpan(text: widget.label!),
          if (widget.required)
            TextSpan(
              text: ' *',
              style: TextStyle(color: colors.error),
            ),
        ],
      ),
    );
  }
  
  InputDecoration _buildInputDecoration(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    
    final borderColor = _getBorderColor(context);
    
    return InputDecoration(
      hintText: widget.placeholder,
      prefixIcon: widget.prefixIcon != null 
          ? Icon(widget.prefixIcon, color: _getIconColor(context))
          : null,
      suffixIcon: _buildSuffixIcon(context),
      filled: false, // Kein Fill für transparentes Design
      contentPadding: spacing.inputPadding,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMd),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMd),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMd),
        borderSide: BorderSide(color: _getFocusedBorderColor(context), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMd),
        borderSide: BorderSide(color: colors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMd),
        borderSide: BorderSide(color: colors.error, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMd),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
    );
  }
  
  Widget? _buildSuffixIcon(BuildContext context) {
    // final colors = context.colors;
    
    if (widget.type == VerticInputType.password) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility : Icons.visibility_off,
          color: _getIconColor(context),
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }
    
    if (widget.type == VerticInputType.search && _controller.text.isNotEmpty) {
      return IconButton(
        icon: Icon(Icons.clear, color: _getIconColor(context)),
        onPressed: () {
          _controller.clear();
          widget.onChanged?.call('');
        },
      );
    }
    
    if (widget.suffixIcon != null) {
      return IconButton(
        icon: Icon(widget.suffixIcon, color: _getIconColor(context)),
        onPressed: widget.onSuffixIconPressed,
      );
    }
    
    return null;
  }
  
  Widget _buildStatusText(BuildContext context) {
    final typography = context.typography;
    final statusText = _getStatusText();
    final statusColor = _getStatusColor(context);
    
    return Text(
      statusText!,
      style: typography.bodySmall.copyWith(color: statusColor),
    );
  }
  
  String? _getStatusText() {
    switch (widget.state) {
      case VerticInputState.error:
        return widget.errorText;
      case VerticInputState.success:
        return widget.successText;
      case VerticInputState.warning:
        return widget.warningText;
      case VerticInputState.normal:
      case VerticInputState.disabled:
        return widget.helperText;
    }
  }
  
  Color _getStatusColor(BuildContext context) {
    final colors = context.colors;
    
    switch (widget.state) {
      case VerticInputState.error:
        return colors.error;
      case VerticInputState.success:
        return colors.success;
      case VerticInputState.warning:
        return colors.warning;
      case VerticInputState.normal:
      case VerticInputState.disabled:
        return colors.onSurfaceVariant;
    }
  }
  
  Color _getBorderColor(BuildContext context) {
    final colors = context.colors;
    
    switch (widget.state) {
      case VerticInputState.error:
        return colors.error;
      case VerticInputState.success:
        return colors.success;
      case VerticInputState.warning:
        return colors.warning;
      case VerticInputState.disabled:
        return colors.outlineVariant;
      case VerticInputState.normal:
        return colors.outline;
    }
  }
  
  Color _getFocusedBorderColor(BuildContext context) {
    final colors = context.colors;
    
    switch (widget.state) {
      case VerticInputState.error:
        return colors.error;
      case VerticInputState.success:
        return colors.success;
      case VerticInputState.warning:
        return colors.warning;
      case VerticInputState.disabled:
      case VerticInputState.normal:
        return colors.primary;
    }
  }
  
  Color _getIconColor(BuildContext context) {
    final colors = context.colors;
    
    if (widget.state == VerticInputState.disabled) {
      return colors.onSurfaceVariant.withValues(alpha: 0.5);
    }
    
    if (_hasFocus) {
      return _getFocusedBorderColor(context);
    }
    
    return colors.onSurfaceVariant;
  }
  
  int? _getMaxLines() {
    if (widget.maxLines != null) {
      return widget.maxLines;
    }
    
    switch (widget.type) {
      case VerticInputType.multiline:
        return null; // Unbegrenzt
      case VerticInputType.password:
        return 1;
      default:
        return 1;
    }
  }
  
  List<TextInputFormatter>? _getInputFormatters() {
    if (widget.inputFormatters != null) {
      return widget.inputFormatters;
    }
    
    switch (widget.type) {
      case VerticInputType.phone:
        return [FilteringTextInputFormatter.digitsOnly];
      case VerticInputType.number:
        return [FilteringTextInputFormatter.digitsOnly];
      default:
        return null;
    }
  }
  
  TextInputType _getKeyboardType() {
    switch (widget.type) {
      case VerticInputType.email:
        return TextInputType.emailAddress;
      case VerticInputType.phone:
        return TextInputType.phone;
      case VerticInputType.number:
        return TextInputType.number;
      case VerticInputType.multiline:
        return TextInputType.multiline;
      case VerticInputType.password:
      case VerticInputType.text:
      case VerticInputType.search:
        return TextInputType.text;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// 🎯 CONVENIENCE CONSTRUCTORS
// ═══════════════════════════════════════════════════════════════

class TextInput extends VerticInput {
  const TextInput({
    super.key,
    super.label,
    super.placeholder,
    super.helperText,
    super.errorText,
    super.successText,
    super.warningText,
    super.state,
    super.prefixIcon,
    super.suffixIcon,
    super.onSuffixIconPressed,
    super.controller,
    super.initialValue,
    super.onChanged,
    super.onTap,
    super.readOnly,
    super.required,
    super.maxLength,
    super.inputFormatters,
    super.textInputAction,
    super.onSubmitted,
    super.focusNode,
    super.autofocus,
    super.tooltip,
  }) : super(type: VerticInputType.text);
}

class EmailInput extends VerticInput {
  const EmailInput({
    super.key,
    super.label,
    super.placeholder,
    super.helperText,
    super.errorText,
    super.successText,
    super.warningText,
    super.state,
    super.suffixIcon,
    super.onSuffixIconPressed,
    super.controller,
    super.initialValue,
    super.onChanged,
    super.onTap,
    super.readOnly,
    super.required,
    super.maxLength,
    super.inputFormatters,
    super.textInputAction,
    super.onSubmitted,
    super.focusNode,
    super.autofocus,
    super.tooltip,
  }) : super(
          type: VerticInputType.email,
          prefixIcon: Icons.email,
        );
}

class PasswordInput extends VerticInput {
  const PasswordInput({
    super.key,
    super.label,
    super.placeholder,
    super.helperText,
    super.errorText,
    super.successText,
    super.warningText,
    super.state,
    super.controller,
    super.initialValue,
    super.onChanged,
    super.onTap,
    super.readOnly,
    super.required,
    super.maxLength,
    super.inputFormatters,
    super.textInputAction,
    super.onSubmitted,
    super.focusNode,
    super.autofocus,
    super.tooltip,
  }) : super(
          type: VerticInputType.password,
          prefixIcon: Icons.lock,
        );
}

class PhoneInput extends VerticInput {
  const PhoneInput({
    super.key,
    super.label,
    super.placeholder,
    super.helperText,
    super.errorText,
    super.successText,
    super.warningText,
    super.state,
    super.suffixIcon,
    super.onSuffixIconPressed,
    super.controller,
    super.initialValue,
    super.onChanged,
    super.onTap,
    super.readOnly,
    super.required,
    super.maxLength,
    super.inputFormatters,
    super.textInputAction,
    super.onSubmitted,
    super.focusNode,
    super.autofocus,
    super.tooltip,
  }) : super(
          type: VerticInputType.phone,
          prefixIcon: Icons.phone,
        );
}

class SearchInput extends VerticInput {
  const SearchInput({
    super.key,
    super.label,
    super.placeholder,
    super.helperText,
    super.errorText,
    super.successText,
    super.warningText,
    super.state,
    super.suffixIcon,
    super.onSuffixIconPressed,
    super.controller,
    super.initialValue,
    super.onChanged,
    super.onTap,
    super.readOnly,
    super.required,
    super.maxLength,
    super.inputFormatters,
    super.textInputAction,
    super.onSubmitted,
    super.focusNode,
    super.autofocus,
    super.tooltip,
  }) : super(
          type: VerticInputType.search,
          prefixIcon: Icons.search,
        );
}

class MultilineInput extends VerticInput {
  const MultilineInput({
    super.key,
    super.label,
    super.placeholder,
    super.helperText,
    super.errorText,
    super.successText,
    super.warningText,
    super.state,
    super.prefixIcon,
    super.suffixIcon,
    super.onSuffixIconPressed,
    super.controller,
    super.initialValue,
    super.onChanged,
    super.onTap,
    super.readOnly,
    super.required,
    super.maxLines,
    super.maxLength,
    super.inputFormatters,
    super.textInputAction,
    super.onSubmitted,
    super.focusNode,
    super.autofocus,
    super.tooltip,
  }) : super(type: VerticInputType.multiline);
} 