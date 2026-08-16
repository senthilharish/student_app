import 'package:latlong2/latlong.dart';

class BusLocationModel {
  final String busNumber;
  final LatLng location;
  final DateTime timestamp;
  final bool isActive;

  BusLocationModel({
    required this.busNumber,
    required this.location,
    required this.timestamp,
    this.isActive = true,
  });

  /// Parses a Realtime Database snapshot value for `bus_locations/{busNumber}`.
  factory BusLocationModel.fromRealtimeMap(
    String busNumber,
    Map<dynamic, dynamic> map,
  ) {
    final lat = (map['lat'] as num?)?.toDouble() ?? 0.0;
    final lng = (map['lng'] as num?)?.toDouble() ?? 0.0;
    final timestampMs = map['timestamp'] as int?;

    return BusLocationModel(
      busNumber: busNumber,
      location: LatLng(lat, lng),
      timestamp: timestampMs != null
          ? DateTime.fromMillisecondsSinceEpoch(timestampMs)
          : DateTime.now(),
      isActive: map['isActive'] as bool? ?? true,
    );
  }
}
