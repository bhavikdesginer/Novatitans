import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _lastPosition;
  StreamSubscription<Position>? _positionSub;
  final _positionController = StreamController<Position>.broadcast();

  Stream<Position> get positionStream => _positionController.stream;
  Position? get lastPosition => _lastPosition;

  Future<bool> init() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  Future<void> startTracking() async {
    final ok = await init();
    if (!ok) {
      debugPrint('[OFFGRID] Location permission denied');
      return;
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // metres
      ),
    ).listen((pos) {
      _lastPosition = pos;
      _positionController.add(pos);
    });
  }

  void stopTracking() {
    _positionSub?.cancel();
  }

  Future<Position?> getCurrentPosition() async {
    final ok = await init();
    if (!ok) return null;
    return Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  String formatCoords(Position pos) =>
      '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';

  void dispose() {
    _positionController.close();
    stopTracking();
  }
}