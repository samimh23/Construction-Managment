import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ManagerLocation {
  final String managerId;
  final double latitude;
  final double longitude;
  final String? siteId;
  final String? timestamp;

  ManagerLocation({
    required this.managerId,
    required this.latitude,
    required this.longitude,
    this.siteId,
    this.timestamp,
  });

  factory ManagerLocation.fromJson(Map<String, dynamic> json) {
    return ManagerLocation(
      managerId: json['managerId'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      siteId: json['siteId']?.toString(),
      timestamp: json['timestamp']?.toString(),
    );
  }
}

class ManagerLocationProvider extends ChangeNotifier {
  IO.Socket? _socket;
  final List<ManagerLocation> _managers = [];

  List<ManagerLocation> get managers => List.unmodifiable(_managers);

  void connect(String managerId, String siteId) {
    if (_socket != null && _socket!.connected) return;
    print('[SOCKET] Connecting to Socket.IO as $managerId for site $siteId');
    _socket = IO.io('http://localhost:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket!.onConnect((_) {
      print('[SOCKET] Connected to Socket.IO');
      // If your backend expects a join event, emit it here
      // _socket!.emit('ownerJoin', {'role': 'owner'});
      notifyListeners();
    });

    // Listen for both possible event names!
    _socket!.on('connectedManagers', (data) {
      print('[SOCKET] Received connectedManagers event: $data');
      _updateManagersFromSocketData(data);
    });

    _socket!.on('managers', (data) {
      print('[SOCKET] Received managers event: $data');
      // If the data is { managers: [...] }
      if (data is Map && data['managers'] is List) {
        _updateManagersFromSocketData(data['managers']);
      } else {
        _updateManagersFromSocketData(data);
      }
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
            print('[SOCKET] Manager location from server: $item');
            _managers.add(ManagerLocation.fromJson(item));
          } else if (item is Map) {
            print('[SOCKET] Manager location from server (force cast): $item');
            _managers.add(ManagerLocation.fromJson(Map<String, dynamic>.from(item)));
          }
        } catch (e) {
          print('[SOCKET] Error parsing manager location: $e');
        }
      }
    }
    print('[SOCKET] Manager locations count after update: ${_managers.length}');
    notifyListeners();
  }

  void sendLocation({
    required String managerId,
    required String siteId,
    required double latitude,
    required double longitude,
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
    };
    print('[SOCKET] Sending managerLocation: $payload');
    _socket!.emit('managerLocation', payload);
  }

  @override
  void dispose() {
    print('[SOCKET] Disconnecting from Socket.IO');
    _socket?.disconnect();
    _socket = null;
    super.dispose();
  }
}