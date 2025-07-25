// vertic_staff_app/lib/widgets/navigation/nav_models.dart

import 'package:flutter/material.dart';

class NavItem {
  final String title;
  final IconData icon;
  final String? route;
  final List<NavItem> children;
  final String? parentTitle; // For showing parent context in search results

  const NavItem({
    required this.title,
    required this.icon,
    this.route,
    this.children = const [],
    this.parentTitle,
  });
}
