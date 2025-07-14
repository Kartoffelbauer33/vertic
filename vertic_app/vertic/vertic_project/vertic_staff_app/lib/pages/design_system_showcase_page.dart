import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../design_system/theme_extensions.dart';
import '../design_system/components/buttons.dart';
import '../design_system/components/chips.dart';
import '../design_system/components/badges.dart';
import '../design_system/components/progress_indicators.dart';
import '../main.dart';

/// **🎨 VERTIC DESIGN SYSTEM SHOWCASE**
/// 
/// Umfassende Demonstration aller Design System Elemente:
/// - Farben (Light/Dark Theme)
/// - Typografie-Hierarchie
/// - Spacing & Layout
/// - Komponenten (Buttons, Inputs, Cards, etc.)
/// - Animationen & Interaktionen
/// - Accessibility-Features
class DesignSystemShowcasePage extends StatefulWidget {
  const DesignSystemShowcasePage({super.key});

  @override
  State<DesignSystemShowcasePage> createState() => _DesignSystemShowcasePageState();
}

class _DesignSystemShowcasePageState extends State<DesignSystemShowcasePage>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '🎨 Vertic Design System',
          style: context.typography.titleLarge,
        ),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
                onPressed: () {
                  themeProvider.toggleTheme();
                },
                tooltip: themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Farben', icon: Icon(Icons.palette)),
            Tab(text: 'Typografie', icon: Icon(Icons.text_fields)),
            Tab(text: 'Spacing', icon: Icon(Icons.space_bar)),
            Tab(text: 'Buttons', icon: Icon(Icons.smart_button)),
            Tab(text: 'Inputs', icon: Icon(Icons.input)),
            Tab(text: 'Cards', icon: Icon(Icons.view_agenda)),
            Tab(text: 'Chips & Badges', icon: Icon(Icons.label)),
            Tab(text: 'Progress & Loading', icon: Icon(Icons.trending_up)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildColorsTab(),
          _buildTypographyTab(),
          _buildSpacingTab(),
          _buildButtonsTab(),
          _buildInputsTab(),
          _buildCardsTab(),
          _buildChipsAndBadgesTab(),
          _buildProgressAndLoadingTab(),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════
  // 🎨 FARBEN TAB
  // ═══════════════════════════════════════════════════════════════
  
  Widget _buildColorsTab() {
    return SingleChildScrollView(
      padding: context.spacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Brand Colors'),
          _buildColorRow([
            _buildColorCard('Primary', context.colors.primary, context.colors.onPrimary),
            _buildColorCard('Secondary', context.colors.secondary, context.colors.onSecondary),
            _buildColorCard('Tertiary', context.colors.tertiary, context.colors.onTertiary),
          ]),
          
          SizedBox(height: context.spacing.xl),
          _buildSectionHeader('Status Colors'),
          _buildColorRow([
            _buildColorCard('Success', context.colors.success, context.colors.onSuccess),
            _buildColorCard('Warning', context.colors.warning, context.colors.onWarning),
            _buildColorCard('Error', context.colors.error, context.colors.onError),
            _buildColorCard('Info', context.colors.info, context.colors.onInfo),
          ]),
          
          SizedBox(height: context.spacing.xl),
          _buildSectionHeader('Surface Colors'),
          _buildColorRow([
            _buildColorCard('Surface', context.colors.surface, context.colors.onSurface),
            _buildColorCard('Surface Variant', context.colors.surfaceVariant, context.colors.onSurfaceVariant),
            _buildColorCard('Background', context.colors.background, context.colors.onBackground),
          ]),
          
          SizedBox(height: context.spacing.xl),
          _buildSectionHeader('Container Colors'),
          _buildColorRow([
            _buildColorCard('Primary Container', context.colors.primaryContainer, context.colors.onPrimaryContainer),
            _buildColorCard('Secondary Container', context.colors.secondaryContainer, context.colors.onSecondaryContainer),
            _buildColorCard('Error Container', context.colors.errorContainer, context.colors.onErrorContainer),
          ]),
        ],
      ),
    );
  }
  
  Widget _buildColorRow(List<Widget> cards) {
    if (context.isCompact) {
      return Column(children: cards);
    }
    return Wrap(
      spacing: context.spacing.md,
      runSpacing: context.spacing.md,
      children: cards,
    );
  }
  
  Widget _buildColorCard(String name, Color color, Color onColor) {
    return Container(
      width: context.isCompact ? double.infinity : 200,
      height: 120,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(context.spacing.radiusMd),
        boxShadow: context.shadows.cardShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            name,
            style: context.typography.titleMedium.copyWith(color: onColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.spacing.xs),
          Text(
            '#${color.toARGB32().toRadixString(16).toUpperCase().substring(2)}',
            style: context.typography.bodySmall.copyWith(color: onColor),
          ),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════
  // 📝 TYPOGRAFIE TAB
  // ═══════════════════════════════════════════════════════════════
  
  Widget _buildTypographyTab() {
    return SingleChildScrollView(
      padding: context.spacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Display Styles'),
          _buildTypographyExample('Display Large', context.typography.displayLarge),
          _buildTypographyExample('Display Medium', context.typography.displayMedium),
          _buildTypographyExample('Display Small', context.typography.displaySmall),
          
          SizedBox(height: context.spacing.xl),
          _buildSectionHeader('Headlines'),
          _buildTypographyExample('Headline Large', context.typography.headlineLarge),
          _buildTypographyExample('Headline Medium', context.typography.headlineMedium),
          _buildTypographyExample('Headline Small', context.typography.headlineSmall),
          
          SizedBox(height: context.spacing.xl),
          _buildSectionHeader('Titles'),
          _buildTypographyExample('Title Large', context.typography.titleLarge),
          _buildTypographyExample('Title Medium', context.typography.titleMedium),
          _buildTypographyExample('Title Small', context.typography.titleSmall),
          
          SizedBox(height: context.spacing.xl),
          _buildSectionHeader('Body Text'),
          _buildTypographyExample('Body Large', context.typography.bodyLarge),
          _buildTypographyExample('Body Medium', context.typography.bodyMedium),
          _buildTypographyExample('Body Small', context.typography.bodySmall),
          
          SizedBox(height: context.spacing.xl),
          _buildSectionHeader('Labels'),
          _buildTypographyExample('Label Large', context.typography.labelLarge),
          _buildTypographyExample('Label Medium', context.typography.labelMedium),
          _buildTypographyExample('Label Small', context.typography.labelSmall),
          
          SizedBox(height: context.spacing.xl),
          _buildSectionHeader('Custom Styles'),
          _buildTypographyExample('Button Text', context.typography.buttonText),
          _buildTypographyExample('Caption Text', context.typography.captionText),
          _buildTypographyExample('Overline Text', context.typography.overlineText),
          _buildTypographyExample('Code Text', context.typography.codeText),
        ],
      ),
    );
  }
  
  Widget _buildTypographyExample(String name, TextStyle style) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: style,
          ),
          SizedBox(height: context.spacing.xs),
          Text(
            'Font: ${style.fontFamily}, Size: ${style.fontSize?.toStringAsFixed(1)}sp, Weight: ${style.fontWeight?.toString().split('.').last}',
            style: context.typography.bodySmall.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          Divider(height: context.spacing.md),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════
  // 📏 SPACING TAB
  // ═══════════════════════════════════════════════════════════════
  
  Widget _buildSpacingTab() {
    return SingleChildScrollView(
      padding: context.spacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Basic Spacing Values'),
          _buildSpacingExample('XS', context.spacing.xs),
          _buildSpacingExample('SM', context.spacing.sm),
          _buildSpacingExample('MD', context.spacing.md),
          _buildSpacingExample('LG', context.spacing.lg),
          _buildSpacingExample('XL', context.spacing.xl),
          _buildSpacingExample('XXL', context.spacing.xxl),
          _buildSpacingExample('XXXL', context.spacing.xxxl),
          
          SizedBox(height: context.spacing.xl),
          _buildSectionHeader('Border Radius'),
          _buildRadiusExample('XS Radius', context.spacing.radiusXs),
          _buildRadiusExample('SM Radius', context.spacing.radiusSm),
          _buildRadiusExample('MD Radius', context.spacing.radiusMd),
          _buildRadiusExample('LG Radius', context.spacing.radiusLg),
          _buildRadiusExample('XL Radius', context.spacing.radiusXl),
          
          SizedBox(height: context.spacing.xl),
          _buildSectionHeader('Component Dimensions'),
          _buildDimensionExample('Button Height', context.spacing.buttonHeight),
          _buildDimensionExample('Input Height', context.spacing.inputHeight),
          _buildDimensionExample('App Bar Height', context.spacing.appBarHeight),
          _buildDimensionExample('List Item Height', context.spacing.listItemHeight),
          
          SizedBox(height: context.spacing.xl),
          _buildSectionHeader('Icon Sizes'),
          _buildIconSizeExample('XS', context.spacing.iconXs),
          _buildIconSizeExample('SM', context.spacing.iconSm),
          _buildIconSizeExample('MD', context.spacing.iconMd),
          _buildIconSizeExample('LG', context.spacing.iconLg),
          _buildIconSizeExample('XL', context.spacing.iconXl),
        ],
      ),
    );
  }
  
  Widget _buildSpacingExample(String name, double value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.spacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              name,
              style: context.typography.labelMedium,
            ),
          ),
          Container(
            width: value,
            height: 24,
            color: context.colors.primary,
          ),
          SizedBox(width: context.spacing.md),
          Text(
            '${value.toStringAsFixed(0)}dp',
            style: context.typography.bodySmall,
          ),
        ],
      ),
    );
  }
  
  Widget _buildRadiusExample(String name, double radius) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.spacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              name,
              style: context.typography.labelMedium,
            ),
          ),
          Container(
            width: 60,
            height: 40,
            decoration: BoxDecoration(
              color: context.colors.primaryContainer,
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
          SizedBox(width: context.spacing.md),
          Text(
            '${radius.toStringAsFixed(0)}dp',
            style: context.typography.bodySmall,
          ),
        ],
      ),
    );
  }
  
  Widget _buildDimensionExample(String name, double height) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.spacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              name,
              style: context.typography.labelMedium,
            ),
          ),
          Container(
            width: 120,
            height: height,
            decoration: BoxDecoration(
              color: context.colors.surfaceVariant,
              borderRadius: BorderRadius.circular(context.spacing.radiusMd),
              border: Border.all(color: context.colors.outline),
            ),
            child: Center(
              child: Text(
                '${height.toStringAsFixed(0)}dp',
                style: context.typography.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildIconSizeExample(String name, double size) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.spacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              name,
              style: context.typography.labelMedium,
            ),
          ),
          Icon(
            Icons.star,
            size: size,
            color: context.colors.primary,
          ),
          SizedBox(width: context.spacing.md),
          Text(
            '${size.toStringAsFixed(0)}dp',
            style: context.typography.bodySmall,
          ),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════
  // 🔘 BUTTONS TAB
  // ═══════════════════════════════════════════════════════════════
  
  Widget _buildButtonsTab() {
    return SingleChildScrollView(
      padding: context.spacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Button Variants'),
          SizedBox(height: context.spacing.md),
          
          Wrap(
            spacing: context.spacing.md,
            runSpacing: context.spacing.md,
            children: [
              PrimaryButton(
                text: 'Primary',
                onPressed: () => _showSnackBar('Primary Button'),
              ),
              SecondaryButton(
                text: 'Secondary',
                onPressed: () => _showSnackBar('Secondary Button'),
              ),
              DestructiveButton(
                text: 'Destructive',
                onPressed: () => _showSnackBar('Destructive Button'),
              ),
              VerticOutlineButton(
                text: 'Outline',
                onPressed: () => _showSnackBar('Outline Button'),
              ),
              GhostButton(
                text: 'Ghost',
                onPressed: () => _showSnackBar('Ghost Button'),
              ),
              LinkButton(
                text: 'Link',
                onPressed: () => _showSnackBar('Link Button'),
              ),
            ],
          ),
          
          SizedBox(height: context.spacing.xl),
          _buildSectionHeader('Button Sizes'),
          SizedBox(height: context.spacing.md),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PrimaryButton(
                text: 'Small Button',
                size: VerticButtonSize.small,
                onPressed: () => _showSnackBar('Small Button'),
              ),
              SizedBox(height: context.spacing.md),
              PrimaryButton(
                text: 'Medium Button',
                size: VerticButtonSize.medium,
                onPressed: () => _showSnackBar('Medium Button'),
              ),
              SizedBox(height: context.spacing.md),
              PrimaryButton(
                text: 'Large Button',
                size: VerticButtonSize.large,
                onPressed: () => _showSnackBar('Large Button'),
              ),
            ],
          ),
          
          SizedBox(height: context.spacing.xl),
          _buildSectionHeader('Buttons with Icons'),
          SizedBox(height: context.spacing.md),
          
          Wrap(
            spacing: context.spacing.md,
            runSpacing: context.spacing.md,
            children: [
              PrimaryButton(
                text: 'With Icon',
                icon: Icons.add,
                onPressed: () => _showSnackBar('Button with Icon'),
              ),
              SecondaryButton(
                text: 'Trailing Icon',
                trailingIcon: Icons.arrow_forward,
                onPressed: () => _showSnackBar('Button with Trailing Icon'),
              ),
              PrimaryButton(
                text: 'Both Icons',
                icon: Icons.star,
                trailingIcon: Icons.keyboard_arrow_down,
                onPressed: () => _showSnackBar('Button with Both Icons'),
              ),
            ],
          ),
          
          SizedBox(height: context.spacing.xl),
          _buildSectionHeader('Loading States'),
          SizedBox(height: context.spacing.md),
          
          Wrap(
            spacing: context.spacing.md,
            runSpacing: context.spacing.md,
            children: [
              PrimaryButton(
                text: 'Loading',
                isLoading: true,
                onPressed: () {},
              ),
              SecondaryButton(
                text: 'Loading',
                isLoading: true,
                onPressed: () {},
              ),
              VerticOutlineButton(
                text: 'Uploading',
                isLoading: true,
                onPressed: () {},
              ),
            ],
          ),
          
          SizedBox(height: context.spacing.xl),
          _buildSectionHeader('Disabled States'),
          SizedBox(height: context.spacing.md),
          
          Wrap(
            spacing: context.spacing.md,
            runSpacing: context.spacing.md,
            children: [
              const PrimaryButton(
                text: 'Disabled',
                onPressed: null,
              ),
              const SecondaryButton(
                text: 'Disabled',
                onPressed: null,
              ),
                              const VerticOutlineButton(
                text: 'Disabled',
                onPressed: null,
              ),
            ],
          ),
          
          SizedBox(height: context.spacing.xl),
          _buildSectionHeader('Icon Buttons'),
          SizedBox(height: context.spacing.md),
          
          Wrap(
            spacing: context.spacing.md,
            runSpacing: context.spacing.md,
            children: [
              VerticIconButton(
                icon: Icons.favorite,
                onPressed: () => _showSnackBar('Heart Icon'),
                tooltip: 'Favorite',
              ),
              VerticIconButton(
                icon: Icons.share,
                onPressed: () => _showSnackBar('Share Icon'),
                tooltip: 'Share',
                size: VerticButtonSize.small,
              ),
              VerticIconButton(
                icon: Icons.settings,
                onPressed: () => _showSnackBar('Settings Icon'),
                tooltip: 'Settings',
                size: VerticButtonSize.large,
              ),
              const VerticIconButton(
                icon: Icons.more_vert,
                isLoading: true,
                tooltip: 'Loading...',
              ),
            ],
          ),
          
          SizedBox(height: context.spacing.xl),
          _buildSectionHeader('Expanded Buttons'),
          SizedBox(height: context.spacing.md),
          
          Column(
            children: [
              PrimaryButton(
                text: 'Expanded Primary',
                isExpanded: true,
                onPressed: () => _showSnackBar('Expanded Primary'),
              ),
              SizedBox(height: context.spacing.md),
              SecondaryButton(
                text: 'Expanded Secondary',
                icon: Icons.download,
                isExpanded: true,
                onPressed: () => _showSnackBar('Expanded Secondary'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════
  // 📝 INPUTS TAB
  // ═══════════════════════════════════════════════════════════════
  
  Widget _buildInputsTab() {
    return SingleChildScrollView(
      padding: context.spacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Text Fields'),
          SizedBox(height: context.spacing.md),
          
          const TextField(
            decoration: InputDecoration(
              labelText: 'Standard Text Field',
              hintText: 'Enter some text...',
            ),
          ),
          SizedBox(height: context.spacing.md),
          
          const TextField(
            decoration: InputDecoration(
              labelText: 'With Helper Text',
              hintText: 'Enter your email',
              helperText: 'We\'ll never share your email',
              prefixIcon: Icon(Icons.email),
            ),
          ),
          SizedBox(height: context.spacing.md),
          
          const TextField(
            decoration: InputDecoration(
              labelText: 'With Error',
              errorText: 'This field is required',
              prefixIcon: Icon(Icons.error),
            ),
          ),
          SizedBox(height: context.spacing.md),
          
          const TextField(
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: Icon(Icons.lock),
              suffixIcon: Icon(Icons.visibility),
            ),
          ),
          SizedBox(height: context.spacing.md),
          
          const TextField(
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Multiline Text',
              hintText: 'Enter a longer text...',
              alignLabelWithHint: true,
            ),
          ),
          
          SizedBox(height: context.spacing.xl),
          _buildSectionHeader('Disabled Fields'),
          SizedBox(height: context.spacing.md),
          
          const TextField(
            enabled: false,
            decoration: InputDecoration(
              labelText: 'Disabled Field',
              hintText: 'This field is disabled',
              prefixIcon: Icon(Icons.block),
            ),
          ),
          
          SizedBox(height: context.spacing.xl),
          _buildSectionHeader('Search Field'),
          SizedBox(height: context.spacing.md),
          
          TextField(
            decoration: InputDecoration(
              labelText: 'Search',
              hintText: 'Search for articles...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {},
              ),
            ),
          ),
          
          SizedBox(height: context.spacing.xl),
          _buildSectionHeader('Dropdowns & Selects'),
          SizedBox(height: context.spacing.md),
          
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Select an option',
              prefixIcon: Icon(Icons.arrow_drop_down),
            ),
            items: ['Option 1', 'Option 2', 'Option 3']
                .map((value) => DropdownMenuItem(
                      value: value,
                      child: Text(value),
                    ))
                .toList(),
            onChanged: (value) => _showSnackBar('Selected: $value'),
          ),
          
          SizedBox(height: context.spacing.xl),
          _buildSectionHeader('Checkboxes & Switches'),
          SizedBox(height: context.spacing.md),
          
          CheckboxListTile(
            title: const Text('Checkbox Option'),
            subtitle: const Text('This is a checkbox with subtitle'),
            value: true,
            onChanged: (value) => _showSnackBar('Checkbox: $value'),
          ),
          
          SwitchListTile(
            title: const Text('Switch Option'),
            subtitle: const Text('This is a switch with subtitle'),
            value: false,
            onChanged: (value) => _showSnackBar('Switch: $value'),
          ),
          
          SizedBox(height: context.spacing.xl),
          _buildSectionHeader('Radio Buttons'),
          SizedBox(height: context.spacing.md),
          
          Column(
            children: [
              RadioListTile<String>(
                title: const Text('Option A'),
                value: 'A',
                groupValue: 'A',
                onChanged: (value) => _showSnackBar('Radio: $value'),
              ),
              RadioListTile<String>(
                title: const Text('Option B'),
                value: 'B',
                groupValue: 'A',
                onChanged: (value) => _showSnackBar('Radio: $value'),
              ),
              RadioListTile<String>(
                title: const Text('Option C'),
                value: 'C',
                groupValue: 'A',
                onChanged: (value) => _showSnackBar('Radio: $value'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════
  // 🃏 CARDS & MORE TAB
  // ═══════════════════════════════════════════════════════════════
  
  Widget _buildCardsTab() {
    return SingleChildScrollView(
      padding: context.spacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Cards'),
          SizedBox(height: context.spacing.md),
          
          // Standard Card
          Card(
            child: Padding(
              padding: context.spacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Standard Card',
                    style: context.typography.titleMedium,
                  ),
                  SizedBox(height: context.spacing.sm),
                  Text(
                    'This is a standard card with some content. Cards are used to group related information.',
                    style: context.typography.bodyMedium,
                  ),
                  SizedBox(height: context.spacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _showSnackBar('Cancel'),
                        child: const Text('Cancel'),
                      ),
                      SizedBox(width: context.spacing.sm),
                      ElevatedButton(
                        onPressed: () => _showSnackBar('OK'),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: context.spacing.md),
          
          // List Card
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('John Doe'),
                  subtitle: const Text('Software Developer'),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showSnackBar('More options'),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: context.spacing.cardPadding,
                  child: Text(
                    'This card contains a list tile with avatar, title, subtitle and action button.',
                    style: context.typography.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: context.spacing.md),
          
          // Elevated Card
          Card(
            elevation: 8,
            child: Padding(
              padding: context.spacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: context.colors.primary),
                      SizedBox(width: context.spacing.sm),
                      Text(
                        'Elevated Card',
                        style: context.typography.titleMedium,
                      ),
                    ],
                  ),
                  SizedBox(height: context.spacing.sm),
                  Text(
                    'This card has higher elevation and includes an icon in the header.',
                    style: context.typography.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: context.spacing.md),
          
          // Outlined Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.spacing.radiusMd),
              side: BorderSide(color: context.colors.outline),
            ),
            child: Padding(
              padding: context.spacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Outlined Card',
                    style: context.typography.titleMedium,
                  ),
                  SizedBox(height: context.spacing.sm),
                  Text(
                    'This card has no elevation but uses a border outline.',
                    style: context.typography.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: context.spacing.xl),
          _buildSectionHeader('Card Variations'),
          SizedBox(height: context.spacing.md),
          
          // Card Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: context.spacing.md,
            mainAxisSpacing: context.spacing.md,
            childAspectRatio: 1.5,
            children: [
              Card(
                child: Padding(
                  padding: context.spacing.cardPadding,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.dashboard, size: 32, color: context.colors.primary),
                      SizedBox(height: context.spacing.sm),
                      Text(
                        'Dashboard',
                        style: context.typography.titleSmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: context.spacing.cardPadding,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics, size: 32, color: context.colors.secondary),
                      SizedBox(height: context.spacing.sm),
                      Text(
                        'Analytics',
                        style: context.typography.titleSmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: context.spacing.cardPadding,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.settings, size: 32, color: context.colors.tertiary),
                      SizedBox(height: context.spacing.sm),
                      Text(
                        'Settings',
                        style: context.typography.titleSmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: context.spacing.cardPadding,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.help, size: 32, color: context.colors.info),
                      SizedBox(height: context.spacing.sm),
                      Text(
                        'Help',
                        style: context.typography.titleSmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════
  // 🃏 CHIPS TAB
  // ═══════════════════════════════════════════════════════════════
  
  Widget _buildChipsAndBadgesTab() {
    return SingleChildScrollView(
      padding: context.spacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Chips'),
          SizedBox(height: context.spacing.md),
          
          // Vertic Chips
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vertic Chips',
                style: context.typography.titleSmall,
              ),
              SizedBox(height: context.spacing.sm),
              Wrap(
                spacing: context.spacing.sm,
                runSpacing: context.spacing.sm,
                children: [
                  VerticChip(
                    label: 'Filled',
                    variant: VerticChipVariant.filled,
                    onPressed: () => _showSnackBar('Filled chip pressed'),
                  ),
                  VerticChip(
                    label: 'Outlined',
                    variant: VerticChipVariant.outlined,
                    onPressed: () => _showSnackBar('Outlined chip pressed'),
                  ),
                  VerticChip(
                    label: 'Elevated',
                    variant: VerticChipVariant.elevated,
                    onPressed: () => _showSnackBar('Elevated chip pressed'),
                  ),
                  VerticChip(
                    label: 'With Icon',
                    icon: Icons.star,
                    onPressed: () => _showSnackBar('Icon chip pressed'),
                  ),
                  VerticChip(
                    label: 'Deletable',
                    onPressed: () => _showSnackBar('Deletable chip pressed'),
                    onDeleted: () => _showSnackBar('Chip deleted'),
                  ),
                  VerticChip(
                    label: 'Selected',
                    selected: true,
                    onPressed: () => _showSnackBar('Selected chip pressed'),
                  ),
                ],
              ),
            ],
          ),
          
          SizedBox(height: context.spacing.lg),
          
          // Filter Chips
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Chips',
                style: context.typography.titleSmall,
              ),
              SizedBox(height: context.spacing.sm),
              Wrap(
                spacing: context.spacing.sm,
                runSpacing: context.spacing.sm,
                children: [
                  VerticFilterChip(
                    label: 'All',
                    selected: true,
                    onSelected: (selected) => _showSnackBar('All filter: $selected'),
                  ),
                  VerticFilterChip(
                    label: 'Active',
                    icon: Icons.check_circle,
                    onSelected: (selected) => _showSnackBar('Active filter: $selected'),
                  ),
                  VerticFilterChip(
                    label: 'Inactive',
                    icon: Icons.cancel,
                    onSelected: (selected) => _showSnackBar('Inactive filter: $selected'),
                  ),
                ],
              ),
            ],
          ),
          
          SizedBox(height: context.spacing.xl),
          _buildSectionHeader('Badges'),
          SizedBox(height: context.spacing.md),
          
          // Notification Badges
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notification Badges',
                style: context.typography.titleSmall,
              ),
              SizedBox(height: context.spacing.sm),
              Wrap(
                spacing: context.spacing.lg,
                runSpacing: context.spacing.lg,
                children: [
                  VerticBadge(
                    count: 5,
                    child: Icon(Icons.notifications, size: 32),
                  ),
                  VerticBadge(
                    count: 99,
                    child: Icon(Icons.mail, size: 32),
                  ),
                  VerticBadge(
                    count: 150,
                    maxCount: 99,
                    child: Icon(Icons.chat, size: 32),
                  ),
                  VerticBadge.dot(
                    child: Icon(Icons.settings, size: 32),
                  ),
                ],
              ),
            ],
          ),
          
          SizedBox(height: context.spacing.lg),
          
          // Status Badges
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status Badges',
                style: context.typography.titleSmall,
              ),
              SizedBox(height: context.spacing.sm),
              Wrap(
                spacing: context.spacing.md,
                runSpacing: context.spacing.md,
                children: [
                  VerticStatusBadge(
                    label: 'Online',
                    color: VerticBadgeColor.success,
                  ),
                  VerticStatusBadge(
                    label: 'Offline',
                    color: VerticBadgeColor.error,
                  ),
                  VerticStatusBadge(
                    label: 'Pending',
                    color: VerticBadgeColor.warning,
                  ),
                  VerticStatusBadge(
                    label: 'Processing',
                    color: VerticBadgeColor.info,
                  ),
                  VerticStatusBadge(
                    label: 'Active',
                    color: VerticBadgeColor.primary,
                  ),
                ],
              ),
            ],
          ),
          
          SizedBox(height: context.spacing.lg),
          
          // Badge Colors
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Badge Colors',
                style: context.typography.titleSmall,
              ),
              SizedBox(height: context.spacing.sm),
              Wrap(
                spacing: context.spacing.lg,
                runSpacing: context.spacing.lg,
                children: [
                  VerticBadge(
                    count: 1,
                    color: VerticBadgeColor.primary,
                    child: Icon(Icons.star, size: 32),
                  ),
                  VerticBadge(
                    count: 2,
                    color: VerticBadgeColor.secondary,
                    child: Icon(Icons.favorite, size: 32),
                  ),
                  VerticBadge(
                    count: 3,
                    color: VerticBadgeColor.success,
                    child: Icon(Icons.check, size: 32),
                  ),
                  VerticBadge(
                    count: 4,
                    color: VerticBadgeColor.warning,
                    child: Icon(Icons.warning, size: 32),
                  ),
                  VerticBadge(
                    count: 5,
                    color: VerticBadgeColor.error,
                    child: Icon(Icons.error, size: 32),
                  ),
                  VerticBadge(
                    count: 6,
                    color: VerticBadgeColor.info,
                    child: Icon(Icons.info, size: 32),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════
  // 📊 PROGRESS INDICATORS TAB
  // ═══════════════════════════════════════════════════════════════
  
  Widget _buildProgressAndLoadingTab() {
    return SingleChildScrollView(
      padding: context.spacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Progress Indicators'),
          SizedBox(height: context.spacing.md),
          
          // Vertic Progress Indicators
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Linear Progress',
                style: context.typography.titleSmall,
              ),
              SizedBox(height: context.spacing.sm),
              VerticProgressIndicator.linear(
                value: 0.7,
                label: 'Upload Progress',
                showPercentage: true,
              ),
              SizedBox(height: context.spacing.md),
              VerticProgressIndicator.linear(
                label: 'Processing...',
                sublabel: 'This may take a few moments',
              ),
            ],
          ),
          
          SizedBox(height: context.spacing.lg),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Circular Progress',
                style: context.typography.titleSmall,
              ),
              SizedBox(height: context.spacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  VerticProgressIndicator.circular(
                    value: 0.75,
                    size: VerticProgressSize.small,
                    showPercentage: true,
                  ),
                  VerticProgressIndicator.circular(
                    value: 0.5,
                    size: VerticProgressSize.medium,
                    showPercentage: true,
                  ),
                  VerticProgressIndicator.circular(
                    value: 0.25,
                    size: VerticProgressSize.large,
                    showPercentage: true,
                  ),
                ],
              ),
            ],
          ),
          
          SizedBox(height: context.spacing.lg),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Loading Indicator',
                style: context.typography.titleSmall,
              ),
              SizedBox(height: context.spacing.sm),
              const Center(
                child: VerticLoadingIndicator(
                  message: 'Loading data...',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════
  // 🛠️ HELPER METHODS
  // ═══════════════════════════════════════════════════════════════
  
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: context.typography.headlineSmall.copyWith(
        color: context.colors.primary,
      ),
    );
  }
  
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: context.spacing.pagePadding,
      ),
    );
  }
  
  void _showAlertDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alert Dialog'),
        content: const Text('This is an example alert dialog using the design system theme.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: context.spacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bottom Sheet',
              style: context.typography.titleLarge,
            ),
            SizedBox(height: context.spacing.md),
            const Text('This is an example bottom sheet using the design system.'),
            SizedBox(height: context.spacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 