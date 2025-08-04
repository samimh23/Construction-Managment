import 'package:constructionproject/Construction/Core/Constants/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// Updated to handle ownerId and correct payloads for both manager and owner.

class ManagerLocation {
  final String managerId;
  final double latitude;
  final double longitude;
  final String? siteId;
  final String? timestamp;
  final String? ownerId;

  ManagerLocation({
    required this.managerId,
    required this.latitude,
    required this.longitude,
    this.siteId,
    this.timestamp,
    this.ownerId,
  });

  factory ManagerLocation.fromJson(Map<String, dynamic> json) {
    return ManagerLocation(
      managerId: json['managerId'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      siteId: json['siteId']?.toString(),
      timestamp: json['timestamp']?.toString(),
      ownerId: json['ownerId']?.toString(),
    );
  }
}

class ManagerLocationProvider extends ChangeNotifier {
  IO.Socket? _socket;
  final List<ManagerLocation> _managers = [];
  final List<VoidCallback> _onConnectedCallbacks = [];

  List<ManagerLocation> get managers => List.unmodifiable(_managers);

  void onConnected(VoidCallback callback) {
    _onConnectedCallbacks.add(callback);
  }

  /// Manager connect - used when manager is logged in (requires ownerId)
  void connectAsManager(String managerId, String siteId, String ownerId) {
    _baseConnect();
    // Optionally send initial location or wait for location update events
    // You may also send a dummy location if needed here
  }

  /// Owner connect - used when owner wants to listen for his managers
  void connectAsOwner() {
    _baseConnect();
    // Owner just listens, doesn't send location
  }

  void _baseConnect() {
    if (_socket != null && _socket!.connected) {
      for (final cb in _onConnectedCallbacks) cb();
      _onConnectedCallbacks.clear();
      return;
    }
    print('[SOCKET] Connecting to Socket.IO');
    _socket = IO.io(ApiConstants.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket!.onConnect((_) {
      print('[SOCKET] Connected to Socket.IO');
      for (final cb in _onConnectedCallbacks) cb();
      _onConnectedCallbacks.clear();
      notifyListeners();
    });

    _socket!.on('connectedManagers', (data) {
      print('[SOCKET] Received connectedManagers event: $data');
      _updateManagersFromSocketData(data);
    });

    _socket!.on('myManagersLocations', (data) {
      print('[SOCKET] Received myManagersLocations event: $data');
      _updateManagersFromSocketData(data);
    });

    _socket!.onDisconnect((_) {
      print('[SOCKET] Disconnected from Socket.IO');
      notifyListeners();
    });
  }

  void _updateManagersFromSocketData(dynamic data) {
    _managers.clear();
    if (data is List) {
      for (var item in data) {
        try {
          if (item is Map<String, dynamic>) {
            _managers.add(ManagerLocation.fromJson(item));
          } else if (item is Map) {
            _managers.add(ManagerLocation.fromJson(Map<String, dynamic>.from(item)));
          }
        } catch (e) {
          print('[SOCKET] Error parsing manager location: $e');
        }
      }
    }
    notifyListeners();
  }

  /// MANAGER: Send location (must include ownerId)
  void sendLocation({
    required String managerId,
    required String siteId,
    required double latitude,
    required double longitude,
    required String ownerId,
  }) {
    if (_socket == null || !_socket!.connected) {
      print('[SOCKET] Not connected. Cannot send location.');
      return;
    }
    final payload = {
      'managerId': managerId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().toIso8601String(),
      'siteId': siteId,
      'ownerId': ownerId,
    };
    _socket!.emit('managerLocation', payload);
  }

  /// OWNER: Request all my managers' locations by sending only ownerId
  void requestManagersForOwner(String ownerId) {
    if (_socket == null || !_socket!.connected) {
      print('[SOCKET] Not connected. Cannot request managers.');
      return;
    }
    print('[SOCKET] Requesting managers for owner: $ownerId');
    _socket!.emit('getMyManagersLocations', ownerId);
  }

  @override
  void dispose() {
    print('[SOCKET] Disconnecting from Socket.IO');
    _socket?.disconnect();
    _socket = null;
    super.dispose();
  }
}