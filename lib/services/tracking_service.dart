import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_app/models/bus_model.dart';
import '../models/student_model.dart';
import '../data/firebase_service.dart';
import 'notification_service.dart';

class TrackingService extends ChangeNotifier {
  BusLocationModel? _currentBusLocation;
  StreamSubscription<BusLocationModel?>? _busLocationSubscription;
  bool _isTracking = false;
  double _distanceToStop = 0.0;
  bool _hasNotifiedProximity = false;

  BusLocationModel? get currentBusLocation => _currentBusLocation;
  bool get isTracking => _isTracking;
  double get distanceToStop => _distanceToStop;

  void startTracking(StudentModel student) {
    if (_isTracking) return;

    _isTracking = true;
    _hasNotifiedProximity = false;
    
    _busLocationSubscription = FirebaseService
        .getBusLocationStream(student.busNumber)
        .listen((busLocation) {
      if (busLocation != null) {
        _currentBusLocation = busLocation;
        _calculateDistance(student.stopLocation);
        _checkProximityNotification(student);
        notifyListeners();
      }
    });
  }

  void stopTracking() {
    _isTracking = false;
    _busLocationSubscription?.cancel();
    _busLocationSubscription = null;
    _currentBusLocation = null;
    _distanceToStop = 0.0;
    _hasNotifiedProximity = false;
    notifyListeners();
  }

  void _calculateDistance(GeoPoint stopLocation) {
    if (_currentBusLocation == null) return;

    _distanceToStop = Geolocator.distanceBetween(
      _currentBusLocation!.location.latitude,
      _currentBusLocation!.location.longitude,
      stopLocation.latitude,
      stopLocation.longitude,
    );
  }

  void _checkProximityNotification(StudentModel student) {
    if (_distanceToStop <= 500 && !_hasNotifiedProximity) {
      _hasNotifiedProximity = true;
      NotificationService().showProximityNotification();
    } else if (_distanceToStop > 500) {
      _hasNotifiedProximity = false;
    }
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}