// lib/pages/role_based_home_page.dart
// 🔥 Homepage inayoangalia role ya user

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serkapp/pages/custom_map_page.dart';
import 'package:serkapp/pages/admin_map_page.dart';
import 'package:serkapp/providers/auth_provider.dart';

class RoleBasedHomePage extends StatelessWidget {
  const RoleBasedHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.userRole;

    // 🔥 LANDLORD - Anaona Admin Map (nyumba zake)
    if (userRole == 'landlord' || userRole == 'admin') {
      return const AdminMapPage();
    }

    // 🔥 NORMAL USER - Anaona Public Map (kutafuta nyumba)
    return const CustomMapPage();
  }
}
