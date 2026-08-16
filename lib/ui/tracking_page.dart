import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/student_model.dart';
import '../../services/tracking_service.dart';

class LiveTrackingScreen extends StatefulWidget {
  final StudentModel student;

  const LiveTrackingScreen({super.key, required this.student});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> 
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _followBus = true;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    
    _slideController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrackingService>().startTracking(widget.student);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    context.read<TrackingService>().stopTracking();
    super.dispose();
  }

  void _centerOnBus() {
    final trackingService = context.read<TrackingService>();
    if (trackingService.currentBusLocation != null) {
      final busLocation = trackingService.currentBusLocation!;
      _mapController.move(
        LatLng(busLocation.location.latitude, busLocation.location.longitude),
        15.0,
      );
      setState(() {
        _followBus = true;
      });
    }
  }

  void _centerOnStop() {
    _mapController.move(
      LatLng(widget.student.stopLocation.latitude, widget.student.stopLocation.longitude),
      15.0,
    );
    setState(() {
      _followBus = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: Text(
          'Tracking Bus ${widget.student.busNumber}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  _followBus ? Icons.my_location_rounded : Icons.location_disabled_rounded,
                  key: ValueKey(_followBus),
                ),
              ),
              onPressed: () {
                setState(() {
                  _followBus = !_followBus;
                });
                if (_followBus) {
                  _centerOnBus();
                }
              },
              tooltip: _followBus ? 'Following Bus' : 'Follow Bus',
            ),
          ),
        ],
      ),
      body: Consumer<TrackingService>(
        builder: (context, trackingService, child) {
          final busLocation = trackingService.currentBusLocation;
          final stopLocation = LatLng(
            widget.student.stopLocation.latitude,
            widget.student.stopLocation.longitude,
          );

          List<Marker> markers = [
            // Bus stop marker
            Marker(
              point: stopLocation,
              width: 50,
              height: 50,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red[600]!.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.location_pin,
                  color: Colors.red[600],
                  size: 30,
                ),
              ),
            ),
          ];

          // Add bus marker if location is available
          if (busLocation != null) {
            final busLatLng = LatLng(
              busLocation.location.latitude,
              busLocation.location.longitude,
            );
            
            markers.add(
              Marker(
                point: busLatLng,
                width: 50,
                height: 50,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1565C0).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.directions_bus_rounded,
                          color: Color(0xFF1565C0),
                          size: 30,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );

            // Auto-center on bus if follow mode is enabled
            if (_followBus) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _mapController.move(busLatLng, _mapController.camera.zoom);
              });
            }
          }

          final status = _statusFor(trackingService);

          return Column(
            children: [
              // Status Bar
              SlideTransition(
                position: _slideAnimation,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [status.colorLight, status.colorDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: status.colorDark.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                status.icon,
                                color: Colors.white,
                                size: 24,
                                key: ValueKey(status.title),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  status.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  status.subtitle,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (trackingService.isTracking &&
                          !trackingService.hasError &&
                          !trackingService.isStale &&
                          busLocation != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Distance to Stop',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${(trackingService.distanceToStop / 1000).toStringAsFixed(2)} km',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.white.withOpacity(0.3),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ETA',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      trackingService.etaMinutes == null
                                          ? '--'
                                          : trackingService.etaMinutes! < 1
                                              ? 'Now'
                                              : '${trackingService.etaMinutes!.round()} min',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Map
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: stopLocation,
                        initialZoom: 13.0,
                        onMapEvent: (event) {
                          if (event is MapEventMoveEnd) {
                            setState(() {
                              _followBus = false;
                            });
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.bus_tracking_student',
                        ),
                        if (busLocation != null)
                          CircleLayer(
                            circles: [
                              CircleMarker(
                                point: stopLocation,
                                radius: 500, // 500 meter notification radius
                                useRadiusInMeter: true,
                                color: Colors.blue.withOpacity(0.1),
                                borderColor: const Color(0xFF1565C0),
                                borderStrokeWidth: 2,
                              ),
                            ],
                          ),
                        MarkerLayer(markers: markers),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "centerBus",
            onPressed: _centerOnBus,
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
            elevation: 4,
            child: const Icon(Icons.directions_bus_rounded),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "centerStop",
            onPressed: _centerOnStop,
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
            elevation: 4,
            child: const Icon(Icons.location_pin),
          ),
        ],
      ),
    );
  }

  _TrackingStatus _statusFor(TrackingService trackingService) {
    if (trackingService.hasError) {
      return _TrackingStatus(
        colorLight: Colors.orange[400]!,
        colorDark: Colors.orange[700]!,
        icon: Icons.cloud_off_rounded,
        title: 'Connection Issue',
        subtitle: trackingService.errorMessage ?? 'Unable to load bus location.',
      );
    }
    if (trackingService.isTracking && trackingService.isStale) {
      return _TrackingStatus(
        colorLight: Colors.amber[400]!,
        colorDark: Colors.amber[800]!,
        icon: Icons.signal_wifi_bad_rounded,
        title: 'Signal Lost',
        subtitle: 'Bus hasn\'t reported its location recently.',
      );
    }
    if (trackingService.isTracking) {
      return _TrackingStatus(
        colorLight: Colors.green[400]!,
        colorDark: Colors.green[600]!,
        icon: Icons.track_changes_rounded,
        title: 'Live Tracking',
        subtitle: 'Real-time bus location updates',
      );
    }
    return _TrackingStatus(
      colorLight: Colors.red[400]!,
      colorDark: Colors.red[600]!,
      icon: Icons.signal_cellular_off_rounded,
      title: 'Tracking Inactive',
      subtitle: 'Unable to connect to bus',
    );
  }
}

class _TrackingStatus {
  final Color colorLight;
  final Color colorDark;
  final IconData icon;
  final String title;
  final String subtitle;

  _TrackingStatus({
    required this.colorLight,
    required this.colorDark,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}