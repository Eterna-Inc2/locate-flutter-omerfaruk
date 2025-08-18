import 'package:json_annotation/json_annotation.dart';
import 'package:latlong2/latlong.dart';

part 'device.g.dart';

@JsonSerializable()
class Device {
  final String id;
  final String name;
  @JsonKey(fromJson: _latLngFromJson, toJson: _latLngToJson)
  final LatLng currentLocation;
  final DateTime lastUpdate;
  final bool isOnline;
  final String status;

  Device({
    required this.id,
    required this.name,
    required this.currentLocation,
    required this.lastUpdate,
    required this.isOnline,
    required this.status,
  });

  factory Device.fromJson(Map<String, dynamic> json) => _$DeviceFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceToJson(this);

  // LatLng JSON serialization helpers
  static LatLng _latLngFromJson(Map<String, dynamic> json) {
    return LatLng(json['lat'] as double, json['lng'] as double);
  }

  static Map<String, dynamic> _latLngToJson(LatLng latLng) {
    return {'lat': latLng.latitude, 'lng': latLng.longitude};
  }

  Device copyWith({
    String? id,
    String? name,
    LatLng? currentLocation,
    DateTime? lastUpdate,
    bool? isOnline,
    String? status,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      currentLocation: currentLocation ?? this.currentLocation,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      isOnline: isOnline ?? this.isOnline,
      status: status ?? this.status,
    );
  }
}
