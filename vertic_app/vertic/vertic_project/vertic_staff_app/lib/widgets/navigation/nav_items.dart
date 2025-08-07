//vertic_staff_app/lib/widgets/navigation/nav_items.dart
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'nav_models.dart';

final List<NavItem> mainNavItems = [
  NavItem(
    title: 'Dashboard',
    icon: LucideIcons.layoutDashboard,
    route: '/dashboard',
  ),
  NavItem(title: 'POS', icon: LucideIcons.shoppingCart, route: '/pos'),
  NavItem(title: 'Fastlane', icon: LucideIcons.zap, route: '/fastlane'),
  NavItem(
    title: 'Kundenverwaltung',
    icon: LucideIcons.users,
    route: '/customers',
    children: [
      NavItem(
        title: 'Kundensuche',
        icon: LucideIcons.userSearch,
        route: '/customers',
      ),
      NavItem(
        title: 'Kunden anlegen',
        icon: LucideIcons.userPlus,
        route: '/customers',
      ),
      NavItem(
        title: 'Familie',
        icon: LucideIcons.users,
        route: '/customers',
      ),
    ],
  ),
];

final List<NavItem> planningNavItems = [
  NavItem(
    title: 'Schichtplanung',
    icon: LucideIcons.calendar,
    route: '/planning',
    children: [
      NavItem(
        title: 'Kalender',
        icon: LucideIcons.calendarDays,
        route: '/planning/calendar',
      ),
      NavItem(
        title: 'Stempeluhr',
        icon: LucideIcons.clock,
        route: '/planning/time-clock',
      ),
      NavItem(
        title: 'Tauschbörse',
        icon: LucideIcons.chevronsLeftRightEllipsis,
        route: '/planning/exchange-market',
      ),
      NavItem(
        title: 'Auswertung',
        icon: LucideIcons.chartLine,
        route: '/planning/reports',
      ),
      NavItem(
        title: 'To Dos',
        icon: LucideIcons.listChecks,
        route: '/planning/todos',
      ),
    ],
  ),
];

final List<NavItem> reportsNavItems = [
  NavItem(
    title: 'Lagerbestand',
    icon: LucideIcons.package,
    route: '/stock/',
    children: [
      NavItem(
        title: 'Artikel',
        icon: LucideIcons.package,
        route: '/stock/products',
      ),
      NavItem(
        title: 'Bestellungen',
        icon: LucideIcons.shoppingCart,
        route: '/stock/orders',
      ),
      NavItem(
        title: 'Stornierungen',
        icon: LucideIcons.undo2,
        route: '/stock/returns',
      ),
      NavItem(
        title: 'Bestellliste',
        icon: LucideIcons.shoppingCart,
        route: '/stock/stock-list',
      ),
    ],
  ),
];

final List<NavItem> settingsNavItems = [
  NavItem(
    title: 'Auswertungen',
    icon: LucideIcons.info,
    route: '/analytics',
    children: [
      NavItem(
        title: 'Verkäufe',
        icon: LucideIcons.package,
        route: '/statistics',
      ),
      NavItem(
        title: 'Stornierungen',
        icon: LucideIcons.undo2,
        route: '/analytics/returns',
      ),
      NavItem(
        title: 'Ausgaben',
        icon: LucideIcons.package,
        route: '/analytics/expenses',
      ),
      NavItem(
        title: 'Kunden',
        icon: LucideIcons.users,
        route: '/analytics/users',
      ),
      NavItem(
        title: 'Mitarbeiter',
        icon: LucideIcons.userCog,
        route: '/analytics/staff',
      ),
    ],
  ),
];

final List<NavItem> administrationNavItems = [
  NavItem(
    title: 'Verwaltung',
    icon: LucideIcons.archive,
    route: '/management',
    children: [
      NavItem(
        title: 'Produkte',
        icon: LucideIcons.package,
        route: '/products',
      ),
      NavItem(
        title: 'Tickets',
        icon: LucideIcons.ticket,
        route: '/management/tickets',
      ),
      NavItem(
        title: 'Kurse',
        icon: LucideIcons.package,
        route: '/management/courses',
      ),
      NavItem(
        title: 'Mitarbeiter',
        icon: LucideIcons.userCog,
        route: '/management/staff',
      ),
      NavItem(
        title: 'Rollen',
        icon: LucideIcons.shield,
        route: '/management/roles',
      ),
      NavItem(
        title: 'Organisation',
        icon: LucideIcons.building2,
        route: '/management/organization',
      ),
      NavItem(
        title: 'Gym',
        icon: LucideIcons.dumbbell,
        route: '/management/gym',
      ),
      NavItem(
        title: 'Automationen',
        icon: LucideIcons.workflow,
        route: '/management/automation',
      ),
      NavItem(
        title: 'Einstellungen',
        icon: LucideIcons.settings,
        route: '/management/settings',
      ),
    ],
  ),
];

final List<NavItem> designNavItems = [
  NavItem(title: 'Design', icon: LucideIcons.paintBucket, route: '/design'),
];

final List<NavItem> adminNavItems = [
  NavItem(
    title: 'Admin',
    icon: LucideIcons.lockKeyhole,
    route: '/admin',
    children: [
      NavItem(
        title: 'System Meldungen',
        icon: LucideIcons.messageCircle,
        route: '/admin/system-messages',
      ),
      NavItem(
        title: 'Unified Ticket Managment',
        icon: LucideIcons.ticket,
        route: '/admin/unified-ticket-managment',
      ),
      NavItem(
        title: 'Gym Verwaltung',
        icon: LucideIcons.building2,
        route: '/admin/gym-management',
      ),
      NavItem(
        title: 'RBAC Managment',
        icon: LucideIcons.shield,
        route: '/admin/rbac-management',
      ),
      NavItem(
        title: 'Ticket Sichtbarkeit',
        icon: LucideIcons.eye,
        route: '/admin/ticket-visibility',
      ),
      NavItem(
        title: 'Drucker Einstellungen',
        icon: LucideIcons.printer,
        route: '/admin/printer-settings',
      ),
      NavItem(
        title: 'Scanner Einstellungen',
        icon: LucideIcons.camera,
        route: '/admin/scanner-settings',
      ),
      NavItem(
        title: 'Dokumentenverwaltung',
        icon: LucideIcons.file,
        route: '/admin/document-management',
      ),
      NavItem(
        title: 'Benutzer-Status verwalten',
        icon: LucideIcons.userCog,
        route: '/admin/user-status-management',
      ),
      NavItem(
        title: 'Preisgestaltung',
        icon: LucideIcons.euro,
        route: '/admin/pricing-management',
      ),
      NavItem(
        title: 'Abrechnungsmanagement',
        icon: LucideIcons.creditCard,
        route: '/admin/billing-management',
      ),
      NavItem(
        title: 'System-Konfiguration',
        icon: LucideIcons.settings,
        route: '/admin/system-configuration',
      ),
      NavItem(
        title: 'QR-Code Rotation',
        icon: LucideIcons.qrCode,
        route: '/admin/qr-code-rotation',
      ),
      NavItem(
        title: 'External Provider Managment',
        icon: LucideIcons.cloud,
        route: '/admin/external-provider-management',
      ),
      NavItem(
        title: 'DACH-Complianze',
        icon: LucideIcons.shield,
        route: '/admin/dach-complianze',
      ),
      NavItem(
        title: 'Berichte % Analyse',
        icon: LucideIcons.chartLine,
        route: '/admin/reports-analysis',
      ),
      NavItem(
        title: 'Backup & Wartung',
        icon: LucideIcons.database,
        route: '/admin/backup',
      ),
    ],
  ),
];

final List<NavItem> bottomNavItems = [
  NavItem(title: 'Settings', icon: LucideIcons.settings, route: '/settings'),
  NavItem(title: 'Admin', icon: LucideIcons.lockKeyhole, route: '/admin'),
];
