// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocationHistory _$LocationHistoryFromJson(Map<String, dynamic> json) =>
    LocationHistory(
      deviceId: json['deviceId'] as String,
      location: LocationHistory._latLngFromJson(
        json['location'] as Map<String, dynamic>,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      note: json['note'] as String?,
    );

Map<String, dynamic> _$LocationHistoryToJson(LocationHistory instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'location': LocationHistory._latLngToJson(instance.location),
      'timestamp': instance.timestamp.toIso8601String(),
      'note': instance.note,
    };
