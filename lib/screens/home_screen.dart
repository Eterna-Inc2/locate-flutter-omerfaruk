import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../models/device.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  bool _autoFollow = true; // Otomatik takip aktif
  bool _isManualZoom = false; // Manuel zoom yapıldığında otomatik zoom'u durdur

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Android emülatörde solda çıkan floating menu'yu gizle
      drawer: const SizedBox.shrink(),
      endDrawer: const SizedBox.shrink(),
      appBar: AppBar(
        automaticallyImplyLeading: false, // Sol taraftaki hamburger menü ikonunu gizle
        title: const Text('Cihaz Takip'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true, // iOS ve Android'de ortalı başlık
        actions: [
          Consumer<DeviceProvider>(
            builder: (context, provider, child) {
              return Container(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      provider.isConnected ? Icons.wifi : Icons.wifi_off,
                      color: provider.isConnected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      provider.isConnected ? 'Bağlı' : 'Bağlı Değil',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<DeviceProvider>(
        builder: (context, provider, child) {
          // Cihaz güncellemelerini dinle
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_autoFollow && !_isManualZoom && provider.devices.isNotEmpty) {
              final latestDevice = provider.devices.first;
              // Mevcut zoom seviyesini koru
              final currentZoom = _mapController.camera.zoom;
              _mapController.move(latestDevice.currentLocation, currentZoom);
            }
          });

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: provider.getMapCenter(),
                  initialZoom: provider.getMapZoom(),
                  maxZoom: 18.0,
                  minZoom: 3.0,
                  onMapEvent: _autoFollow ? _onMapEvent : null,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.takip_fl',
                  ),
                  // Cihaz markerları
                  ...provider.devices.map(
                    (device) => _buildDeviceMarker(device),
                  ),
                ],
              ),
              // Cihaz yoksa mesaj göster
              if (provider.devices.isEmpty)
                Positioned(
                  top: 100,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 48,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Henüz cihaz eklenmemiş',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cihaz eklemek için Cihazlar sekmesine gidin',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Zoom in butonu - Soft tasarım
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  final currentZoom = _mapController.camera.zoom;
                  _mapController.move(
                    _mapController.camera.center,
                    currentZoom + 1,
                  );
                  // Manuel zoom yapıldığını işaretle (sadece zoom için)
                  _isManualZoom = true;
                  
                  // 3 saniye sonra otomatik takibi tekrar aktif et
                  Future.delayed(const Duration(seconds: 3), () {
                    if (mounted) {
                      setState(() {
                        _isManualZoom = false;
                      });
                    }
                  });
                },
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: const Icon(Icons.add, color: Colors.grey, size: 20),
                ),
              ),
            ),
          ),
          // Zoom out butonu - Soft tasarım
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  final currentZoom = _mapController.camera.zoom;
                  _mapController.move(
                    _mapController.camera.center,
                    currentZoom - 1,
                  );
                  // Manuel zoom yapıldığını işaretle (sadece zoom için)
                  _isManualZoom = true;
                  
                  // 3 saniye sonra otomatik takibi tekrar aktif et
                  Future.delayed(const Duration(seconds: 3), () {
                    if (mounted) {
                      setState(() {
                        _isManualZoom = false;
                      });
                    }
                  });
                },
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: const Icon(Icons.remove, color: Colors.grey, size: 20),
                ),
              ),
            ),
          ),
          // Otomatik Takip Toggle - Soft tasarım
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    _autoFollow = !_autoFollow;
                  });
                },
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    _autoFollow ? Icons.my_location : Icons.location_off,
                    color: _autoFollow ? Colors.green[600] : Colors.grey,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          // Haritayı Ortala - Soft tasarım
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  // Haritayı tüm cihazları içerecek şekilde ortala
                  final center = context.read<DeviceProvider>().getMapCenter();
                  final zoom = context.read<DeviceProvider>().getMapZoom();
                  _mapController.move(center, zoom);
                  // Manuel zoom flag'ini sıfırla
                  _isManualZoom = false;
                },
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: const Icon(
                    Icons.center_focus_strong,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          // Ayarlar - Soft tasarım
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  _showConnectionDialog(context);
                },
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: const Icon(
                    Icons.settings,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceMarker(Device device) {
    return MarkerLayer(
      markers: [
        Marker(
          point: device.currentLocation,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showDeviceInfo(device),
            child: Container(
              decoration: BoxDecoration(
                color: device.isOnline ? Colors.green : Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(Icons.location_on, color: Colors.white, size: 24),
            ),
          ),
        ),
      ],
    );
  }

  void _showDeviceInfo(Device device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(device.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Durum: ${device.status}'),
            Text('Son Güncelleme: ${_formatDateTime(device.lastUpdate)}'),
            Text(
              'Konum: ${device.currentLocation.latitude.toStringAsFixed(4)}, ${device.currentLocation.longitude.toStringAsFixed(4)}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _onMapEvent(MapEvent event) {
    // Yeni konum geldiğinde haritayı ortala (manuel zoom yapılmadıysa)
    if (_autoFollow && !_isManualZoom && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && context.read<DeviceProvider>().devices.isNotEmpty) {
          final latestDevice = context.read<DeviceProvider>().devices.first;
          final currentZoom = _mapController.camera.zoom;
          _mapController.move(latestDevice.currentLocation, currentZoom);
        }
      });
    }
  }

  void _showConnectionDialog(BuildContext context) {
    String url = 'wss://dcaef8cc0ea9.ngrok-free.app/socket.io/';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Socket.IO Bağlantısı'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'Socket.IO URL',
            hintText: 'wss://dcaef8cc0ea9.ngrok-free.app/socket.io/',
          ),
          onChanged: (value) => url = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<DeviceProvider>().connectToWebSocket(url);
              Navigator.pop(context);
            },
            child: const Text('Bağlan'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }
}
