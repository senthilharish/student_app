import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/student_model.dart';
import '../../data/firebase_service.dart';

class DestinationSetupScreen extends StatefulWidget {
  final String name;
  final String rollNumber;
  final String busNumber;

  const DestinationSetupScreen({
    super.key,
    required this.name,
    required this.rollNumber,
    required this.busNumber,
  });

  @override
  State<DestinationSetupScreen> createState() => _DestinationSetupScreenState();
}

class _DestinationSetupScreenState extends State<DestinationSetupScreen> {
  final MapController _mapController = MapController();
  LatLng _selectedLocation = const LatLng(11.0168, 76.9558); // Coimbatore default
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
        });
        _mapController.move(_selectedLocation, 15.0);
      }
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  Future<void> _saveStudentProfile() async {
    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final user = authService.currentUser;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      
      final student = StudentModel(
        uid: user.uid,
        rollNumber:int.parse(widget.rollNumber),
        name: widget.name,
        busNumber: widget.busNumber,
        stopLocation: GeoPoint(_selectedLocation.latitude, _selectedLocation.longitude),
        fcmToken:'',
      );

      await authService.updateStudentProfile(student);
      
      if (mounted) {
        // The AuthWrapper will automatically navigate to HomeScreen
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Your Bus Stop'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Text(
              'Tap on the map to select your bus stop location',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedLocation,
                initialZoom: 15.0,
                onTap: (tapPosition, point) {
                  setState(() {
                    _selectedLocation = point;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.bus_tracking_student',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Selected Location:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${_selectedLocation.latitude.toStringAsFixed(4)}, ${_selectedLocation.longitude.toStringAsFixed(4)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveStudentProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save and Continue'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}