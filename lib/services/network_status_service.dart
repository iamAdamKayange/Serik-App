import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:serkapp/services/api_services.dart';

class NetworkStatusService {
  NetworkStatusService._();

  static final NetworkStatusService instance = NetworkStatusService._();

  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);
  Timer? _timer;
  bool _checking = false;

  void start({Duration interval = const Duration(seconds: 20)}) {
    _timer ??= Timer.periodic(interval, (_) => checkNow());
    unawaited(checkNow());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> checkNow() async {
    if (_checking) return;
    _checking = true;
    try {
      final host = Uri.parse(ApiService.baseUrl).host;
      final result = await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 5));
      final online = result.isNotEmpty && result.first.rawAddress.isNotEmpty;
      if (isOnline.value != online) {
        isOnline.value = online;
      }
    } catch (_) {
      if (isOnline.value != false) {
        isOnline.value = false;
      }
    } finally {
      _checking = false;
    }
  }
}
