import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';
import '../providers/message_provider.dart';
import '../providers/mesh_provider.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final mesh = context.read<MeshProvider>();
    context.read<MessageProvider>().sendMessage(
      content: text,
      senderId: mesh.nodeId,
      senderName: mesh.nodeName,
    );

    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = context.watch<MessageProvider>().messages;
    final mesh = context.watch<MeshProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('OFFGRID'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: mesh.isRunning
                  ? AppTheme.primary.withOpacity(0.15)
                  : AppTheme.danger.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: mesh.isRunning ? AppTheme.primary : AppTheme.danger,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: mesh.isRunning ? AppTheme.primary : AppTheme.danger,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  mesh.isRunning
                      ? '${mesh.connectedCount} node${mesh.connectedCount != 1 ? 's' : ''}'
                      : 'Offline',
                  style: TextStyle(
                    color: mesh.isRunning ? AppTheme.primary : AppTheme.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!mesh.isRunning)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppTheme.warning.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: AppTheme.warning, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Mesh is off — messages saved locally only',
                      style: TextStyle(color: AppTheme.warning, fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: mesh.toggleMesh,
                    child: const Text('Start', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          Expanded(
            child: messages.isEmpty
                ? _emptyState()
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (ctx, i) => _MessageBubble(msg: messages[i]),
            ),
          ),
          _InputBar(controller: _controller, onSend: _sendMessage),
        ],
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.chat_bubble_outline,
            size: 48, color: AppTheme.textMuted.withOpacity(0.4)),
        const SizedBox(height: 12),
        const Text('No messages yet',
            style: TextStyle(color: AppTheme.textMuted)),
        const SizedBox(height: 4),
        const Text('Messages travel through the mesh network',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
      ],
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  final Message msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isEmergency = msg.type == MessageType.emergency;
    final isMe = msg.isMe;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.surfaceAlt,
              child: Text(
                msg.senderName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isEmergency
                    ? AppTheme.danger.withOpacity(0.2)
                    : isMe
                    ? AppTheme.primary.withOpacity(0.15)
                    : AppTheme.surfaceAlt,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: isEmergency
                    ? Border.all(color: AppTheme.danger, width: 1)
                    : isMe
                    ? Border.all(
                    color: AppTheme.primary.withOpacity(0.3), width: 1)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      msg.senderName,
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  if (!isMe) const SizedBox(height: 2),
                  Text(
                    msg.content,
                    style: TextStyle(
                      color: isEmergency ? AppTheme.danger : AppTheme.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(msg.timestamp),
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 10),
                      ),
                      if (msg.hopCount > 0) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.lan, size: 10, color: AppTheme.textMuted),
                        const SizedBox(width: 2),
                        Text(
                          '${msg.hopCount}',
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 10),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _InputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.surfaceAlt)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (_) => onSend(),
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Send a message...',
                contentPadding:
                EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: AppTheme.background, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}