class MeshPeer {
  final String id;
  final String name;
  final String connectionType; // 'bluetooth' | 'wifi_direct'
  final int signalStrength;    // RSSI or estimated strength 0-100
  final DateTime lastSeen;
  bool isConnected;

  MeshPeer({
    required this.id,
    required this.name,
    required this.connectionType,
    required this.signalStrength,
    required this.lastSeen,
    this.isConnected = false,
  });

  String get shortId => id.length > 8 ? id.substring(0, 8) : id;
}