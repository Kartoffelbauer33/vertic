import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vertic_staff/design_system/design_system.dart';
import 'package:test_server_client/test_server_client.dart';
import 'faslane_dashboard_page.dart';
import 'package:vertic_staff/services/fastlane/fastlane_state_provider.dart';
import 'package:vertic_staff/widgets/fastlane/staff_unlock_dialog.dart';

import 'fastlane_registration_page.dart';

/// Fastlane Einstieg: Modusauswahl, Kiosk-Lock und Logo-Tap-Exit
class FastlanePage extends StatefulWidget {
  const FastlanePage({super.key});

  @override
  State<FastlanePage> createState() => _FastlanePageState();
}

class _FastlanePageState extends State<FastlanePage> {
  int _logoTapCounter = 0;
  DateTime? _firstTapAt;
  bool _clientLoggedIn = false; // Nach Login: zeige Client-Home

  @override
  void initState() {
    super.initState();
    // Tastatur-Shortcut: Cmd + V fünfmal (als Ersatz für 5x Logo auf Desktop)
    // Wir lauschen global in diesem Screen via Shortcuts/Actions
  }

  void _handleLogoTap() {
    final now = DateTime.now();
    if (_firstTapAt == null || now.difference(_firstTapAt!).inSeconds > 3) {
      _firstTapAt = now;
      _logoTapCounter = 0;
    }
    _logoTapCounter++;
    if (_logoTapCounter >= 5) {
      _logoTapCounter = 0;
      _firstTapAt = null;
      _promptStaffUnlock();
    }
  }

  Future<void> _promptStaffUnlock() async {
    final ok = await StaffUnlockDialog.show(context);
    if (!mounted) return;
    if (ok) context.read<FastlaneStateProvider>().deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final fastlane = context.watch<FastlaneStateProvider>();
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;

    final child = fastlane.mode == null
        ? _buildModePicker(context)
        : _buildModeContent(context, fastlane.mode!);

    // Shortcuts für Desktop: Robuste, plattformübergreifende Kombination
    // macOS: Cmd + Shift + U
    // Windows/Linux: Alt + Shift + U
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        // macOS Variante (Cmd + Shift + U)
        LogicalKeySet(
          LogicalKeyboardKey.meta,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyU,
        ): _FastlaneUnlockIntent(),
        // Windows/Linux Variante (Alt + Shift + U)
        LogicalKeySet(
          LogicalKeyboardKey.alt,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyU,
        ): _FastlaneUnlockIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _FastlaneUnlockIntent: CallbackAction<_FastlaneUnlockIntent>(
            onInvoke: (intent) {
              // Ignoriere Shortcut, wenn ein Textfeld fokussiert ist
              final focusContext = FocusManager.instance.primaryFocus?.context;
              final hasEditableAncestor =
                  focusContext?.findAncestorWidgetOfExactType<EditableText>() != null;
              if (hasEditableAncestor) return null;
              // Desktop / Nicht-Mobile Plattformen direkt entsperrbar per Shortcut
              final isMobile = defaultTargetPlatform == TargetPlatform.android ||
                  defaultTargetPlatform == TargetPlatform.iOS;
              if (!isMobile) {
                // Direkt den Staff-Unlock-Dialog anzeigen (robust, kein 5x Tap nötig)
                _promptStaffUnlock();
              }
              return null;
            },
          ),
        },
        child: Scaffold(
          backgroundColor: colors.surface,
          body: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    // Zusätzlicher Top-Offset, damit Step-Bar nicht mit Titel kollidiert
                    padding: EdgeInsets.fromLTRB(
                      spacing.lg,
                      spacing.lg + 48,
                      spacing.lg,
                      spacing.lg,
                    ),
                    child: child,
                  ),
                ),
                // Logo oben links, 5x Tap beendet Kiosk
                Positioned(
                  top: spacing.md,
                  left: spacing.md,
                  child: GestureDetector(
                    onTap: _handleLogoTap,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        Icon(LucideIcons.zap, color: colors.primary, size: spacing.iconLg),
                        SizedBox(width: spacing.sm),
                        Text('Fastlane', style: typography.titleLarge.copyWith(color: colors.onSurface)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModePicker(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final typography = context.typography;

    final card = Card(
      child: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fastlane Modus wählen', style: typography.headlineSmall.copyWith(color: colors.onSurface)),
            SizedBox(height: spacing.md),
            Wrap(
              spacing: spacing.md,
              runSpacing: spacing.md,
              children: [
                _modeButton(context, 'Registrierung', LucideIcons.userPlus, FastlaneMode.registration),
                _modeButton(context, 'Login', LucideIcons.logIn, FastlaneMode.login),
                _modeButton(context, 'Check-in', LucideIcons.qrCode, FastlaneMode.checkIn),
                _modeButton(context, 'Login + Registrierung', LucideIcons.switchCamera, FastlaneMode.loginAndRegistration),
                _modeButton(context, 'Alles (Kombiniert)', LucideIcons.grid2x2, FastlaneMode.allInOne),
              ],
            ),
            SizedBox(height: spacing.lg),
            Text(
              'Hinweis: Nach Auswahl ist die Staff-App gesperrt. Beenden über 5x Tippen auf das Icon oder Shortcut (Desktop: macOS Cmd+Shift+U, Windows/Linux Alt+Shift+U).',
              style: typography.bodySmall.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: card,
      ),
    );
  }

  Widget _modeButton(BuildContext context, String label, IconData icon, FastlaneMode mode) {
    final spacing = context.spacing;
    final colors = context.colors;
    final typography = context.typography;
    return InkWell(
      onTap: () => context.read<FastlaneStateProvider>().activate(mode),
      borderRadius: BorderRadius.circular(spacing.radiusMd),
      child: Container(
        padding: EdgeInsets.all(spacing.lg),
        width: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(spacing.radiusMd),
          border: Border.all(color: colors.outline),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: spacing.iconXl, color: colors.primary),
            SizedBox(height: spacing.md),
            Text(label, style: typography.titleMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildModeContent(BuildContext context, FastlaneMode mode) {
    switch (mode) {
      case FastlaneMode.registration:
        return const FastlaneRegistrationPage();
      case FastlaneMode.login:
        return _buildLogin(context);
      case FastlaneMode.checkIn:
        return _buildComingSoon(context, 'Check-in');
      case FastlaneMode.loginAndRegistration:
        return _buildSplit(context, const FastlaneRegistrationPage(), _buildLogin(context));
      case FastlaneMode.allInOne:
        return _buildAllInOne(context);
    }
  }

  Widget _buildSplit(BuildContext context, Widget left, Widget right) {
    if (context.isCompact) {
      return Column(children: [Expanded(child: left), const Divider(height: 1), Expanded(child: right)]);
    }
    return Row(children: [Expanded(child: left), const VerticalDivider(width: 1), Expanded(child: right)]);
  }

  Widget _buildAllInOne(BuildContext context) {
    final spacing = context.spacing;
    return _buildSplit(
      context,
      const FastlaneRegistrationPage(),
      Padding(
        padding: EdgeInsets.all(spacing.md),
        child: _buildLogin(context),
      ),
    );
  }

  Widget _buildComingSoon(BuildContext context, String name) {
    final typography = context.typography;
    final colors = context.colors;
    return Center(
      child: Text('$name wird implementiert...', style: typography.titleMedium.copyWith(color: colors.onSurfaceVariant)),
    );
  }

  Widget _buildLogin(BuildContext context) {
    final client = Provider.of<Client>(context, listen: false);
    if (_clientLoggedIn) {
      return FastlaneClientHome(client: client);
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: FastlaneLoginPanel(
          client: client,
          onLoggedIn: (sessionManager, emailAuth) {
            if (!mounted) return;
            setState(() {
              _clientLoggedIn = true;
            });
          },
        ),
      ),
    );
  }
}

/// Intent für das Auslösen des Staff-Unlock-Dialogs über Tastenkombination
class _FastlaneUnlockIntent extends Intent {
  const _FastlaneUnlockIntent();
}

