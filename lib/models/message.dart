import 'dart:convert';

enum MessageType { text, image, emergency, location }

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isMe;
  final int hopCount; // how many mesh hops this message travelled
  bool delivered;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.isMe,
    this.hopCount = 0,
    this.delivered = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'senderId': senderId,
    'senderName': senderName,
    'content': content,
    'type': type.index,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'isMe': isMe ? 1 : 0,
    'hopCount': hopCount,
    'delivered': delivered ? 1 : 0,
  };

  factory Message.fromMap(Map<String, dynamic> map) => Message(
    id: map['id'],
    senderId: map['senderId'],
    senderName: map['senderName'],
    content: map['content'],
    type: MessageType.values[map['type']],
    timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    isMe: map['isMe'] == 1,
    hopCount: map['hopCount'] ?? 0,
    delivered: map['delivered'] == 1,
  );

  // Serialized for BT/WiFi transmission
  String toJson() => jsonEncode(toMap());
  factory Message.fromJson(String json) => Message.fromMap(jsonDecode(json));
}