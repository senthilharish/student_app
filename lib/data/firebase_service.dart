import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_app/models/bus_model.dart';
import '../models/student_model.dart';
import '../models/trip_history_model.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Student operations
  static Future<void> saveStudent(StudentModel student) async {
    await _firestore
        .collection('students')
        .doc(student.uid)
        .set(student.toMap());
  }

  static Future<StudentModel?> getStudent(String uid) async {
    try {
      final doc = await _firestore.collection('students').doc(uid).get();
      if (doc.exists) {
        return StudentModel.fromMap(doc.data()!, uid);
      }
      return null;
    } catch (e) {
      print('Error getting student: $e');
      return null;
    }
  }

  // Bus location operations
  static Stream<BusLocationModel?> getBusLocationStream(String busNumber) {
    return _firestore
        .collection('buses')
        .doc(busNumber)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        return BusLocationModel.fromMap({
          'busNumber': busNumber,
          'location': data['location'],
          'timestamp': data['timestamp'] ?? Timestamp.now(),
        });
      }
      return null;
    });
  }

  // Trip history operations
  static Future<void> logTripArrival(String studentUid, TripHistoryModel entry) async {
    await _firestore
        .collection('students')
        .doc(studentUid)
        .collection('trip_history')
        .add(entry.toMap());
  }

  static Stream<List<TripHistoryModel>> getTripHistoryStream(String studentUid) {
    return _firestore
        .collection('students')
        .doc(studentUid)
        .collection('trip_history')
        .orderBy('arrivedAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TripHistoryModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}