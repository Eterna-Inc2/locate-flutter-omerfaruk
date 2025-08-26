import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../providers/device_provider.dart';
import '../models/device.dart';
import '../widgets/locate_header.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _idController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LocateHeader(
        title: 'Yeni Cihaz Ekle',
        showBackButton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Cihaz Adı',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.device_hub),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Cihaz adı gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: 'Cihaz ID',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.fingerprint),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Cihaz ID gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _addDevice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Cihaz Ekle', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addDevice() {
    if (_formKey.currentState!.validate()) {
      final device = Device(
        id: _idController.text,
        name: _nameController.text,
        currentLocation: const LatLng(
          0,
          0,
        ), // Varsayılan konum, cihazdan güncellenecek
        lastUpdate: DateTime.now(),
        isOnline: false, // Yeni eklenen cihaz başlangıçta offline
        status: 'Offline',
      );

      context.read<DeviceProvider>().addDevice(device);
      Navigator.pop(context);
    }
  }
}
