import 'package:flutter/material.dart';
import 'package:serkapp/services/api_services.dart';
import 'package:serkapp/services/notification_service.dart';

class SavedHouseButton extends StatefulWidget {
  const SavedHouseButton({super.key, required this.houseId});

  final String houseId;

  @override
  State<SavedHouseButton> createState() => _SavedHouseButtonState();
}

class _SavedHouseButtonState extends State<SavedHouseButton> {
  String? _token;
  bool _saved = false;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = await NotificationService.instance.getDeviceToken();
    if (!mounted) return;
    if (token == null) {
      setState(() => _loading = false);
      return;
    }

    final saved = await ApiService.isHouseSaved(
      token: token,
      houseId: widget.houseId,
    );
    if (!mounted) return;
    setState(() {
      _token = token;
      _saved = saved;
      _loading = false;
    });
  }

  Future<void> _toggle() async {
    final token = _token;
    if (token == null || _busy) return;

    setState(() => _busy = true);
    final ok = _saved
        ? await ApiService.removeSavedHouse(
            token: token,
            houseId: widget.houseId,
          )
        : await ApiService.saveHouseForAlerts(
            token: token,
            houseId: widget.houseId,
          );

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
