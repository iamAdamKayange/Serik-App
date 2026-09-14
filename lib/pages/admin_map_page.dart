import 'package:flutter/material.dart';
import 'package:serik/pages/google_maps_property_map_page.dart';

class AdminMapPage extends StatefulWidget {
  final dynamic newlyAddedHouse;

  const AdminMapPage({super.key, this.newlyAddedHouse});

  @override
  State<AdminMapPage> createState() => _AdminMapPageState();
}

class _AdminMapPageState extends State<AdminMapPage> {
  @override
  Widget build(BuildContext context) {
    // Use Google Maps property map for landlord
    return GoogleMapsPropertyMapPage.landlord();
  }
}
