// lib/widgets/advanced_location_picker.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/csv_location_service.dart';

class AdvancedLocationPicker extends StatefulWidget {
  final Function(
    String fullAddress,
    String region,
    String district,
    String division, // 🆕 Tarafa
    String ward,
    String village, // 🆕 Kijiji
    String street,
  )
  onLocationSelected;

  final String? initialRegion;
  final String? initialDistrict;
  final String? initialDivision; // 🆕
  final String? initialWard;
  final String? initialVillage; // 🆕
  final String? initialStreet;

  const AdvancedLocationPicker({
    super.key,
    required this.onLocationSelected,
    this.initialRegion,
    this.initialDistrict,
    this.initialDivision,
    this.initialWard,
    this.initialVillage,
    this.initialStreet,
  });

  @override
  State<AdvancedLocationPicker> createState() => _AdvancedLocationPickerState();
}

class _AdvancedLocationPickerState extends State<AdvancedLocationPicker> {
  String? _selectedRegion;
  String? _selectedDistrict;
  String? _selectedDivision; // 🆕 Tarafa
  String? _selectedWard;
  String? _selectedVillage; // 🆕 Kijiji
  String? _selectedStreet;

  List<String> _availableDistricts = [];
  List<String> _availableDivisions = []; // 🆕
  List<String> _availableWards = [];
  List<String> _availableVillages = []; // 🆕
  List<String> _availableStreets = [];

  // For manual input
  final TextEditingController _manualStreetController = TextEditingController();
  final TextEditingController _manualVillageController =
      TextEditingController();
  bool _isManualStreet = false;
  bool _isManualVillage = false;

  @override
  void initState() {
    super.initState();
    _selectedRegion = widget.initialRegion;
    _selectedDistrict = widget.initialDistrict;
    _selectedDivision = widget.initialDivision;
    _selectedWard = widget.initialWard;
    _selectedVillage = widget.initialVillage;
    _selectedStreet = widget.initialStreet;

    _updateDistricts();
    _updateDivisions();
    _updateWards();
    _updateVillages();
    _updateStreets();
  }

  void _updateDistricts() {
    if (_selectedRegion != null && _selectedRegion!.isNotEmpty) {
      _availableDistricts = CsvLocationService.getDistricts(_selectedRegion!);
    } else {
      _availableDistricts = [];
    }
  }

  void _updateDivisions() {
    if (_selectedRegion != null &&
        _selectedDistrict != null &&
        _selectedDistrict!.isNotEmpty) {
      _availableDivisions = CsvLocationService.getDivisions(
        _selectedRegion!,
        _selectedDistrict!,
      );
    } else {
      _availableDivisions = [];
    }
  }

  void _updateWards() {
    if (_selectedRegion != null &&
        _selectedDistrict != null &&
        _selectedDistrict!.isNotEmpty) {
      // If division is selected, get wards for that division
      if (_selectedDivision != null &&
          _selectedDivision!.isNotEmpty &&
          _selectedDivision != 'Hakuna Tarafa') {
        _availableWards = CsvLocationService.getWardsByDivision(
          _selectedRegion!,
          _selectedDistrict!,
          _selectedDivision!,
        );
      } else {
        // Otherwise get wards for the district
        _availableWards = CsvLocationService.getWards(
          _selectedRegion!,
          _selectedDistrict!,
        );
      }
    } else {
      _availableWards = [];
    }
  }

  void _updateVillages() {
    if (_selectedRegion != null &&
        _selectedDistrict != null &&
        _selectedWard != null &&
        _selectedWard!.isNotEmpty) {
      _availableVillages = CsvLocationService.getVillages(
        _selectedRegion!,
        _selectedDistrict!,
        _selectedWard!,
      );
    } else {
      _availableVillages = [];
    }
  }

  void _updateStreets() {
    if (_selectedRegion != null &&
        _selectedDistrict != null &&
        _selectedWard != null &&
        _selectedWard!.isNotEmpty) {
      _availableStreets = CsvLocationService.getStreets(
        _selectedRegion!,
        _selectedDistrict!,
        _selectedWard!,
      );
    } else {
      _availableStreets = [];
    }
  }

  void _notifySelection() {
    // Get street value from manual input if needed
    String finalStreet = _selectedStreet ?? '';
    if (_isManualStreet && _manualStreetController.text.isNotEmpty) {
      finalStreet = _manualStreetController.text;
    }

    // Get village value from manual input if needed
    String finalVillage = _selectedVillage ?? '';
    if (_isManualVillage && _manualVillageController.text.isNotEmpty) {
      finalVillage = _manualVillageController.text;
    }

    final fullAddress = CsvLocationService.getFullAddress(
      _selectedRegion ?? '',
      _selectedDistrict ?? '',
      _selectedDivision ?? '',
      _selectedWard ?? '',
      finalVillage,
      finalStreet,
    );

    widget.onLocationSelected(
      fullAddress,
      _selectedRegion ?? '',
      _selectedDistrict ?? '',
      _selectedDivision ?? '',
      _selectedWard ?? '',
      finalVillage,
      finalStreet,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!CsvLocationService.isLoaded()) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Inapakia data za mikoa...'),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ========== MKOA (REGION) ==========
        _buildDropdown(
          label: 'Mkoa',
          hint: 'Chagua Mkoa',
          icon: Icons.map_rounded,
          value: _selectedRegion,
          items: CsvLocationService.getRegions(),
          onChanged: (value) {
            setState(() {
              _selectedRegion = value;
              _selectedDistrict = null;
              _selectedDivision = null;
              _selectedWard = null;
              _selectedVillage = null;
              _selectedStreet = null;
              _isManualVillage = false;
              _isManualStreet = false;
              _manualVillageController.clear();
              _manualStreetController.clear();

              _updateDistricts();
              _availableDivisions = [];
              _availableWards = [];
              _availableVillages = [];
              _availableStreets = [];
            });
            _notifySelection();
          },
        ),

        const SizedBox(height: 16),

        // ========== WILAYA (DISTRICT) ==========
        if (_selectedRegion != null && _selectedRegion!.isNotEmpty)
          _buildDropdown(
            label: 'Wilaya',
            hint: 'Chagua Wilaya',
            icon: Icons.location_city_rounded,
            value: _selectedDistrict,
            items: _availableDistricts,
            onChanged: (value) {
              setState(() {
                _selectedDistrict = value;
                _selectedDivision = null;
                _selectedWard = null;
                _selectedVillage = null;
                _selectedStreet = null;
                _isManualVillage = false;
                _isManualStreet = false;
                _manualVillageController.clear();
                _manualStreetController.clear();

                _updateDivisions();
                _availableWards = [];
                _availableVillages = [];
                _availableStreets = [];
              });
              _notifySelection();
            },
          ),

        const SizedBox(height: 16),

        // ========== TARAFA (DIVISION) - OPTIONAL ==========
        if (_selectedDistrict != null &&
            _selectedDistrict!.isNotEmpty &&
            _availableDivisions.isNotEmpty)
          _buildDropdown(
            label: 'Tarafa',
            hint: 'Chagua Tarafa (Si lazima)',
            icon: Icons.merge_type_rounded,
            value: _selectedDivision,
            items: ['Hakuna Tarafa', ..._availableDivisions],
            onChanged: (value) {
              setState(() {
                _selectedDivision = value;
                _selectedWard = null;
                _selectedVillage = null;
                _selectedStreet = null;
                _isManualVillage = false;
                _isManualStreet = false;
                _manualVillageController.clear();
                _manualStreetController.clear();

                _updateWards();
                _availableVillages = [];
                _availableStreets = [];
              });
              _notifySelection();
            },
            isOptional: true,
          ),

        const SizedBox(height: 16),

        // ========== KATA (WARD) ==========
        if (_selectedDistrict != null &&
            _selectedDistrict!.isNotEmpty &&
            _availableWards.isNotEmpty)
          _buildDropdown(
            label: 'Kata / Shehia',
            hint: 'Chagua Kata',
            icon: Icons.streetview_rounded,
            value: _selectedWard,
            items: _availableWards,
            onChanged: (value) {
              setState(() {
                _selectedWard = value;
                _selectedVillage = null;
                _selectedStreet = null;
                _isManualVillage = false;
                _isManualStreet = false;
                _manualVillageController.clear();
                _manualStreetController.clear();

                _updateVillages();
                _updateStreets();
              });
              _notifySelection();
            },
          ),

        const SizedBox(height: 16),

        // ========== KIJIJI (VILLAGE) - OPTIONAL ==========
        if (_selectedWard != null && _selectedWard!.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_availableVillages.isNotEmpty)
                _buildDropdown(
                  label: 'Kijiji',
                  hint: 'Chagua Kijiji (Si lazima)',
                  icon: FontAwesomeIcons.house,
                  value: _selectedVillage,
                  items: ['Hakuna Kijiji', ..._availableVillages],
                  onChanged: (value) {
                    setState(() {
                      if (value == 'Jaza mwenyewe') {
                        _isManualVillage = true;
                        _selectedVillage = null;
                      } else {
                        _isManualVillage = false;
                        _selectedVillage = value;
                      }
                      _selectedStreet = null;
                      _isManualStreet = false;
                      _manualStreetController.clear();
                    });
                    _updateStreets();
                    _notifySelection();
                  },
                  isOptional: true,
                ),

              // Manual village input
              if (_isManualVillage || _availableVillages.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextFormField(
                    controller: _manualVillageController,
                    decoration: InputDecoration(
                      labelText: 'Jina la Kijiji (Jaza mwenyewe)',
                      hintText: 'Mfano: Kijiji cha Kilimo',
                      prefixIcon: FaIcon(
                        FontAwesomeIcons.locationDot,
                        color: const Color(0xFF2E7D32),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onChanged: (value) {
                      _selectedVillage = value;
                      _notifySelection();
                    },
                  ),
                ),
            ],
          ),

        const SizedBox(height: 16),

        // ========== MTAA (STREET) ==========
        if (_selectedWard != null && _selectedWard!.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_availableStreets.isNotEmpty)
                _buildDropdown(
                  label: 'Mtaa / Barabara',
                  hint: 'Chagua Mtaa',
                  icon: FontAwesomeIcons.road,
                  value: _selectedStreet,
                  items: _availableStreets,
                  onChanged: (value) {
                    setState(() {
                      if (value == 'Jaza mwenyewe') {
                        _isManualStreet = true;
                        _selectedStreet = null;
                      } else {
                        _isManualStreet = false;
                        _selectedStreet = value;
                      }
                    });
                    _notifySelection();
                  },
                ),

              // Manual street input
              if (_isManualStreet || _availableStreets.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextFormField(
                    controller: _manualStreetController,
                    decoration: InputDecoration(
                      labelText: 'Jina la Mtaa / Barabara *',
                      hintText: 'Mfano: Mtaa wa Uhuru, Barabara ya Kilimo',
                      prefixIcon: FaIcon(
                        FontAwesomeIcons.route,
                        color: Color(0xFF2E7D32),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      helperText: '* Muhimu - Tafadhali weka jina la mtaa',
                    ),
                    onChanged: (value) {
                      _selectedStreet = value;
                      _notifySelection();
                    },
                  ),
                ),
            ],
          ),

        const SizedBox(height: 16),

        // ========== PREVIEW YA ANWANI ==========
        if (_selectedRegion != null && _selectedRegion!.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Anwani Kamili:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.green[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CsvLocationService.getFullAddress(
                          _selectedRegion ?? '',
                          _selectedDistrict ?? '',
                          _selectedDivision ?? '',
                          _selectedWard ?? '',
                          (_isManualVillage
                                  ? _manualVillageController.text
                                  : _selectedVillage) ??
                              '',
                          (_isManualStreet
                                  ? _manualStreetController.text
                                  : _selectedStreet) ??
                              '',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ✅ Widget ya dropdown inayojenga Icon na FontAwesome kwa usahihi
  Widget _buildDropdown<T>({
    required String label,
    required String hint,
    required Object icon, // Inaweza kuwa IconData au FaIconData
    required T? value,
    required List<T> items,
    required Function(T?) onChanged,
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
            if (isOptional)
              Text(
                ' (Si lazima)',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<T>(
            initialValue: value != null && items.contains(value) ? value : null,
            isExpanded: true,
            hint: Text(hint),
            decoration: InputDecoration(
              labelText: label,
              // ✅ Muhimu: Inaweza kubeba Icon na FontAwesome
              prefixIcon: icon is IconData
                  ? Icon(icon, color: const Color(0xFF2E7D32))
                  : FaIcon(
                      icon as FaIconData,
                      color: const Color(0xFF2E7D32),
                      size: 20,
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2E7D32),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            items: [
              DropdownMenuItem<T>(value: null, child: Text('-- $hint --')),
              ...items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item.toString()),
                );
              }),
            ],
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _manualStreetController.dispose();
    _manualVillageController.dispose();
    super.dispose();
  }
}
