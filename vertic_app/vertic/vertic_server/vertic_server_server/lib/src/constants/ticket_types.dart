// Tickettypen und Preise als Konstanten
class TicketTypes {
  // Tickettyp-Strings
  static const String KIND = 'TAGESKARTE_KIND';
  static const String REGULAER = 'TAGESKARTE_REGULAER';
  static const String SENIOR = 'TAGESKARTE_SENIOR';
  static const String FAMILY = 'TAGESKARTE_FAMILIE';
  static const String GROUP = 'TAGESKARTE_GRUPPE';

  // Altersgrenze für Kindertickets (z.B. unter 12 Jahre)
  static const int KIND_ALTER_MAX = 12;

  // Altersgrenze für Seniorentickets (z.B. ab 65 Jahre)
  static const int SENIOR_ALTER_MIN = 65;

  // Preise in Euro
  static const Map<String, double> PREISE = {
    KIND: 5.50,
    REGULAER: 12.00,
    SENIOR: 8.00,
    FAMILY: 25.00,
    GROUP: 9.00,
  };

  // Tickettyp basierend auf Alter ermitteln
  static String getTicketTypeByAge(int age) {
    if (age < KIND_ALTER_MAX) {
      return KIND;
    } else if (age >= SENIOR_ALTER_MIN) {
      return SENIOR;
    } else {
      return REGULAER;
    }
  }
}
