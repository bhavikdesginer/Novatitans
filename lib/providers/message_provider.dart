import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../services/database_service.dart';
import '../services/mesh_service.dart';

class MessageProvider extends ChangeNotifier {
  final _db = DatabaseService();
  final _mesh = MeshService();
  final _uuid = const Uuid();

  List<Message> _messages = [];
  bool _hasEmergencyAlert = false;

  List<Message> get messages => _messages;
  List<Message> get emergencyMessages =>
      _messages.where((m) => m.type == MessageType.emergency).toList();
  bool get hasEmergencyAlert => _hasEmergencyAlert;

  MessageProvider() {
    _loadMessages();
    _listenToMesh();
  }

  Future<void> _loadMessages() async {
    _messages = await _db.getAllMessages();
    notifyListeners();
  }

  void _listenToMesh() {
    _mesh.incomingMessages.listen((msg) {
      if (!_messages.any((m) => m.id == msg.id)) {
        _messages.add(msg);
        if (msg.type == MessageType.emergency) {
          _hasEmergencyAlert = true;
        }
        notifyListeners();
      }
    });
  }

  Future<void> sendMessage({
    required String content,
    required String senderId,
    required String senderName,
    MessageType type = MessageType.text,
  }) async {
    final msg = Message(
      id: _uuid.v4(),
      senderId: senderId,
      senderName: senderName,
      content: content,
      type: type,
      timestamp: DateTime.now(),
      isMe: true,
    );

    _messages.add(msg);
    notifyListeners();

    await _mesh.broadcast(msg);
  }

  Future<void> sendEmergencyBroadcast({
    required String senderId,
    required String senderName,
    required String message,
  }) async {
    await sendMessage(
      content: '🆘 EMERGENCY: $message',
      senderId: senderId,
      senderName: senderName,
      type: MessageType.emergency,
    );
  }

  void clearEmergencyAlert() {
    _hasEmergencyAlert = false;
    notifyListeners();
  }
}