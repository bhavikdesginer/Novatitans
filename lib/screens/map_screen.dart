// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:provider/provider.dart';
// import '../providers/location_provider.dart';
// import '../providers/mesh_provider.dart';
// import '../providers/message_provider.dart';
// import '../models/message.dart';
// import '../theme/app_theme.dart';

// class MapScreen extends StatefulWidget {
//   const MapScreen({super.key});

//   @override
//   State<MapScreen> createState() => _MapScreenState();
// }

// class _MapScreenState extends State<MapScreen> {
//   final _mapController = MapController();
//   bool _followUser = true;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<LocationProvider>().startTracking();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final locationProvider = context.watch<LocationProvider>();
//     final mesh = context.watch<MeshProvider>();
//     final messages = context.watch<MessageProvider>().messages;

//     final pos = locationProvider.position;
//     final myLocation =
//     pos != null ? LatLng(pos.latitude, pos.longitude) : null;

//     // Build markers for location-sharing messages
//     final locationMarkers = messages
//         .where((m) => m.type == MessageType.location)
//         .map((m) {
//       try {
//         final parts = m.content.split(',');
//         final lat = double.parse(parts[0].trim());
//         final lng = double.parse(parts[1].trim());
//         return Marker(
//           point: LatLng(lat, lng),
//           width: 40,
//           height: 40,
//           child: _PeerMarker(name: m.senderName),
//         );
//       } catch (_) {
//         return null;
//       }
//     }).whereType<Marker>().toList();

//     if (myLocation != null && _followUser) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         try {
//           _mapController.move(myLocation, _mapController.camera.zoom);
//         } catch (_) {}
//       });
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('NAVIGATION'),
//         actions: [
//           IconButton(
//             icon: Icon(
//               _followUser ? Icons.my_location : Icons.location_searching,
//               color: _followUser ? AppTheme.primary : AppTheme.textMuted,
//             ),
//             onPressed: () => setState(() => _followUser = !_followUser),
//           ),
//           if (pos != null)
//             IconButton(
//               icon: const Icon(Icons.share_location),
//               onPressed: () => _shareLocation(context, pos.latitude, pos.longitude),
//               tooltip: 'Share my location',
//             ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           FlutterMap(
//             mapController: _mapController,
//             options: MapOptions(
//               initialCenter: myLocation ?? const LatLng(20.5937, 78.9629),
//               initialZoom: 14,
//               onTap: (_, __) => setState(() => _followUser = false),
//             ),
//             children: [
//               // Tile layer — swap URL for offline tile server in production
//               TileLayer(
//                 urlTemplate:
//                 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//                 userAgentPackageName: 'com.offgrid.app',
//                 // For truly offline: use MBTiles tile provider
//               ),
//               if (myLocation != null)
//                 MarkerLayer(
//                   markers: [
//                     Marker(
//                       point: myLocation,
//                       width: 50,
//                       height: 50,
//                       child: _MyLocationMarker(),
//                     ),
//                   ],
//                 ),
//               MarkerLayer(markers: locationMarkers),
//             ],
//           ),
//           // Coordinates HUD
//           if (pos != null)
//             Positioned(
//               bottom: 16,
//               left: 16,
//               child: Container(
//                 padding:
//                 const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                 decoration: BoxDecoration(
//                   color: AppTheme.surface.withOpacity(0.9),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(
//                       color: AppTheme.primary.withOpacity(0.3)),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
//                       style: const TextStyle(
//                           color: AppTheme.primary,
//                           fontSize: 12,
//                           fontFamily: 'monospace'),
//                     ),
//                     if (pos.altitude != 0)
//                       Text(
//                         'Alt: ${pos.altitude.toStringAsFixed(1)}m',
//                         style: const TextStyle(
//                             color: AppTheme.textMuted, fontSize: 11),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           // Offline warning
//           Positioned(
//             top: 0,
//             left: 0,
//             right: 0,
//             child: Container(
//               padding: const EdgeInsets.symmetric(vertical: 4),
//               color: AppTheme.warning.withOpacity(0.15),
//               child: const Text(
//                 'ℹ️  For offline use, cache tiles or use MBTiles bundle',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(color: AppTheme.warning, fontSize: 11),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _shareLocation(BuildContext ctx, double lat, double lng) {
//     final mesh = ctx.read<MeshProvider>();
//     ctx.read<MessageProvider>().sendMessage(
//       content: '$lat, $lng',
//       senderId: mesh.nodeId,
//       senderName: mesh.nodeName,
//       type: MessageType.location,
//     );
//     ScaffoldMessenger.of(ctx).showSnackBar(
//       const SnackBar(
//         content: Text('Location shared to mesh'),
//         backgroundColor: AppTheme.primary,
//         duration: Duration(seconds: 2),
//       ),
//     );
//   }
// }

// class _MyLocationMarker extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       alignment: Alignment.center,
//       children: [
//         Container(
//           width: 50,
//           height: 50,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: AppTheme.primary.withOpacity(0.15),
//           ),
//         ),
//         Container(
//           width: 20,
//           height: 20,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: AppTheme.primary,
//             border: Border.all(color: AppTheme.background, width: 2),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _PeerMarker extends StatelessWidget {
//   final String name;
//   const _PeerMarker({required this.name});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//           decoration: BoxDecoration(
//             color: AppTheme.warning,
//             borderRadius: BorderRadius.circular(4),
//           ),
//           child: Text(name,
//               style: const TextStyle(
//                   color: AppTheme.background,
//                   fontSize: 10,
//                   fontWeight: FontWeight.bold)),
//         ),
//         const Icon(Icons.location_on, color: AppTheme.warning, size: 20),
//       ],
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../providers/mesh_provider.dart';
import '../providers/message_provider.dart';
import '../models/message.dart';
import '../theme/app_theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapController = MapController();
  bool _followUser = true;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationService>().startTracking();
    });
  }

  @override
  Widget build(BuildContext context) {
    // final locationProvider = context.watch<LocationService>();
    final locationProvider = context.watch<LocationService>();
    final mesh = context.watch<MeshProvider>();
    final messages = context.watch<MessageProvider>().messages;

    final pos = locationProvider.position;
    final myLocation =
        pos != null ? LatLng(pos.latitude, pos.longitude) : null;

    // Build markers for location-sharing messages
    final locationMarkers = messages
        .where((m) => m.type == MessageType.location)
        .map((m) {
      try {
        final parts = m.content.split(',');
        final lat = double.parse(parts[0].trim());
        final lng = double.parse(parts[1].trim());
        return Marker(
          point: LatLng(lat, lng),
          width: 40,
          height: 40,
          child: _PeerMarker(name: m.senderName),
        );
      } catch (_) {
        return null;
      }
    }).whereType<Marker>().toList();

    if (myLocation != null && _followUser) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _mapController.move(myLocation, _mapController.camera.zoom);
        } catch (_) {}
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('NAVIGATION'),
        actions: [
          IconButton(
            icon: Icon(
              _followUser ? Icons.my_location : Icons.location_searching,
              color: _followUser ? AppTheme.primary : AppTheme.textMuted,
            ),
            onPressed: () => setState(() => _followUser = !_followUser),
          ),
          if (pos != null)
            IconButton(
              icon: const Icon(Icons.share_location),
              onPressed: () => _shareLocation(context, pos.latitude, pos.longitude),
              tooltip: 'Share my location',
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: myLocation ?? const LatLng(20.5937, 78.9629),
              initialZoom: 14,
              onTap: (_, __) => setState(() => _followUser = false),
            ),
            children: [
              // Tile layer — swap URL for offline tile server in production
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.offgrid.app',
                // For truly offline: use MBTiles tile provider
              ),
              if (myLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: myLocation,
                      width: 50,
                      height: 50,
                      child: _MyLocationMarker(),
                    ),
                  ],
                ),
              MarkerLayer(markers: locationMarkers),
            ],
          ),
          // Coordinates HUD
          if (pos != null)
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontFamily: 'monospace'),
                    ),
                    if (pos.altitude != 0)
                      Text(
                        'Alt: ${pos.altitude.toStringAsFixed(1)}m',
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 11),
                      ),
                  ],
                ),
              ),
            ),
          // Offline warning
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: AppTheme.warning.withOpacity(0.15),
              child: const Text(
                'ℹ️  For offline use, cache tiles or use MBTiles bundle',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.warning, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareLocation(BuildContext ctx, double lat, double lng) {
    final mesh = ctx.read<MeshProvider>();
    ctx.read<MessageProvider>().sendMessage(
          content: '$lat, $lng',
          senderId: mesh.nodeId,
          senderName: mesh.nodeName,
          type: MessageType.location,
        );
    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(
        content: Text('Location shared to mesh'),
        backgroundColor: AppTheme.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _MyLocationMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primary.withOpacity(0.15),
          ),
        ),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primary,
            border: Border.all(color: AppTheme.background, width: 2),
          ),
        ),
      ],
    );
  }
}

class _PeerMarker extends StatelessWidget {
  final String name;
  const _PeerMarker({required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.warning,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(name,
              style: const TextStyle(
                  color: AppTheme.background,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ),
        const Icon(Icons.location_on, color: AppTheme.warning, size: 20),
      ],
    );
  }
}