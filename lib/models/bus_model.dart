import 'package:cloud_firestore/cloud_firestore.dart';

class BusLocationModel {
  final String busNumber;
  final GeoPoint location;
  final DateTime timestamp;

  BusLocationModel({
    required this.busNumber,
    required this.location,
    required this.timestamp,
  });

  factory BusLocationModel.fromMap(Map<String, dynamic> map) {
    return BusLocationModel(
      busNumber: map['busNumber'] ?? '',
      location: map['location'] ?? const GeoPoint(0, 0),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'busNumber': busNumber,
      'location': location,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}