import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/message_provider.dart';
import '../providers/mesh_provider.dart';
import '../theme/app_theme.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final _controller = TextEditingController();
  bool _isBroadcasting = false;

  final _presets = [
    'Need medical assistance immediately',
    'Trapped — send help to my location',
    'Under attack — need evacuation',
    'Water/food supplies critical',
    'All clear — area is safe',
  ];

  Future<void> _broadcast(String message) async {
    if (_isBroadcasting) return;
    setState(() => _isBroadcasting = true);

    final mesh = context.read<MeshProvider>();
    await context.read<MessageProvider>().sendEmergencyBroadcast(
      senderId: mesh.nodeId,
      senderName: mesh.nodeName,
      message: message,
    );

    context.read<MessageProvider>().clearEmergencyAlert();

    if (mounted) setState(() => _isBroadcasting = false);
  }

  @override
  Widget build(BuildContext context) {
    final emergencyMsgs =
        context.watch<MessageProvider>().emergencyMessages;
    final mesh = context.watch<MeshProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('EMERGENCY'),
        titleTextStyle: const TextStyle(
          color: AppTheme.danger,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
        iconTheme: const IconThemeData(color: AppTheme.danger),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SOS Button
            _SOSButton(isBroadcasting: _isBroadcasting, onTap: () {
              _broadcast('SOS — IMMEDIATE HELP NEEDED');
            }),
            const SizedBox(height: 24),

            // Custom message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CUSTOM ALERT',
                      style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    maxLines: 3,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                        hintText: 'Describe your situation...'),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final text = _controller.text.trim();
                        if (text.isNotEmpty) _broadcast(text);
                      },
                      icon: const Icon(Icons.campaign, size: 18),
                      label: const Text('BROADCAST'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.danger,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Presets
            const Text('QUICK ALERTS',
                style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            ..._presets.map((p) => GestureDetector(
              onTap: () => _broadcast(p),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.danger.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber,
                        color: AppTheme.danger, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(p,
                          style: const TextStyle(
                              color: AppTheme.textPrimary)),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppTheme.textMuted),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 24),

            // Received emergency log
            if (emergencyMsgs.isNotEmpty) ...[
              const Text('RECEIVED ALERTS',
                  style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              ...emergencyMsgs.reversed.map((msg) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border:
                  Border.all(color: AppTheme.danger.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.campaign,
                            color: AppTheme.danger, size: 16),
                        const SizedBox(width: 6),
                        Text(msg.senderName,
                            style: const TextStyle(
                                color: AppTheme.danger,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                        const Spacer(),
                        Text(
                          DateFormat('HH:mm').format(msg.timestamp),
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(msg.content,
                        style: const TextStyle(
                            color: AppTheme.textPrimary)),
                    if (msg.hopCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Relayed via ${msg.hopCount} node${msg.hopCount > 1 ? 's' : ''}',
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 11),
                        ),
                      ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}

class _SOSButton extends StatelessWidget {
  final bool isBroadcasting;
  final VoidCallback onTap;

  const _SOSButton({required this.isBroadcasting, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isBroadcasting ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppTheme.danger.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.danger, width: 2),
        ),
        child: Column(
          children: [
            Icon(
              isBroadcasting ? Icons.broadcast_on_personal : Icons.sos,
              color: AppTheme.danger,
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(
              isBroadcasting ? 'BROADCASTING...' : 'SOS',
              style: const TextStyle(
                color: AppTheme.danger,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap to send emergency signal\nthrough the entire mesh network',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}