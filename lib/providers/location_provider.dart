// import 'package:flutter/foundation.dart';
// import 'package:geolocator/geolocator.dart';
// // import 'package:services/location_service.dart';

// class LocationProvider extends ChangeNotifier {
//   final _locationService = Location_Service();

//   Position? _position;
//   bool _tracking = false;

//   Position? get position => _position;
//   bool get tracking => _tracking;

//   LocationProvider() {
//     _locationService.positionStream.listen((pos) {
//       _position = pos;
//       notifyListeners();
//     });
//   }

//   Future<void> startTracking() async {
//     await _locationService.startTracking();
//     _tracking = true;
//     notifyListeners();
//   }

//   void stopTracking() {
//     _locationService.stopTracking();
//     _tracking = false;
//     notifyListeners();
//   }

//   Location_Service get service => _locationService;
// }



import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationService {
  final StreamController<Position> _positionStreamController =
      StreamController<Position>.broadcast();
  StreamSubscription<Position>? _positionSubscription;
  Position? _currentPosition;

  Stream<Position> get positionStream => _positionStreamController.stream;
  Position? get position => _currentPosition;

  Future<void> startTracking() async {
    if (_positionSubscription != null) return;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      _currentPosition = position;
      _positionStreamController.add(position);
    });
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  void dispose() {
    _positionSubscription?.cancel();
    _positionStreamController.close();
  }
}