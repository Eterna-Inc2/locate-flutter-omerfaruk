import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../models/device.dart';
import 'add_device_screen.dart';
import 'location_history_map_screen.dart';

class DeviceListScreen extends StatelessWidget {
  const DeviceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cihaz Listesi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true, // iOS ve Android'de ortalı başlık
      ),
      body: Consumer<DeviceProvider>(
        builder: (context, provider, child) {
          if (provider.devices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz cihaz eklenmemiş',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'İlk cihazınızı eklemek için + butonuna tıklayın',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.devices.length,
            itemBuilder: (context, index) {
              final device = provider.devices[index];
              return _buildDeviceCard(context, device);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddDeviceScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDeviceCard(BuildContext context, Device device) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: device.isOnline ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.location_on, color: Colors.white, size: 30),
        ),
        title: Text(
          device.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Durum: ${device.status}',
              style: TextStyle(
                color: device.isOnline ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Son Güncelleme: ${_formatDateTime(device.lastUpdate)}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Konum: ${device.currentLocation.latitude.toStringAsFixed(4)}, ${device.currentLocation.longitude.toStringAsFixed(4)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'history') {
              _showLocationHistory(context, device);
            } else if (value == 'map') {
              _showOnMap(context, device);
            } else if (value == 'rename') {
              _showRenameDialog(context, device);
            } else if (value == 'delete') {
              _showDeleteDialog(context, device);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'history',
              child: Row(
                children: [
                  Icon(Icons.history),
                  SizedBox(width: 8),
                  Text('Konum Geçmişi'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'map',
              child: Row(
                children: [
                  Icon(Icons.map),
                  SizedBox(width: 8),
                  Text('Haritada Göster'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'rename',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('İsim Değiştir'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Cihazı Sil', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          child: const Icon(Icons.more_vert),
        ),
        isThreeLine: true,
      ),
    );
  }

  void _showLocationHistory(BuildContext context, Device device) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationHistoryScreen(device: device),
      ),
    );
  }

  void _showOnMap(BuildContext context, Device device) {
    // Konum geçmişi haritasını göster
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationHistoryMapScreen(device: device),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Device device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cihazı Sil'),
        content: Text(
          '${device.name} cihazını silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<DeviceProvider>().removeDevice(device.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${device.name} silindi'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, Device device) {
    final TextEditingController nameController = TextEditingController(
      text: device.name,
    );
    final FocusNode focusNode = FocusNode();

    showDialog(
      context: context,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AlertDialog(
          title: const Text('Cihaz İsmini Değiştir'),
          content: TextField(
            controller: nameController,
            focusNode: focusNode,
            decoration: const InputDecoration(
              labelText: 'Yeni İsim',
              border: OutlineInputBorder(),
              hintText: 'Cihaz ismini girin',
            ),
            autofocus: true,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  context.read<DeviceProvider>().updateDeviceName(
                    device.id,
                    newName,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cihaz ismi "$newName" olarak güncellendi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Güncelle'),
            ),
          ],
        ),
      ),
    ).then((_) {
      // Dialog kapandığında focus'u temizle
      focusNode.dispose();
      nameController.dispose();
    });

    // Dialog açıldıktan sonra focus'u ver
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }
}

class LocationHistoryScreen extends StatelessWidget {
  final Device device;

  const LocationHistoryScreen({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${device.name} - Konum Geçmişi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Consumer<DeviceProvider>(
        builder: (context, provider, child) {
          final history = provider.getLocationHistory(device.id);

          if (history.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Konum geçmişi bulunamadı',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  Text(
                    'Henüz konum güncellemesi yapılmamış',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Konum geçmişini yeniden eskiye sırala (en yeni en üstte)
          final sortedHistory = List.from(history)
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

          return Column(
            children: [
              // Özet bilgi
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue[50],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSummaryItem(
                      'Son Güncelleme',
                      _formatDateTime(sortedHistory.first.timestamp),
                      Icons.access_time,
                    ),
                    _buildSummaryItem(
                      'İlk Güncelleme',
                      _formatDateTime(sortedHistory.last.timestamp),
                      Icons.history,
                    ),
                  ],
                ),
              ),
              // Konum listesi
              Expanded(
                child: ListView.builder(
                  itemCount: sortedHistory.length,
                  itemBuilder: (context, index) {
                    final location = sortedHistory[index];
                    final isLatest = index == 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isLatest ? Colors.green : Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isLatest ? Icons.gps_fixed : Icons.location_on,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          '${location.location.latitude.toStringAsFixed(6)}, ${location.location.longitude.toStringAsFixed(6)}',
                          style: TextStyle(
                            fontWeight: isLatest
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDateTime(location.timestamp),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isLatest)
                              const Text(
                                '📍 Şu anki konum',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        trailing: Text(
                          '#${sortedHistory.length - index}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
