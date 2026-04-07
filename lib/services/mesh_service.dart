import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../models/mesh_peer.dart';
import 'database_service.dart';

/// Handles both Bluetooth LE scanning/advertising and WiFi Direct (Nearby Connections)
/// Every device is simultaneously a sender AND relay node.
class MeshService {
  static final MeshService _instance = MeshService._internal();
  factory MeshService() => _instance;
  MeshService._internal();

  // ── State ────────────────────────────────────────────────────────────────
  final _db = DatabaseService();
  final _uuid = const Uuid();

  String _nodeId = '';
  String _nodeName = '';
  bool _isRunning = false;

  final Map<String, MeshPeer> _peers = {};
  final _peersController = StreamController<List<MeshPeer>>.broadcast();
  final _incomingController = StreamController<Message>.broadcast();

  Stream<List<MeshPeer>> get peersStream => _peersController.stream;
  Stream<Message> get incomingMessages => _incomingController.stream;
  List<MeshPeer> get peers => List.unmodifiable(_peers.values);
  bool get isRunning => _isRunning;
  String get nodeId => _nodeId;
  String get nodeName => _nodeName;

  // ── Init ─────────────────────────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _nodeId = prefs.getString('node_id') ?? _uuid.v4();
    _nodeName = prefs.getString('node_name') ?? 'Survivor-${_nodeId.substring(0, 4)}';
    await prefs.setString('node_id', _nodeId);
    await prefs.setString('node_name', _nodeName);
  }

  Future<void> setNodeName(String name) async {
    _nodeName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('node_name', name);
  }

  // ── Start / Stop ──────────────────────────────────────────────────────────
  Future<void> startMesh() async {
    if (_isRunning) return;
    _isRunning = true;
    await _startNearbyConnections();
    await _startBluetoothScan();
    debugPrint('[OFFGRID] Mesh started — node: $_nodeId');
  }

  Future<void> stopMesh() async {
    _isRunning = false;
    await Nearby().stopAllEndpoints();
    await Nearby().stopAdvertising();
    await Nearby().stopDiscovery();
    FlutterBluePlus.stopScan();
    debugPrint('[OFFGRID] Mesh stopped');
  }

  // ── WiFi Direct via Nearby Connections ───────────────────────────────────
  Future<void> _startNearbyConnections() async {
    try {
      await Nearby().startAdvertising(
        _nodeName,
        Strategy.P2P_CLUSTER,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
        serviceId: 'com.offgrid.mesh',
      );

      await Nearby().startDiscovery(
        _nodeName,
        Strategy.P2P_CLUSTER,
        onEndpointFound: (id, name, serviceId) {
          debugPrint('[OFFGRID] Found peer: $name ($id)');
          Nearby().requestConnection(
            _nodeName,
            id,
            onConnectionInitiated: _onConnectionInitiated,
            onConnectionResult: _onConnectionResult,
            onDisconnected: _onDisconnected,
          );
        },
        onEndpointLost: (id) {
          _peers[id]?.isConnected = false;
          _notifyPeers();
        },
        serviceId: 'com.offgrid.mesh',
      );
    } catch (e) {
      debugPrint('[OFFGRID] Nearby Connections error: $e');
    }
  }

  void _onConnectionInitiated(String id, ConnectionInfo info) {
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endpointId, payload) {
        if (payload.type == PayloadType.BYTES && payload.bytes != null) {
          final raw = utf8.decode(payload.bytes!);
          _handleIncomingRaw(raw, endpointId, 'wifi_direct');
        }
      },
      onPayloadTransferUpdate: (endpointId, update) {},
    );
  }

  void _onConnectionResult(String id, Status status) {
    if (status == Status.CONNECTED) {
      _peers[id] = MeshPeer(
        id: id,
        name: 'Peer-${id.substring(0, 4)}',
        connectionType: 'wifi_direct',
        signalStrength: 80,
        lastSeen: DateTime.now(),
        isConnected: true,
      );
      _notifyPeers();
    }
  }

  void _onDisconnected(String id) {
    _peers[id]?.isConnected = false;
    _notifyPeers();
  }

  // ── Bluetooth scan (detect nearby BT devices as potential peers) ──────────
  Future<void> _startBluetoothScan() async {
    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        continuousUpdates: true,
      );

      FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final deviceId = r.device.remoteId.str;
          if (!_peers.containsKey(deviceId)) {
            _peers[deviceId] = MeshPeer(
              id: deviceId,
              name: r.device.platformName.isEmpty
                  ? 'BT-${deviceId.substring(0, 5)}'
                  : r.device.platformName,
              connectionType: 'bluetooth',
              signalStrength: _rssiToPercent(r.rssi),
              lastSeen: DateTime.now(),
            );
            _notifyPeers();
          }
        }
      });

      // Restart scan every 20s
      Timer.periodic(const Duration(seconds: 20), (_) async {
        if (_isRunning) {
          await FlutterBluePlus.startScan(
              timeout: const Duration(seconds: 15),
              continuousUpdates: true);
        }
      });
    } catch (e) {
      debugPrint('[OFFGRID] BT scan error: $e');
    }
  }

  // ── Send message to all connected WiFi Direct peers ───────────────────────
  Future<void> broadcast(Message msg) async {
    await _db.markMessageSeen(msg.id);
    await _db.insertMessage(msg);

    final payload = msg.toJson();
    for (final peer in _peers.values) {
      if (peer.isConnected && peer.connectionType == 'wifi_direct') {
        try {
          await Nearby().sendBytesPayload(
              peer.id, Uint8List.fromList(utf8.encode(payload)));
        } catch (e) {
          debugPrint('[OFFGRID] Send failed to ${peer.id}: $e');
        }
      }
    }
  }

  // ── Handle incoming raw payload (store-and-forward relay) ─────────────────
  Future<void> _handleIncomingRaw(
      String raw, String fromPeerId, String connType) async {
    try {
      final msg = Message.fromJson(raw);

      // Deduplication — don't relay what we've already seen
      if (await _db.hasSeenMessage(msg.id)) return;
      await _db.markMessageSeen(msg.id);
      await _db.insertMessage(msg);

      _incomingController.add(msg);

      // Relay to all OTHER connected peers (store-and-forward mesh)
      final relayed = Message(
        id: msg.id,
        senderId: msg.senderId,
        senderName: msg.senderName,
        content: msg.content,
        type: msg.type,
        timestamp: msg.timestamp,
        isMe: false,
        hopCount: msg.hopCount + 1,
      );
      final relayPayload = relayed.toJson();

      for (final peer in _peers.values) {
        if (peer.isConnected &&
            peer.connectionType == 'wifi_direct' &&
            peer.id != fromPeerId) {
          try {
            await Nearby().sendBytesPayload(
                peer.id, Uint8List.fromList(utf8.encode(relayPayload)));
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('[OFFGRID] Parse error: $e');
    }
  }

  void _notifyPeers() {
    _peersController.add(peers);
  }

  int _rssiToPercent(int rssi) {
    if (rssi >= -50) return 100;
    if (rssi <= -100) return 0;
    return ((rssi + 100) * 2).clamp(0, 100);
  }

  void dispose() {
    _peersController.close();
    _incomingController.close();
  }
}