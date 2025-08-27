import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';
import 'dart:async';
import '../models/device.dart';
import '../providers/device_provider.dart';
import '../models/location_history.dart';
import '../widgets/locate_header.dart';
import '../models/safe_zone.dart';

class LocationHistoryMapScreen extends StatefulWidget {
  final Device device;

  const LocationHistoryMapScreen({super.key, required this.device});

  @override
  State<LocationHistoryMapScreen> createState() =>
      _LocationHistoryMapScreenState();
}

class _LocationHistoryMapScreenState extends State<LocationHistoryMapScreen> {
  final MapController _mapController = MapController();

  // Kullanıcı tarih seçene kadar canlı pencere (son 7 gün–şimdi) açık
  bool _useLiveWindow = true;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  final bool _isRealTimeTracking = true; // Sayfa açıldığında canlı takip aktif
  bool _isManualZoom = false; // Manuel zoom yapılınca otomatik takip durur
  Timer? _realTimeTimer;
  bool _isSelectingSafeZoneCenter = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startRealTimeTracking();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _centerOnLatestLocation();
    });
  }

  List<LocationHistory> _getFilteredHistory(DeviceProvider provider) {
    final allHistory = provider.getLocationHistory(widget.device.id);

    // Canlı penceredeysek aralığı "şimdi" ile her seferinde yeniden kur
    final now = DateTime.now();
    final effectiveStart = _useLiveWindow
        ? now.subtract(const Duration(days: 7))
        : _startDate;
    final effectiveEnd = _useLiveWindow ? now : _endDate;

    return allHistory.where((h) {
      try {
        return h.timestamp.isAfter(
              effectiveStart.subtract(const Duration(seconds: 1)),
            ) &&
            h.timestamp.isBefore(effectiveEnd.add(const Duration(seconds: 1)));
      } catch (_) {
        return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      // Android emülatörde solda çıkan floating menu'yu gizle
      // drawer ve endDrawer kaldırıldı - iOS'taki gibi sadece geri ikonu olsun
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 20),
        child: Consumer<DeviceProvider>(
          builder: (context, provider, child) {
            final currentDevice = provider.devices.firstWhere(
              (d) => d.id == widget.device.id,
              orElse: () => widget.device,
            );
            return LocateHeader(
              title: '${currentDevice.name} - Konum Geçmişi',
              showBackButton: true,
              actions: [
                if (provider.getSafeZones(widget.device.id).isEmpty)
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _isSelectingSafeZoneCenter = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Haritaya dokunarak merkez seçin'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_location_alt),
                    label: const Text('Güvenli Alan'),
                  )
                else
                  TextButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Güvenli Alanı Sil'),
                          content: const Text('Kaldırılsın mı?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Vazgeç'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Sil'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && mounted) {
                        await context.read<DeviceProvider>().removeAllSafeZones(
                          widget.device.id,
                        );
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Güvenli Alanı Sil'),
                  ),
              ],
            );
          },
        ),
      ),
      body: Consumer<DeviceProvider>(
        builder: (context, provider, child) {
          final filteredHistory = _getFilteredHistory(provider);
          final zones = provider.getSafeZones(widget.device.id);
          final safeZone = zones.isNotEmpty ? zones.first : null;

          return Column(
            children: [
              // Tarih aralığı seçimi (HER ZAMAN TIKLANABİLİR)
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[50]!, Colors.blue[100]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue[600],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _useLiveWindow
                              ? 'Tarih Aralığı: Son 7 Gün (Canlı)'
                              : 'Tarih Aralığı',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const Spacer(),
                        if (safeZone != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.shield_moon,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Güvenli Alan: ${(safeZone.radiusMeters / 1000).toStringAsFixed(1)} km',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (!_useLiveWindow)
                          TextButton.icon(
                            onPressed: () {
                              setState(
                                () => _useLiveWindow = true,
                              ); // canlıya dön
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _centerOnFilteredHistory();
                              });
                            },
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Canlı 7 Gün'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDatePicker('Başlangıç', _startDate, (
                            date,
                          ) {
                            setState(() {
                              _useLiveWindow = false; // kullanıcı seçti
                              _startDate = date;
                            });
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _centerOnFilteredHistory();
                            });
                          }),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDatePicker('Bitiş', _endDate, (date) {
                            setState(() {
                              _useLiveWindow = false; // kullanıcı seçti
                              _endDate = date;
                            });
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _centerOnFilteredHistory();
                            });
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Harita
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Consumer<DeviceProvider>(
                      builder: (context, provider, child) {
                        final currentDevice = provider.devices.firstWhere(
                          (d) => d.id == widget.device.id,
                          orElse: () => widget.device,
                        );

                        if (filteredHistory.isEmpty) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.grey[100]!, Colors.grey[200]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.location_off,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    'Konum Geçmişi Bulunamadı',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Seçilen tarih aralığında\nkonum verisi yok',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // keep map reactivity but no-op var removed (lastTs)

                        return Listener(
                          onPointerDown: (_) {},
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: currentDevice.currentLocation,
                              initialZoom: 14.0,
                              maxZoom: 18.0,
                              minZoom: 3.0,
                              onMapEvent: _isRealTimeTracking
                                  ? _onMapEvent
                                  : null,
                              onTap: (tapPosition, point) async {
                                if (!_isSelectingSafeZoneCenter) return;
                                setState(
                                  () => _isSelectingSafeZoneCenter = false,
                                );
                                final radiusKm = await _askRadiusKm(context);
                                if (radiusKm == null) return;
                                final zone = SafeZone(
                                  centerLat: point.latitude,
                                  centerLng: point.longitude,
                                  radiusMeters: radiusKm * 1000.0,
                                );
                                await context
                                    .read<DeviceProvider>()
                                    .addSafeZone(widget.device.id, zone);
                              },
                              interactionOptions: const InteractionOptions(
                                enableScrollWheel: true,
                                enableMultiFingerGestureRace: true,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.takip_fl',
                              ),

                              // Cihaz marker'ı (mevcut konum)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: currentDevice.currentLocation,
                                    width: 40,
                                    height: 40,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Rota (geçmişten polyline)
                              if (filteredHistory.length > 1)
                                PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: filteredHistory
                                          .map((h) => h.location)
                                          .toList(),
                                      strokeWidth: 3,
                                      color: Colors.blue[600]!,
                                    ),
                                  ],
                                ),

                              // Geçmiş noktalar (küçük marker'lar)
                              MarkerLayer(
                                markers: filteredHistory
                                    .map(
                                      (history) => Marker(
                                        point: history.location,
                                        width: 8,
                                        height: 8,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.blue[400],
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),

                              // Güvenli Alan Çemberleri (tümü)
                              CircleLayer(
                                circles: [
                                  for (final zone in provider.getSafeZones(
                                    widget.device.id,
                                  ))
                                    CircleMarker(
                                      point: LatLng(
                                        zone.centerLat,
                                        zone.centerLng,
                                      ),
                                      color: Colors.green.withOpacity(0.15),
                                      borderColor: Colors.green,
                                      borderStrokeWidth: 2,
                                      useRadiusInMeter: true,
                                      radius: zone.radiusMeters,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Zoom in
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
                  final newZoom = (currentZoom + 1).clamp(3.0, 18.0);
                  _mapController.move(_mapController.camera.center, newZoom);
                },
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.zoom_in, color: Colors.blue, size: 20),
                ),
              ),
            ),
          ),
          // Zoom out
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
                  final newZoom = (currentZoom - 1).clamp(3.0, 18.0);
                  _mapController.move(_mapController.camera.center, newZoom);
                },
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.zoom_out, color: Colors.blue, size: 20),
                ),
              ),
            ),
          ),
          // Center on device
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
                  _centerOnLatestLocation();
                },
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.my_location, color: Colors.blue, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<double?> _askRadiusKm(BuildContext context) async {
    final controller = TextEditingController(text: '1.0');
    return showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yarıçap (km)'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'Örn: 1.5'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text.replaceAll(',', '.'));
              if (val == null || val <= 0) {
                Navigator.pop(ctx);
              } else {
                Navigator.pop(ctx, val);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(
    String label,
    DateTime date,
    Function(DateTime) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            // ignore: use_build_context_synchronously
            final selectedDate = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: Colors.blue[600]!,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Colors.black87,
                    ),
                    dialogTheme: const DialogThemeData(
                      backgroundColor: Colors.white,
                    ),
                  ),
                  child: child!,
                );
              },
            );

            if (selectedDate != null) {
              final initialTime = TimeOfDay.fromDateTime(
                date,
              ); // date parametresini async gap'ten önce hesapla
              final primaryColor = Colors
                  .blue[600]!; // Colors.blue[600]'yı async gap'ten önce hesapla
              final whiteColor =
                  Colors.white; // Colors.white'ı async gap'ten önce hesapla
              final blackColor = Colors
                  .black87; // Colors.black87'yi async gap'ten önce hesapla
              // ignore: use_build_context_synchronously
              final selectedTime = await showTimePicker(
                context: context,
                initialTime: initialTime,
                builder: (context, child) {
                  final themeContext =
                      context; // context'i local variable olarak sakla
                  // ignore: use_build_context_synchronously
                  return Theme(
                    data: Theme.of(themeContext).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: primaryColor,
                        onPrimary: whiteColor,
                        surface: whiteColor,
                        onSurface: blackColor,
                      ),
                      dialogTheme: DialogThemeData(backgroundColor: whiteColor),
                    ),
                    child: child!,
                  );
                },
              );

              if (mounted) {
                setState(() {
                  _useLiveWindow = false; // tarih seçildi -> canlı mod kapansın
                  if (selectedTime != null) {
                    if (mounted) {
                      _startOrEndSetter(
                        label == 'Başlangıç',
                        selectedDate,
                        selectedTime,
                        mounted ? onChanged : (date) {},
                      );
                    }
                  } else {
                    if (mounted) {
                      onChanged(
                        DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                        ),
                      );
                    }
                  }
                });

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _centerOnFilteredHistory();
                  }
                });
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _startOrEndSetter(
    bool isStart,
    DateTime selectedDate,
    TimeOfDay selectedTime,
    Function(DateTime) onChanged,
  ) {
    if (!mounted) return;

    final combined = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    onChanged(combined);
  }

  void _onMapEvent(MapEvent event) {
    if (_isManualZoom) return;
    if (_isRealTimeTracking && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _followCurrentLocation();
      });
    }
  }

  void _followCurrentLocation() {
    if (!mounted) return;
    if (_isManualZoom) return;

    final provider = context.read<DeviceProvider>();
    final history = provider.getLocationHistory(widget.device.id);

    if (history.isNotEmpty) {
      final latestLocation = history.last.location;
      final currentZoom = _mapController.camera.zoom;
      try {
        if (!mounted) return;
        _mapController.move(latestLocation, currentZoom);
      } catch (_) {}
    }
  }

  // _centerMap kaldırıldı (kullanım yok)

  LatLng _calculateCenter(List<LocationHistory> history) {
    double totalLat = 0, totalLng = 0;
    for (final h in history) {
      totalLat += h.location.latitude;
      totalLng += h.location.longitude;
    }
    return LatLng(totalLat / history.length, totalLng / history.length);
  }

  double _calculateZoom(List<LocationHistory> history) {
    if (history.length < 2) return 14.0;
    double minLat = double.infinity, maxLat = -double.infinity;
    double minLng = double.infinity, maxLng = -double.infinity;

    for (final h in history) {
      minLat = min(minLat, h.location.latitude);
      maxLat = max(maxLat, h.location.latitude);
      minLng = min(minLng, h.location.longitude);
      maxLng = max(maxLng, h.location.longitude);
    }

    final latRange = maxLat - minLat;
    final lngRange = maxLng - minLng;
    final maxRange = max(latRange, lngRange);

    if (maxRange > 10) return 4.0;
    if (maxRange > 5) return 6.0;
    if (maxRange > 1) return 8.0;
    if (maxRange > 0.1) return 10.0;
    return 12.0;
  }

  void _centerOnLatestLocation() {
    if (!mounted) return;
    if (_isManualZoom) return;

    final provider = context.read<DeviceProvider>();
    final history = provider.getLocationHistory(widget.device.id);

    if (history.isNotEmpty) {
      final latestLocation = history.last.location;
      try {
        if (!mounted) return;
        _mapController.move(latestLocation, 14.0);
      } catch (_) {}
    }
  }

  void _centerOnFilteredHistory() {
    if (!mounted) return;
    if (_isManualZoom) return;

    final provider = context.read<DeviceProvider>();
    final filtered = _getFilteredHistory(provider);

    if (filtered.isNotEmpty) {
      final center = _calculateCenter(filtered);
      final zoom = _calculateZoom(filtered);
      try {
        if (!mounted) return;
        _mapController.move(center, zoom);
      } catch (_) {}
    }
  }

  void _startRealTimeTracking() {
    // Önceki timer'ı durdur
    _stopRealTimeTimer();

    _realTimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isRealTimeTracking) {
        _stopRealTimeTimer();
        return;
      }

      _followCurrentLocation();

      // Yeni konum ekleme (Provider tarafı notifyListeners() çağırmalı)
      final provider = context.read<DeviceProvider>();
      final currentDevice = provider.devices.firstWhere(
        (d) => d.id == widget.device.id,
        orElse: () => widget.device,
      );

      final history = provider.getLocationHistory(widget.device.id);
      final exists = history.any(
        (h) =>
            h.location.latitude == currentDevice.currentLocation.latitude &&
            h.location.longitude == currentDevice.currentLocation.longitude,
      );

      if (!exists) {
        provider.addLocationToHistory(
          widget.device.id,
          currentDevice.currentLocation,
          DateTime.now(),
        );
        // setState gerekmez; Consumer yeniden çizilecek
      }
    });

    _followCurrentLocation();
  }

  void _stopRealTimeTimer() {
    _realTimeTimer?.cancel();
    _realTimeTimer = null;
  }

  @override
  void dispose() {
    _stopRealTimeTimer();
    super.dispose();
  }

  // _buildStatChip method'u kaldırıldı - UI'dan kaldırıldı

  // _formatDuration method'u kaldırıldı - UI'dan kaldırıldı
}
