import 'package:cloud_firestore/cloud_firestore.dart';

class TripHistoryModel {
  final String id;
  final String busNumber;
  final DateTime arrivedAt;
  final double distanceAtArrival;

  TripHistoryModel({
    required this.id,
    required this.busNumber,
    required this.arrivedAt,
    required this.distanceAtArrival,
  });

  factory TripHistoryModel.fromMap(Map<String, dynamic> map, String id) {
    return TripHistoryModel(
      id: id,
      busNumber: map['busNumber'] ?? '',
      arrivedAt: (map['arrivedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      distanceAtArrival: (map['distanceAtArrival'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'busNumber': busNumber,
      'arrivedAt': Timestamp.fromDate(arrivedAt),
      'distanceAtArrival': distanceAtArrival,
    };
  }
}
