import 'package:flutter/material.dart';
import 'package:serkapp/l10n/app_localization.dart';
import 'package:serkapp/services/api_services.dart';
import 'package:serkapp/services/notification_service.dart';

class SmartAlertSettingsPage extends StatefulWidget {
  const SmartAlertSettingsPage({super.key});

  @override
  State<SmartAlertSettingsPage> createState() => _SmartAlertSettingsPageState();
}

class _SmartAlertSettingsPageState extends State<SmartAlertSettingsPage> {
  static const _houseTypes = [
    'Nyumba ya Kawaida',
    'Apartment',
    'Single Room',
    'Bedsitter',
    'Studio',
  ];

  final _regionsController = TextEditingController();
  final _districtsController = TextEditingController();
  final _minRentController = TextEditingController();
  final _maxRentController = TextEditingController();

  String? _token;
  bool _enabled = false;
  bool _loading = true;
  bool _saving = false;
  final Set<String> _selectedTypes = {};

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _regionsController.dispose();
    _districtsController.dispose();
    _minRentController.dispose();
    _maxRentController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final token = await NotificationService.instance.getDeviceToken();
    if (!mounted) return;
    if (token == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    final prefs = await ApiService.getSmartAlertPreferences(token: token);
    if (!mounted) return;
    setState(() {
      _token = token;
      _enabled = prefs?['enabled'] == true;
      _regionsController.text = _joinList(prefs?['regions']);
      _districtsController.text = _joinList(prefs?['districts']);
      _minRentController.text = prefs?['minRent']?.toString() ?? '';
      _maxRentController.text = prefs?['maxRent']?.toString() ?? '';
      _selectedTypes
        ..clear()
        ..addAll(_stringList(prefs?['houseTypes']));
      _loading = false;
    });
  }

  Future<void> _save() async {
    final token = _token;
    if (token == null || _saving) return;

    setState(() => _saving = true);
    final ok = await ApiService.saveSmartAlertPreferences(
      token: token,
      enabled: _enabled,
      regions: _splitList(_regionsController.text),
      districts: _splitList(_districtsController.text),
      houseTypes: _selectedTypes.toList(),
      minRent: _parseMoney(_minRentController.text),
      maxRent: _parseMoney(_maxRentController.text),
    );
    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Smart alerts zimehifadhiwa.'
              : 'Imeshindikana kuhifadhi smart alerts.',
        ),
      ),
    );
    if (ok) Navigator.pop(context);
  }

  static List<String> _splitList(String value) => value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();

  static List<String> _stringList(dynamic value) {
    if (value is! List) return [];
    return value.map((item) => item.toString()).toList();
  }

  static String _joinList(dynamic value) => _stringList(value).join(', ');

  static double? _parseMoney(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('Smart alerts', en: 'Smart alerts')),
        actions: [
          TextButton(
            onPressed: _saving || _loading ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.tr('Hifadhi', en: 'Save')),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _token == null
              ? _MissingTokenState(colors: colors)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  children: [
                    SwitchListTile(
                      value: _enabled,
                      onChanged: (value) => setState(() => _enabled = value),
                      title: Text(
                        l10n.tr(
                          'Pokea alert za nyumba zinazokufaa',
                          en: 'Receive alerts for matching houses',
                        ),
                      ),
                      subtitle: Text(
                        l10n.tr(
                          'Tutakutumia notification nyumba mpya ikilingana na vigezo hivi.',
                          en: 'We will notify you when a new house matches these filters.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _TextSection(
                      controller: _regionsController,
                      label: l10n.tr('Mikoa', en: 'Regions'),
                      hint: 'Dar es Salaam, Dodoma',
                      icon: Icons.map_outlined,
                    ),
                    const SizedBox(height: 12),
                    _TextSection(
                      controller: _districtsController,
                      label: l10n.tr('Wilaya', en: 'Districts'),
                      hint: 'Kinondoni, Ilala',
                      icon: Icons.location_city_outlined,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _TextSection(
                            controller: _minRentController,
                            label: l10n.tr('Bei ya chini', en: 'Min rent'),
                            hint: '50000',
                            icon: Icons.price_check_rounded,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TextSection(
                            controller: _maxRentController,
                            label: l10n.tr('Bei ya juu', en: 'Max rent'),
                            hint: '250000',
                            icon: Icons.payments_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l10n.tr('Aina ya nyumba', en: 'House type'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _houseTypes.map((type) {
                        final selected = _selectedTypes.contains(type);
                        return FilterChip(
                          selected: selected,
                          label: Text(type),
                          onSelected: (value) {
                            setState(() {
                              if (value) {
                                _selectedTypes.add(type);
                              } else {
                                _selectedTypes.remove(type);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n.tr(
                        'Ukiiacha sehemu tupu, haitatumika kuchuja matokeo.',
                        en: 'Empty fields are ignored when matching houses.',
                      ),
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _TextSection extends StatelessWidget {
  const _TextSection({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _MissingTokenState extends StatelessWidget {
  const _MissingTokenState({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_paused_outlined,
              size: 54,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            const Text(
              'Token ya notification haijapatikana. Hakikisha umeipa app ruhusa ya notifications kisha jaribu tena.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
