// lib/pages/role_based_home_page.dart
// 🔥 Homepage inayoangalia role ya user

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serik/pages/admin_home_screen.dart';
import 'package:serik/pages/custom_map_page.dart';
import 'package:serik/pages/admin_map_page.dart';
import 'package:serik/pages/rental_home_page.dart';
import 'package:serik/providers/auth_provider.dart';

class RoleBasedHomePage extends StatelessWidget {
  const RoleBasedHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.userRole;

    // 🔥 ADMIN - Anaona admin dashboard kamili
    if (userRole == 'admin') {
      return const AdminHomeScreen();
    }

    // 🔥 LANDLORD - Anaona landlord dashboard
    if (userRole == 'landlord') {
      return const RentalHomePage();
    }

    // 🔥 BACKWARD COMPATIBILITY - default map view for power users
    if (userRole == 'landlord_map') {
      return const AdminMapPage();
    }

    // 🔥 NORMAL USER - Anaona Public Map (kutafuta nyumba)
    return const CustomMapPage();
  }
}
