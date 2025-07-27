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

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final MapController _mapController = MapController();
  bool _followBus = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrackingService>().startTracking(widget.student);
    });
  }

  @override
  void dispose() {
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
    }
  }

  void _centerOnStop() {
    _mapController.move(
      LatLng(widget.student.stopLocation.latitude, widget.student.stopLocation.longitude),
      15.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tracking Bus ${widget.student.busNumber}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_followBus ? Icons.my_location : Icons.location_disabled),
            onPressed: () {
              setState(() {
                _followBus = !_followBus;
              });
              if (_followBus) {
                _centerOnBus();
              }
            },
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
              width: 40,
              height: 40,
              child: const Icon(
                Icons.location_pin,
                color: Colors.red,
                size: 40,
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
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.directions_bus,
                  color: Colors.blue,
                  size: 40,
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

          return Column(
            children: [
              // Status bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: trackingService.isTracking ? Colors.green.shade50 : Colors.red.shade50,
                child: Column(
                  children: [
                    Text(
                      trackingService.isTracking ? 'Tracking Active' : 'Tracking Inactive',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: trackingService.isTracking ? Colors.green : Colors.red,
                      ),
                    ),
                    if (trackingService.isTracking && busLocation != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Distance to stop: ${(trackingService.distanceToStop / 1000).toStringAsFixed(2)} km',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Last updated: ${busLocation.timestamp.hour}:${busLocation.timestamp.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
              // Map
              Expanded(
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
                    MarkerLayer(markers: markers),
                    if (busLocation != null)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: stopLocation,
                            radius: 500, // 500 meter notification radius
                            useRadiusInMeter: true,
                            color: Colors.blue.withOpacity(0.2),
                            borderColor: Colors.blue,
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),
                  ],
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
            backgroundColor: Colors.blue,
            child: const Icon(Icons.directions_bus, color: Colors.white),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "centerStop",
            onPressed: _centerOnStop,
            backgroundColor: Colors.red,
            child: const Icon(Icons.location_pin, color: Colors.white),
          ),
        ],
      ),
    );
  }
}