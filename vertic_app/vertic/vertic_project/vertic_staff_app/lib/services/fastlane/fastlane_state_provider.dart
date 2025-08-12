import 'package:flutter/foundation.dart';

/// Fastlane-Modi für die Kiosk-Nutzung
enum FastlaneMode {
  registration,
  login,
  checkIn,
  loginAndRegistration,
  allInOne,
}

/// Zentrale Steuerung für den Fastlane-Modus (Kiosk-Lock, Modus, etc.)
class FastlaneStateProvider extends ChangeNotifier {
  bool _isActive = false;
  FastlaneMode? _mode;

  bool get isActive => _isActive;
  FastlaneMode? get mode => _mode;

  /// Aktiviert den Fastlane-Modus und setzt den gewünschten Modus
  void activate(FastlaneMode mode) {
    if (_isActive && _mode == mode) return;
    _isActive = true;
    _mode = mode;
    notifyListeners();
  }

  /// Deaktiviert den Fastlane-Modus vollständig
  void deactivate() {
    if (!_isActive && _mode == null) return;
    _isActive = false;
    _mode = null;
    notifyListeners();
  }

  /// Setzt den Modus ohne den Kiosk-Lock zu beeinflussen
  void setMode(FastlaneMode? mode) {
    _mode = mode;
    notifyListeners();
  }
}


