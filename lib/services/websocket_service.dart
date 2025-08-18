import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:latlong2/latlong.dart';
import '../models/device.dart';

class WebSocketService {
  io.Socket? _socket;
  bool _isConnected = false;

  // Callbacks
  Function(String)? onConnectionStatusChanged;
  Function(Device)? onDeviceUpdate;
  Function(String)? onError;
  Function(String, List<Map<String, dynamic>>)? onLocationHistoryBatch;

  bool get isConnected => _isConnected;

  void connect(String url) {
    try {
      // Parse the ngrok URL
      String baseUrl = url;
      if (baseUrl.startsWith('wss://')) {
        baseUrl = baseUrl.replaceFirst('wss://', 'https://');
      }
      if (baseUrl.startsWith('ws://')) {
        baseUrl = baseUrl.replaceFirst('ws://', 'http://');
      }

      // Remove query parameters for base URL
      if (baseUrl.contains('?')) {
        baseUrl = baseUrl.split('?')[0];
      }

      // Remove /socket.io/ path if it exists in the URL
      if (baseUrl.endsWith('/socket.io/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 10);
      }

      print('Connecting to WebSocket: $baseUrl');

      _socket = io.io(baseUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'forceNew': true,
        'path': '/socket.io/',
        'timeout': 20000, // 20 saniye timeout
      });

      _socket!.onConnect((_) {
        print('WebSocket Connected!');
        _isConnected = true;
        onConnectionStatusChanged?.call('Connected');

        // Bağlantı kurulduktan sonra geçmiş verileri iste
        print('WebSocket connected, requesting location history...');
        _requestLocationHistory();
      });

      _socket!.onDisconnect((_) {
        print('WebSocket Disconnected!');
        _isConnected = false;
        onConnectionStatusChanged?.call('Disconnected');
      });

      _socket!.onError((error) {
        print('WebSocket Error: $error');
        _isConnected = false;
        onError?.call('Socket.IO Error: $error');
        onConnectionStatusChanged?.call('Error: $error');
      });

      _socket!.onConnectError((error) {
        print('WebSocket Connect Error: $error');
        onError?.call('Connect Error: $error');
      });

      // Listen for location updates from backend
      _socket!.on('location', (data) {
        try {
          final device = _convertLocationToDevice(data);
          onDeviceUpdate?.call(device);
        } catch (e) {
          onError?.call('Device parsing error: $e');
        }
      });

      // Listen for location history from backend
      _socket!.on('location_history', (data) {
        try {
          print('Received location history: $data');
          // Bu event'i DeviceProvider'a ilet - geçmiş veriler için
          onDeviceUpdate?.call(_convertLocationHistoryToDevice(data));
        } catch (e) {
          onError?.call('Location history parsing error: $e');
        }
      });

      // Listen for location history batch from backend (tüm geçmiş veriler)
      _socket!.on('location_history_batch', (data) {
        try {
          print('Received location history batch: ${data.length} records');
          // Tüm geçmiş verileri DeviceProvider'a ilet
          _processLocationHistoryBatch(data);
        } catch (e) {
          onError?.call('Location history batch parsing error: $e');
        }
      });

      _socket!.connect();
    } catch (e) {
      onError?.call('Connection error: $e');
      onConnectionStatusChanged?.call('Connection failed');
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _isConnected = false;
    onConnectionStatusChanged?.call('Disconnected');
  }

  void sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _socket != null) {
      _socket!.emit('message', message);
    }
  }

  void _requestLocationHistory() {
    if (_isConnected && _socket != null) {
      print('Requesting location history from backend...');
      _socket!.emit('get_location_history', {
        'request': 'location_history',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  void _processLocationHistoryBatch(dynamic data) {
    try {
      if (data is List) {
        print('Processing ${data.length} location history records');

        // Her cihaz için geçmiş verileri grupla
        final Map<String, List<Map<String, dynamic>>> deviceHistoryMap = {};

        for (final record in data) {
          if (record is Map<String, dynamic>) {
            final deviceId = record['device_id'] ?? 'unknown';
            if (!deviceHistoryMap.containsKey(deviceId)) {
              deviceHistoryMap[deviceId] = [];
            }
            deviceHistoryMap[deviceId]!.add(record);
          }
        }

        // Her cihaz için geçmiş verileri DeviceProvider'a gönder
        for (final entry in deviceHistoryMap.entries) {
          final deviceId = entry.key;
          final historyRecords = entry.value;

          // DeviceProvider'a geçmiş verileri gönder
          onLocationHistoryBatch?.call(deviceId, historyRecords);
        }
      }
    } catch (e) {
      print('Error processing location history batch: $e');
    }
  }

  Device _convertLocationHistoryToDevice(dynamic data) {
    // Geçmiş veri formatını Device'a çevir
    // Bu metod backend'den gelen geçmiş veri formatına göre ayarlanmalı
    try {
      if (data is Map<String, dynamic>) {
        return Device(
          id: data['device_id'] ?? 'unknown',
          name: data['device_name'] ?? '',
          currentLocation: LatLng(
            data['latitude']?.toDouble() ?? 0.0,
            data['longitude']?.toDouble() ?? 0.0,
          ),
          lastUpdate: DateTime.parse(
            data['timestamp'] ?? DateTime.now().toIso8601String(),
          ),
          isOnline: data['is_online'] ?? false,
          status: data['status'] ?? 'unknown',
        );
      }
    } catch (e) {
      print('Error converting location history data: $e');
    }

    // Hata durumunda varsayılan device döndür
    return Device(
      id: 'unknown',
      name: 'Unknown Device',
      currentLocation: const LatLng(0, 0),
      lastUpdate: DateTime.now(),
      isOnline: false,
      status: 'unknown',
    );
  }

  // Convert backend location data to Device model
  Device _convertLocationToDevice(Map<String, dynamic> locationData) {
    final parsedTimestamp = _parseTimestamp(locationData['ts']);

    return Device(
      id: locationData['deviceId'] ?? 'unknown',
      name: '', // Boş isim - DeviceProvider'da mevcut isim korunacak
      currentLocation: LatLng(
        (locationData['lat'] ?? 0.0).toDouble(),
        (locationData['lng'] ?? 0.0).toDouble(),
      ),
      lastUpdate: parsedTimestamp,
      isOnline: true,
      status: 'Online',
    );
  }

  // Parse timestamp from various formats
  DateTime _parseTimestamp(dynamic ts) {
    if (ts == null) {
      return DateTime.now();
    }

    try {
      // Eğer string ise
      if (ts is String) {
        // ISO 8601 format (2024-01-15T10:30:00.000Z) - UTC timestamp
        if (ts.contains('T') || ts.contains('Z')) {
          // UTC timestamp'i parse et ve local timezone'a çevir
          final utcDateTime = DateTime.parse(ts);

          // UTC'den local timezone'a çevir
          final localDateTime = utcDateTime.toLocal();
          return localDateTime;
        }

        // Unix timestamp string (1705312200)
        if (RegExp(r'^\d{10,13}$').hasMatch(ts)) {
          final timestamp = int.parse(ts);
          // 13 haneli ise milisaniye, 10 haneli ise saniye
          if (timestamp > 9999999999) {
            return DateTime.fromMillisecondsSinceEpoch(
              timestamp,
              isUtc: true,
            ).toLocal();
          } else {
            return DateTime.fromMillisecondsSinceEpoch(
              timestamp * 1000,
              isUtc: true,
            ).toLocal();
          }
        }

        // Diğer string formatları
        return DateTime.parse(ts);
      }

      // Eğer number ise (Unix timestamp)
      if (ts is num) {
        final timestamp = ts.toInt();
        if (timestamp > 9999999999) {
          return DateTime.fromMillisecondsSinceEpoch(
            timestamp,
            isUtc: true,
          ).toLocal();
        } else {
          return DateTime.fromMillisecondsSinceEpoch(
            timestamp * 1000,
            isUtc: true,
          ).toLocal();
        }
      }

      // Eğer int ise
      if (ts is int) {
        if (ts > 9999999999) {
          return DateTime.fromMillisecondsSinceEpoch(ts, isUtc: true).toLocal();
        } else {
          return DateTime.fromMillisecondsSinceEpoch(
            ts * 1000,
            isUtc: true,
          ).toLocal();
        }
      }

      // Hiçbiri değilse şu anki zaman
      return DateTime.now();
    } catch (e) {
      // Timestamp parse hatası - şu anki zamanı döndür
      return DateTime.now();
    }
  }
}
