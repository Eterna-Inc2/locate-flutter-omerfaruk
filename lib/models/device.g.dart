// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Device _$DeviceFromJson(Map<String, dynamic> json) => Device(
  id: json['id'] as String,
  name: json['name'] as String,
  currentLocation: Device._latLngFromJson(
    json['currentLocation'] as Map<String, dynamic>,
  ),
  lastUpdate: DateTime.parse(json['lastUpdate'] as String),
  isOnline: json['isOnline'] as bool,
  status: json['status'] as String,
);

Map<String, dynamic> _$DeviceToJson(Device instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'currentLocation': Device._latLngToJson(instance.currentLocation),
  'lastUpdate': instance.lastUpdate.toIso8601String(),
  'isOnline': instance.isOnline,
  'status': instance.status,
};
