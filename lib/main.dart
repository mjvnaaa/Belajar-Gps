import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geolocator Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePages(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePages extends StatefulWidget {
  const MyHomePages({Key? key}) : super(key: key);

  @override
  _MyHomePagesState createState() => _MyHomePagesState();
}

class _MyHomePagesState extends State<MyHomePages> {
  Position? _currentPosition;
  String? _errorMessage;
  String? _currentAddress;
  double? _distanceInMeters;

  final double _pnbLatitude = 1.4966;
  final double _pnbLongitude = 124.8483;

  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<Position> _getPermissionAndLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Layanan lokasi nonaktif. Silakan aktifkan GPS.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Izin lokasi ditolak permanen. Silakan ubah di pengaturan HP.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  void _handleGetLocation() async {
    try {
      Position position = await _getPermissionAndLocation();
      setState(() {
        _currentPosition = position;
        _errorMessage = null;
      });

      // panggil fungsi baru setelah dapat lokasi
      _getAddressFromLatLng(position);
      _calculateDistance(position);

    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst("Exception: ", "");
      });
    }
  }

  void _handleStartTracking() {
    if (_positionStreamSubscription != null) {
      setState(() {
        _errorMessage = "Pelacakan sudah aktif.";
      });
      return;
    }

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (Position position) {
        setState(() {
          _currentPosition = position;
          _errorMessage = null;
        });

        // memanggil fungsi baru di dalam stream
        _getAddressFromLatLng(position);
        _calculateDistance(position);
      },
      onError: (error) {
        setState(() {
          _errorMessage = error.toString();
        });
      },
    );

    setState(() {
      _errorMessage = "Pelacakan dimulai...";
    });
  }

  void _handleStopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    setState(() {
      _errorMessage = "Pelacakan dihentikan.";
    });
  }

  // geocoding
  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks[0];

      setState(() {
        _currentAddress =
            "${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}";
      });
    } catch (e) {
      setState(() {
        _currentAddress = "Tidak dapat mengambil alamat.";
      });
    }
  }

  // fungsi jarak ke PNB
  void _calculateDistance(Position position) {
    double distance = Geolocator.distanceBetween(
      _pnbLatitude,
      _pnbLongitude,
      position.latitude,
      position.longitude,
    );

    setState(() {
      _distanceInMeters = distance;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Geolocator (Alamat & Jarak)"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, size: 50, color: Colors.blue),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 150),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_errorMessage != null)
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      
                      const SizedBox(height: 16),

                      if (_currentPosition != null)
                        Text(
                          "Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}\nLng: ${_currentPosition!.longitude.toStringAsFixed(4)}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      
                      const SizedBox(height: 10),

                      if (_currentAddress != null)
                        Text(
                          "Alamat:\n$_currentAddress",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      
                      const SizedBox(height: 10),

                      if (_distanceInMeters != null)
                        Text(
                          "Jarak ke PNB: ${_distanceInMeters!.toStringAsFixed(2)} meter",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),

                ElevatedButton.icon(
                  icon: const Icon(Icons.location_searching),
                  label: const Text('Dapatkan Lokasi Sekarang'),
                  onPressed: _handleGetLocation,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Mulai Lacak'),
                      onPressed: _handleStartTracking,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.stop),
                      label: const Text('Henti Lacak'),
                      onPressed: _handleStopTracking,
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}