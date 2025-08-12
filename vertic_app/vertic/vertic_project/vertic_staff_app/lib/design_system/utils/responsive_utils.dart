/// **📏 VERTIC DESIGN SYSTEM - RESPONSIVE UTILITY**
///
/// Bietet eine zentrale Funktion zur Berechnung von responsiven Werten.
/// Dies ermöglicht fließende Skalierung von Schriftgrößen, Abständen, Icon-Größen etc.
/// basierend auf der aktuellen Bildschirmbreite.
library;

/// Berechnet einen responsiven Wert, der linear zwischen einem Minimal-
/// und einem Maximalwert skaliert, basierend auf der Bildschirmbreite.
///
/// - [screenWidth]: Die aktuelle Breite des Bildschirms.
/// - [defaultValue]: Der Zielwert für eine Standard-Bildschirmbreite (z.B. 1440px).
/// - [minValue]: Der absolute Minimalwert, der nicht unterschritten wird (für kleine Bildschirme).
/// - [maxValue]: Der absolute Maximalwert, der nicht überschritten wird (für sehr große Bildschirme).
/// - [standardWidth]: Die Bildschirmbreite, bei der der `defaultValue` erreicht wird.
///
/// **Beispiel:**
/// `responsiveValue(context, defaultValue: 16, minValue: 14, maxValue: 20)`
/// Auf einem kleinen Bildschirm -> 14px
/// Auf einem Standard-Desktop -> 16px
/// Auf einem 4K-Monitor -> 20px
double responsiveValue(
  double screenWidth,
  {required double defaultValue,
  required double minValue,
  double? maxValue,
  double standardWidth = 1440.0,
}) {
  // Skalierungsfaktor berechnen
  final double scaleFactor = screenWidth / standardWidth;
  
  // Skalierten Wert berechnen
  double scaledValue = defaultValue * scaleFactor;
  
  // Sicherstellen, dass der Wert innerhalb der Min/Max-Grenzen liegt
  if (maxValue != null) {
    return scaledValue.clamp(minValue, maxValue);
  }
  return scaledValue.clamp(minValue, double.infinity);
}
