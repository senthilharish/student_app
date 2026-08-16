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
  // If no fresh location has arrived in this long, the bus is presumed to
  // have gone offline (app killed, crashed, backgrounded) rather than
  // genuinely stationary — the driver's throttle still writes at least
  // every 20s while active, so this gives comfortable headroom.
  static const Duration _staleAfter = Duration(seconds: 45);

  BusLocationModel? _currentBusLocation;
  BusLocationModel? _previousBusLocation;
  StreamSubscription<BusLocationModel?>? _busLocationSubscription;
  Timer? _staleCheckTimer;
  bool _isTracking = false;
  double _distanceToStop = 0.0;
  double? _etaMinutes;
  bool _hasNotifiedProximity = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isStale = false;

  BusLocationModel? get currentBusLocation => _currentBusLocation;
  bool get isTracking => _isTracking;
  double get distanceToStop => _distanceToStop;
  double? get etaMinutes => _etaMinutes;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  bool get isStale => _isStale;

  void startTracking(StudentModel student) {
    if (_isTracking) return;

    _isTracking = true;
    _hasNotifiedProximity = false;
    _hasError = false;
    _errorMessage = null;
    _previousBusLocation = null;
    _etaMinutes = null;
    _isStale = false;

    _busLocationSubscription = FirebaseService
        .getBusLocationStream(student.busNumber)
        .listen((busLocation) {
      if (busLocation != null) {
        _previousBusLocation = _currentBusLocation;
        _currentBusLocation = busLocation;
        _hasError = false;
        _errorMessage = null;
        _isStale = !busLocation.isActive;
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

    _staleCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkStale();
    });
  }

  void _checkStale() {
    final current = _currentBusLocation;
    if (current == null) return;

    final isStaleNow = !current.isActive ||
        DateTime.now().difference(current.timestamp) > _staleAfter;
    if (isStaleNow != _isStale) {
      _isStale = isStaleNow;
      notifyListeners();
    }
  }

  void stopTracking() {
    _isTracking = false;
    _busLocationSubscription?.cancel();
    _busLocationSubscription = null;
    _staleCheckTimer?.cancel();
    _staleCheckTimer = null;
    _currentBusLocation = null;
    _previousBusLocation = null;
    _distanceToStop = 0.0;
    _etaMinutes = null;
    _hasNotifiedProximity = false;
    _hasError = false;
    _errorMessage = null;
    _isStale = false;
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