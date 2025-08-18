import 'package:json_annotation/json_annotation.dart';
import 'package:latlong2/latlong.dart';

part 'location_history.g.dart';

@JsonSerializable()
class LocationHistory {
  final String deviceId;
  @JsonKey(fromJson: _latLngFromJson, toJson: _latLngToJson)
  final LatLng location;
  final DateTime timestamp;
  final String? note;

  LocationHistory({
    required this.deviceId,
    required this.location,
    required this.timestamp,
    this.note,
  });

  factory LocationHistory.fromJson(Map<String, dynamic> json) =>
      _$LocationHistoryFromJson(json);
  Map<String, dynamic> toJson() => _$LocationHistoryToJson(this);

  // LatLng JSON serialization helpers
  static LatLng _latLngFromJson(Map<String, dynamic> json) {
    return LatLng(json['lat'] as double, json['lng'] as double);
  }

  static Map<String, dynamic> _latLngToJson(LatLng latLng) {
    return {'lat': latLng.latitude, 'lng': latLng.longitude};
  }
}
