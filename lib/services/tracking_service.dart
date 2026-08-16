import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_app/models/bus_model.dart';
import '../models/student_model.dart';
import '../data/firebase_service.dart';
import 'notification_service.dart';

class TrackingService extends ChangeNotifier {
  static const double _proximityThresholdMeters = 500;
  // Below this speed the bus is treated as stationary/idle, so an ETA
  // extrapolated from it would be misleadingly large or infinite.
  static const double _minSpeedForEtaMs = 1.0;

  BusLocationModel? _currentBusLocation;
  BusLocationModel? _previousBusLocation;
  StreamSubscription<BusLocationModel?>? _busLocationSubscription;
  bool _isTracking = false;
  double _distanceToStop = 0.0;
  double? _etaMinutes;
  bool _hasNotifiedProximity = false;
  bool _hasError = false;
  String? _errorMessage;

  BusLocationModel? get currentBusLocation => _currentBusLocation;
  bool get isTracking => _isTracking;
  double get distanceToStop => _distanceToStop;
  double? get etaMinutes => _etaMinutes;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;

  void startTracking(StudentModel student) {
    if (_isTracking) return;

    _isTracking = true;
    _hasNotifiedProximity = false;
    _hasError = false;
    _errorMessage = null;
    _previousBusLocation = null;
    _etaMinutes = null;

    _busLocationSubscription = FirebaseService
        .getBusLocationStream(student.busNumber)
        .listen((busLocation) {
      if (busLocation != null) {
        _previousBusLocation = _currentBusLocation;
        _currentBusLocation = busLocation;
        _hasError = false;
        _errorMessage = null;
        _calculateDistance(student.stopLocation);
        _calculateEta();
        _checkProximityNotification(student);
        notifyListeners();
      }
    }, onError: (error) {
      _hasError = true;
      _errorMessage = 'Unable to load bus location. Check your connection.';
      notifyListeners();
    });
  }

  void stopTracking() {
    _isTracking = false;
    _busLocationSubscription?.cancel();
    _busLocationSubscription = null;
    _currentBusLocation = null;
    _previousBusLocation = null;
    _distanceToStop = 0.0;
    _etaMinutes = null;
    _hasNotifiedProximity = false;
    _hasError = false;
    _errorMessage = null;
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

  void _calculateEta() {
    _etaMinutes = null;
    final previous = _previousBusLocation;
    final current = _currentBusLocation;
    if (previous == null || current == null) return;

    final elapsedSeconds =
        current.timestamp.difference(previous.timestamp).inSeconds;
    if (elapsedSeconds <= 0) return;

    final movedMeters = Geolocator.distanceBetween(
      previous.location.latitude,
      previous.location.longitude,
      current.location.latitude,
      current.location.longitude,
    );

    final speedMs = movedMeters / elapsedSeconds;
    if (speedMs < _minSpeedForEtaMs) return;

    _etaMinutes = (_distanceToStop / speedMs) / 60;
  }

  void _checkProximityNotification(StudentModel student) {
    if (_distanceToStop <= _proximityThresholdMeters && !_hasNotifiedProximity) {
      _hasNotifiedProximity = true;
      NotificationService().showProximityNotification();
    } else if (_distanceToStop > _proximityThresholdMeters) {
      _hasNotifiedProximity = false;
    }
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}