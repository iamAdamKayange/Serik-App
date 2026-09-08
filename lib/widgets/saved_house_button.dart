import 'package:flutter/material.dart';
import 'package:serik/services/api_services.dart';

class SavedHouseButton extends StatefulWidget {
  const SavedHouseButton({super.key, required this.houseId});

  final String houseId;

  @override
  State<SavedHouseButton> createState() => _SavedHouseButtonState();
}

class _SavedHouseButtonState extends State<SavedHouseButton> {
  bool _saved = false;
  bool _loading = true;
  bool _busy = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _token = await ApiService.getToken();
    final saved = await ApiService.isHouseSaved(houseId: widget.houseId);
    if (!mounted) return;
    setState(() {
      _saved = saved;
      _loading = false;
    });
  }

  Future<void> _toggle() async {
    if (_busy) return;

    setState(() => _busy = true);
    final ok = _saved
        ? await ApiService.removeSavedHouse(houseId: widget.houseId)
        : await ApiService.saveHouseForAlerts(houseId: widget.houseId);

    if (!mounted) return;
    setState(() {
      if (ok) _saved = !_saved;
      _busy = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (_saved ? 'Nyumba imehifadhiwa.' : 'Nyumba imeondolewa.')
              : 'Imeshindikana kubadilisha saved house.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return IconButton(
      tooltip: _saved ? 'Ondoa saved' : 'Hifadhi nyumba',
      onPressed: _token == null || _busy ? null : _toggle,
      icon: Icon(_saved ? Icons.bookmark_rounded : Icons.bookmark_border),
    );
  }
}
