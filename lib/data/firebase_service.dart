import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:student_app/models/bus_model.dart';
import '../models/student_model.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _realtimeDatabaseUrl =
      'https://tracker-aa86b-default-rtdb.firebaseio.com/';

  // Live bus location is read from Realtime Database — the driver app writes
  // here at high frequency, and RTDB fan-out reads are far cheaper than
  // Firestore document reads at that update rate.
  static final DatabaseReference _busLocationsRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: _realtimeDatabaseUrl,
  ).ref('bus_locations');

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
    return _busLocationsRef.child(busNumber).onValue.map((event) {
      final value = event.snapshot.value;
      if (value is Map) {
        return BusLocationModel.fromRealtimeMap(busNumber, value);
      }
      return null;
    });
  }
}
