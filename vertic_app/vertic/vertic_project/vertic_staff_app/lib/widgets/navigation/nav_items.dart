// lib/widgets/navigation/nav_items.dart

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vertic_staff/router/routes.dart';

import 'nav_models.dart';

/// Haupt-Navigation
final List<NavItem> mainNavItems = [
  NavItem(
    title: 'Dashboard',
    icon: LucideIcons.layoutDashboard,
    route: Routes.dashboard,
  ),
  NavItem(title: 'POS', icon: LucideIcons.shoppingCart, route: Routes.pos),
  NavItem(title: 'Fastlane', icon: LucideIcons.zap, route: Routes.fastlane),
  NavItem(
    title: 'Kundenverwaltung',
    icon: LucideIcons.users,
    route: Routes.customers,
    children: [
      NavItem(
        title: 'Kundensuche',
        icon: LucideIcons.userSearch,
        route: Routes.customers,
      ),
      NavItem(
        title: 'Kunden anlegen',
        icon: LucideIcons.userPlus,
        route: Routes.customerAdd,
      ),
      NavItem(
        title: 'Familie',
        icon: LucideIcons.users,
        route: Routes.customerFamilies,
      ),
    ],
  ),
];

/// Schichtplanung
final List<NavItem> planningNavItems = [
  NavItem(
    title: 'Schichtplanung',
    icon: LucideIcons.calendar,
    route: Routes.planning,
    children: [
      NavItem(
        title: 'Kalender',
        icon: LucideIcons.calendarDays,
        route: Routes.planningCalendar,
      ),
      NavItem(
        title: 'Stempeluhr',
        icon: LucideIcons.clock,
        route: Routes.planningTimeClock,
      ),
      NavItem(
        title: 'Tauschbörse',
        icon: LucideIcons.chevronsLeftRightEllipsis,
        route: Routes.planningExchangeMarket,
      ),
      NavItem(
        title: 'Auswertung',
        icon: LucideIcons.chartLine,
        route: Routes.planningReports,
      ),
      NavItem(
        title: 'To Dos',
        icon: LucideIcons.listChecks,
        route: Routes.planningTodos,
      ),
    ],
  ),
];

/// Lagerbestand
final List<NavItem> reportsNavItems = [
  NavItem(
    title: 'Lagerbestand',
    icon: LucideIcons.package,
    route: Routes.stock,
    children: [
      NavItem(
        title: 'Artikel',
        icon: LucideIcons.package,
        route: Routes.stockProducts,
      ),
      NavItem(
        title: 'Bestellungen',
        icon: LucideIcons.shoppingCart,
        route: Routes.stockOrders,
      ),
      NavItem(
        title: 'Stornierungen',
        icon: LucideIcons.undo2,
        route: Routes.stockReturns,
      ),
      NavItem(
        title: 'Bestellliste',
        icon: LucideIcons.shoppingCart,
        route: Routes.stockOrderList,
      ),
    ],
  ),
];

/// Auswertung & Analytics
final List<NavItem> settingsNavItems = [
  NavItem(
    title: 'Auswertungen',
    icon: LucideIcons.chartLine,
    route: Routes.statistics,
    children: [
      NavItem(
        title: 'Verkäufe',
        icon: LucideIcons.euro,
        route: Routes.analyticsSales,
      ),
      NavItem(
        title: 'Stornierungen',
        icon: LucideIcons.undo2,
        route: Routes.analyticsReturns,
      ),
      NavItem(
        title: 'Ausgaben',
        icon: LucideIcons.creditCard,
        route: Routes.analyticsExpenses,
      ),
      NavItem(
        title: 'Kundenverhalten',
        icon: LucideIcons.users,
        route: Routes.analyticsUserBehavior,
      ),
      NavItem(
        title: 'Mitarbeiter',
        icon: LucideIcons.userCog,
        route: Routes.analyticsStaff,
      ),
    ],
  ),
];

/// Verwaltung
final List<NavItem> administrationNavItems = [
  NavItem(
    title: 'Verwaltung',
    icon: LucideIcons.archive,
    route: Routes.administration,
    children: [
      NavItem(
        title: 'Produkte',
        icon: LucideIcons.package,
        route: Routes.adminProducts,
      ),
      NavItem(
        title: 'Tickets',
        icon: LucideIcons.ticket,
        route: Routes.adminTickets,
      ),
      NavItem(
        title: 'Kurse',
        icon: LucideIcons.book,
        route: Routes.adminCourses,
      ),
      NavItem(
        title: 'Mitarbeiter',
        icon: LucideIcons.userCog,
        route: Routes.adminStaff,
      ),
      NavItem(
        title: 'Rollen',
        icon: LucideIcons.shield,
        route: Routes.adminRoles,
      ),
      NavItem(
        title: 'Organisation',
        icon: LucideIcons.building2,
        route: Routes.adminOrganization,
      ),
      NavItem(title: 'Gym', icon: LucideIcons.dumbbell, route: Routes.adminGym),
      NavItem(
        title: 'Automationen',
        icon: LucideIcons.workflow,
        route: Routes.adminAutomation,
      ),
      NavItem(
        title: 'Einstellungen',
        icon: LucideIcons.settings,
        route: Routes.adminSettings,
      ),
    ],
  ),
];

/// Design System Showcase
final List<NavItem> designNavItems = [
  NavItem(title: 'Design', icon: LucideIcons.paintBucket, route: Routes.design),
];

/// Superuser/Admin-Bereich
final List<NavItem> adminNavItems = [
  NavItem(
    title: 'Admin',
    icon: LucideIcons.lockKeyhole,
    route: Routes.adminDashboard,
    children: [
      NavItem(
        title: 'System Meldungen',
        icon: LucideIcons.messageCircle,
        route: Routes.adminSystemMessages,
      ),
      NavItem(
        title: 'System-Konfiguration',
        icon: LucideIcons.settings,
        route: Routes.adminSystemConfiguration,
      ),
      NavItem(
        title: 'Unified Ticket Managment',
        icon: LucideIcons.ticket,
        route: Routes.adminUnifiedTicketManagement,
      ),
      NavItem(
        title: 'Email Verification',
        icon: LucideIcons.mail,
        route: Routes.adminEmailVerification,
      ),
      NavItem(
        title: 'Gym Verwaltung',
        icon: LucideIcons.building2,
        route: Routes.adminGymManagement,
      ),
      NavItem(
        title: 'RBAC Managment',
        icon: LucideIcons.shield,
        route: Routes.adminRbacManagement,
      ),
      NavItem(
        title: 'Drucker Einstellungen',
        icon: LucideIcons.printer,
        route: Routes.adminPrinterSettings,
      ),
      NavItem(
        title: 'Scanner Einstellungen',
        icon: LucideIcons.camera,
        route: Routes.adminScannerSettings,
      ),
      NavItem(
        title: 'Dokumentenverwaltung',
        icon: LucideIcons.file,
        route: Routes.adminDocumentManagement,
      ),
      NavItem(
        title: 'Rollen & Permissions',
        icon: LucideIcons.shield,
        route: Routes.adminRolePermissions,
      ),
      NavItem(
        title: 'Benutzer-Status verwalten',
        icon: LucideIcons.userCog,
        route: Routes.adminUserStatusManagement,
      ),
      NavItem(
        title: 'New Staff Managment',
        icon: LucideIcons.userPlus,
        route: Routes.adminNewStaffManagement,
      ),
      NavItem(
        title: 'Staff Managment',
        icon: LucideIcons.users,
        route: Routes.adminStaffManagement,
      ),
      NavItem(
        title: 'New Staff',
        icon: LucideIcons.userPlus,
        route: Routes.adminNewStaff,
      ),
      NavItem(
        title: 'Preisgestaltung',
        icon: LucideIcons.euro,
        route: Routes.adminPricingManagement,
      ),
      NavItem(
        title: 'Abrechnungsmanagement',
        icon: LucideIcons.creditCard,
        route: Routes.adminBillingManagement,
      ),
      NavItem(
        title: 'Steuern',
        icon: LucideIcons.receipt,
        route: Routes.adminTaxClassManagement,
      ),
      NavItem(
        title: 'Ticket Managment',
        icon: LucideIcons.ticket,
        route: Routes.adminTicketTypeManagement,
      ),
      NavItem(
        title: 'Vertic Ticket Managment',
        icon: LucideIcons.ticketCheck,
        route: Routes.adminVerticTicketManagement,
      ),
      NavItem(
        title: 'Ticket Sichtbarkeit',
        icon: LucideIcons.eye,
        route: Routes.adminTicketVisibility,
      ),
      NavItem(
        title: 'QR-Code Rotation',
        icon: LucideIcons.qrCode,
        route: Routes.adminQrCodeRotation,
      ),
      NavItem(
        title: 'External Provider Managment',
        icon: LucideIcons.cloud,
        route: Routes.adminExternalProviderManagement,
      ),
      NavItem(
        title: 'DACH-Complianze',
        icon: LucideIcons.shield,
        route: Routes.adminDachCompliance,
      ),
      NavItem(
        title: 'Berichte & Analyse',
        icon: LucideIcons.chartLine,
        route: Routes.adminReportsAnalytics,
      ),
      NavItem(
        title: 'Backup & Wartung',
        icon: LucideIcons.database,
        route: Routes.adminBackup,
      ),
    ],
  ),
];

/// Account-Submenü Items für Footer-Bereich
final List<NavItem> accountNavItems = [
  NavItem(
    title: 'Mein Account',
    icon: LucideIcons.user,
    route: Routes.account,
    children: [
      NavItem(
        title: 'Profil',
        icon: LucideIcons.user,
        route: Routes.accountTabProfile,
      ),
      NavItem(
        title: 'Lohn und Schichten',
        icon: LucideIcons.calendar,
        route: Routes.accountTabShifts,
      ),
      NavItem(
        title: 'Berechtigungen',
        icon: LucideIcons.shield,
        route: Routes.accountTabPermissions,
      ),
      NavItem(
        title: 'Benachrichtigungen',
        icon: LucideIcons.bell,
        route: Routes.accountTabNotifications,
      ),
      NavItem(
        title: 'Sicherheit',
        icon: LucideIcons.lock,
        route: Routes.accountTabSecurity,
      ),
      NavItem(
        title: 'Einstellungen',
        icon: LucideIcons.settings,
        route: Routes.accountTabSettings,
      ),
    ],
  ),
];
