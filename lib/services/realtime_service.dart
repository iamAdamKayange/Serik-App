import 'package:flutter/foundation.dart';
import 'package:serkapp/services/api_services.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

typedef RealtimeCallback = void Function(dynamic data);

class RealtimeService {
  RealtimeService._();

  static final RealtimeService instance = RealtimeService._();

  io.Socket? _socket;
  bool _isConnecting = false;

  bool get isConnected => _socket?.connected ?? false;

  void connect() {
    if (_socket != null || _isConnecting) return;

    _isConnecting = true;
    _socket = io.io(
      ApiService.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableReconnection()
          .setReconnectionAttempts(999)
          .setReconnectionDelay(1200)
          .disableAutoConnect()
          .build(),
    );

    _socket!
      ..onConnect((_) {
        _isConnecting = false;
        debugPrint('Socket connected: ${_socket?.id}');
      })
      ..onDisconnect((reason) {
        debugPrint('Socket disconnected: $reason');
      })
      ..onConnectError((error) {
        _isConnecting = false;
        debugPrint('Socket connect error: $error');
      })
      ..onError((error) {
        debugPrint('Socket error: $error');
      })
      ..connect();
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _isConnecting = false;
  }

  void joinLandlord(String? landlordId) {
    if (landlordId == null || landlordId.isEmpty) return;
    connect();
    _socket?.emit('join:landlord', landlordId);
  }

  void leaveLandlord(String? landlordId) {
    if (landlordId == null || landlordId.isEmpty) return;
    _socket?.emit('leave:landlord', landlordId);
  }

  void on(String event, RealtimeCallback callback) {
    connect();
    _socket?.on(event, callback);
  }

  void emit(String event, [dynamic data]) {
    connect();
    _socket?.emit(event, data);
  }

  void off(String event, [RealtimeCallback? callback]) {
    if (callback == null) {
      _socket?.off(event);
    } else {
      _socket?.off(event, callback);
    }
  }
}
