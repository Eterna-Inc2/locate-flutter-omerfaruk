// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'safe_zone.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SafeZone _$SafeZoneFromJson(Map<String, dynamic> json) => SafeZone(
  centerLat: (json['centerLat'] as num).toDouble(),
  centerLng: (json['centerLng'] as num).toDouble(),
  radiusMeters: (json['radiusMeters'] as num).toDouble(),
);

Map<String, dynamic> _$SafeZoneToJson(SafeZone instance) => <String, dynamic>{
  'centerLat': instance.centerLat,
  'centerLng': instance.centerLng,
  'radiusMeters': instance.radiusMeters,
};
