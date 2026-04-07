import 'package:flutter/foundation.dart';
import '../models/mesh_peer.dart';
import '../services/mesh_service.dart';

class MeshProvider extends ChangeNotifier {
  final _mesh = MeshService();

  List<MeshPeer> _peers = [];
  bool _isRunning = false;
  String _nodeId = '';
  String _nodeName = '';

  List<MeshPeer> get peers => _peers;
  bool get isRunning => _isRunning;
  int get connectedCount => _peers.where((p) => p.isConnected).length;
  int get totalVisible => _peers.length;
  String get nodeId => _nodeId;
  String get nodeName => _nodeName;

  MeshProvider() {
    _init();
  }

  Future<void> _init() async {
    await _mesh.init();
    _nodeId = _mesh.nodeId;
    _nodeName = _mesh.nodeName;
    _mesh.peersStream.listen((peers) {
      _peers = peers;
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> toggleMesh() async {
    if (_isRunning) {
      await _mesh.stopMesh();
      _isRunning = false;
    } else {
      await _mesh.startMesh();
      _isRunning = true;
    }
    notifyListeners();
  }

  Future<void> setNodeName(String name) async {
    await _mesh.setNodeName(name);
    _nodeName = name;
    notifyListeners();
  }

  MeshService get service => _mesh;
}