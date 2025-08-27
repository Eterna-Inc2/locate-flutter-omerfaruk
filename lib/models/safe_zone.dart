import 'package:json_annotation/json_annotation.dart';

part 'safe_zone.g.dart';

@JsonSerializable()
class SafeZone {
  final double centerLat;
  final double centerLng;
  // metre cinsinden yarıçap
  final double radiusMeters;

  const SafeZone({
    required this.centerLat,
    required this.centerLng,
    required this.radiusMeters,
  });

  factory SafeZone.fromJson(Map<String, dynamic> json) =>
      _$SafeZoneFromJson(json);
  Map<String, dynamic> toJson() => _$SafeZoneToJson(this);
}
