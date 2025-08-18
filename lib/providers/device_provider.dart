import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';
import '../models/device.dart';
import '../models/location_history.dart';
import '../services/websocket_service.dart';

class DeviceProvider with ChangeNotifier {
  final WebSocketService _webSocketService = WebSocketService();

  final List<Device> _devices = [];
  final Map<String, List<LocationHistory>> _locationHistory = {};
  bool _isConnected = false;
  String _connectionStatus = 'Disconnected';

  List<Device> get devices => _devices;
  bool get isConnected => _isConnected;
  String get connectionStatus => _connectionStatus;

  DeviceProvider() {
    _setupWebSocketCallbacks();
    // _loadMockData(); // Test için mock data - KALDIRILDI
  }

  void _setupWebSocketCallbacks() {
    _webSocketService.onDeviceUpdate = (device) {
      _updateDevice(device);
    };

    _webSocketService.onConnectionStatusChanged = (status) {
      _connectionStatus = status;
      _isConnected = status == 'Connected';
      notifyListeners();
    };

    _webSocketService.onError = (error) {
      // WebSocket hatası loglanabilir
    };

    _webSocketService.onLocationHistoryBatch = (deviceId, historyRecords) {
      _processLocationHistoryBatch(deviceId, historyRecords);
    };
  }

  void connectToWebSocket(String url) {
    _webSocketService.connect(url);
  }

  void disconnectFromWebSocket() {
    _webSocketService.disconnect();
  }

  void _updateDevice(Device updatedDevice) {
    final index = _devices.indexWhere((d) => d.id == updatedDevice.id);

    if (index != -1) {
      // Mevcut cihazın ismini koru, sadece konum ve durum bilgilerini güncelle
      final existingDevice = _devices[index];
      final updatedDeviceWithPreservedName = updatedDevice.copyWith(
        name: existingDevice.name, // Mevcut ismi koru
      );
      _devices[index] = updatedDeviceWithPreservedName;
    } else {
      // Yeni cihaz için varsayılan isim ata
      final deviceWithDefaultName = updatedDevice.copyWith(
        name: 'Cihaz ${updatedDevice.id}',
      );
      _devices.add(deviceWithDefaultName);
    }

    // Konum geçmişine ekle
    _addToLocationHistory(updatedDevice);

    notifyListeners();
  }

  void _addToLocationHistory(Device device) {
    if (!_locationHistory.containsKey(device.id)) {
      _locationHistory[device.id] = [];
    }

    final history = _locationHistory[device.id]!;

    // Backend'den gelen her konum güncellemesini direkt kaydet
    history.add(
      LocationHistory(
        deviceId: device.id,
        location: device.currentLocation,
        timestamp: device.lastUpdate,
      ),
    );

    // Timestamp'e göre sırala (en eski en üstte - ilk konum 1 olsun)
    history.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Son 500 kaydı tut (performans için)
    if (history.length > 500) {
      history.removeRange(500, history.length);
    }
  }

  // Geçmiş verileri toplu olarak ekle (WebSocket'ten gelen geçmiş veriler için)
  void addLocationHistoryBatch(
    String deviceId,
    List<LocationHistory> historyBatch,
  ) {
    if (!_locationHistory.containsKey(deviceId)) {
      _locationHistory[deviceId] = [];
    }

    final history = _locationHistory[deviceId]!;

    // Mevcut geçmişi temizle ve yeni geçmişi ekle
    history.clear();
    history.addAll(historyBatch);

    // Timestamp'e göre sırala
    history.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Son 500 kaydı tut
    if (history.length > 500) {
      history.removeRange(500, history.length);
    }

    notifyListeners();
  }

  // WebSocket'ten gelen geçmiş verileri işle
  void _processLocationHistoryBatch(
    String deviceId,
    List<Map<String, dynamic>> historyRecords,
  ) {
    try {
      // Map'ten LocationHistory listesine çevir
      final locationHistoryList = historyRecords.map((record) {
        return LocationHistory(
          deviceId: deviceId,
          location: LatLng(
            (record['latitude'] ?? 0.0).toDouble(),
            (record['longitude'] ?? 0.0).toDouble(),
          ),
          timestamp: DateTime.parse(
            record['timestamp'] ?? DateTime.now().toIso8601String(),
          ),
        );
      }).toList();

      // Geçmiş verileri ekle
      addLocationHistoryBatch(deviceId, locationHistoryList);
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  List<LocationHistory> getLocationHistory(String deviceId) {
    return _locationHistory[deviceId] ?? [];
  }

  // Manuel olarak konum geçmişine ekleme
  void addLocationToHistory(
    String deviceId,
    LatLng location,
    DateTime timestamp,
  ) {
    if (!_locationHistory.containsKey(deviceId)) {
      _locationHistory[deviceId] = [];
    }

    final history = _locationHistory[deviceId]!;

    // Yeni konumu ekle
    history.add(
      LocationHistory(
        deviceId: deviceId,
        location: location,
        timestamp: timestamp,
      ),
    );

    // Timestamp'e göre sırala (en eski en üstte - ilk konum 1 olsun)
    history.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Son 500 kaydı tut (performans için)
    if (history.length > 500) {
      history.removeRange(500, history.length);
    }

    // UI'ı güncelle
    notifyListeners();
  }

  // Tarih aralığına göre konum geçmişi filtreleme
  List<LocationHistory> getLocationHistoryByDateRange(
    String deviceId,
    DateTime startDate,
    DateTime endDate,
  ) {
    final allHistory = _locationHistory[deviceId] ?? [];

    if (allHistory.isEmpty) return [];

    // Tarih aralığına göre filtrele

    final filtered = allHistory.where((location) {
      try {
        // Konum timestamp'i startDate ile endDate arasında mı?
        return location.timestamp.isAfter(
              startDate.subtract(const Duration(seconds: 1)),
            ) &&
            location.timestamp.isBefore(
              endDate.add(const Duration(seconds: 1)),
            );
      } catch (e) {
        // Timestamp hatası varsa false döndür
        return false;
      }
    }).toList();

    // Filtrelenmiş kayıtları timestamp'e göre sırala (en eski en üstte - ilk konum 1 olsun)
    filtered.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return filtered;
  }

  // Son N günün konum geçmişi
  List<LocationHistory> getLocationHistoryLastDays(String deviceId, int days) {
    if (days <= 0) return [];

    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    return getLocationHistoryByDateRange(deviceId, startDate, endDate);
  }

  // Harita merkezi hesaplama (tüm cihazları içerecek şekilde)
  LatLng getMapCenter() {
    if (_devices.isEmpty) {
      // Cihaz yoksa Türkiye merkezi
      return const LatLng(39.9334, 32.8597);
    }

    if (_devices.length == 1) {
      // Tek cihaz varsa o cihazın konumu
      return _devices.first.currentLocation;
    }

    // Birden fazla cihaz varsa hepsini içerecek merkez
    double totalLat = 0;
    double totalLng = 0;

    for (final device in _devices) {
      totalLat += device.currentLocation.latitude;
      totalLng += device.currentLocation.longitude;
    }

    return LatLng(totalLat / _devices.length, totalLng / _devices.length);
  }

  // Harita zoom seviyesi hesaplama
  double getMapZoom() {
    if (_devices.isEmpty) {
      return 6.0; // Türkiye genel görünüm
    }

    if (_devices.length == 1) {
      return 12.0; // Tek cihaz için yakın zoom
    }

    // Birden fazla cihaz için bounds hesapla
    double minLat = _devices.first.currentLocation.latitude;
    double maxLat = _devices.first.currentLocation.latitude;
    double minLng = _devices.first.currentLocation.longitude;
    double maxLng = _devices.first.currentLocation.longitude;

    for (final device in _devices) {
      minLat = min(minLat, device.currentLocation.latitude);
      maxLat = max(maxLat, device.currentLocation.latitude);
      minLng = min(minLng, device.currentLocation.longitude);
      maxLng = max(maxLng, device.currentLocation.longitude);
    }

    // Lat ve Lng farklarına göre zoom hesapla
    double latDiff = maxLat - minLat;
    double lngDiff = maxLng - minLng;
    double maxDiff = max(latDiff, lngDiff);

    if (maxDiff > 10) return 4.0; // Çok geniş alan
    if (maxDiff > 5) return 6.0; // Geniş alan
    if (maxDiff > 1) return 8.0; // Orta alan
    if (maxDiff > 0.1) return 10.0; // Dar alan
    return 12.0; // Çok dar alan
  }

  // Yeni cihaz ekleme
  void addDevice(Device device) {
    _devices.add(device);
    notifyListeners();
  }

  // Cihaz silme
  void removeDevice(String deviceId) {
    _devices.removeWhere((device) => device.id == deviceId);
    _locationHistory.remove(deviceId);
    notifyListeners();
  }

  // Cihaz güncelleme
  void updateDevice(Device updatedDevice) {
    final index = _devices.indexWhere((d) => d.id == updatedDevice.id);
    if (index != -1) {
      _devices[index] = updatedDevice;
      _addToLocationHistory(updatedDevice);
      notifyListeners();
    }
  }

  // Cihaz ismi güncelleme
  void updateDeviceName(String deviceId, String newName) {
    final index = _devices.indexWhere((d) => d.id == deviceId);
    if (index != -1) {
      final device = _devices[index];
      _devices[index] = device.copyWith(name: newName);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _webSocketService.disconnect();
    super.dispose();
  }
}
