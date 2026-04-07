import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mesh_peer.dart';
import '../providers/mesh_provider.dart';
import '../theme/app_theme.dart';

class MeshScreen extends StatelessWidget {
  const MeshScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mesh = context.watch<MeshProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MESH NETWORK'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showRenameDialog(context, mesh),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NodeCard(mesh: mesh),
            const SizedBox(height: 20),
            _MeshToggle(mesh: mesh),
            const SizedBox(height: 24),
            _PeerList(peers: mesh.peers),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, MeshProvider mesh) {
    final ctrl = TextEditingController(text: mesh.nodeName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Set Your Node Name',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(hintText: 'e.g. Survivor-Alpha'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              mesh.setNodeName(ctrl.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _NodeCard extends StatelessWidget {
  final MeshProvider mesh;
  const _NodeCard({required this.mesh});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.router, color: AppTheme.primary),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(mesh.nodeName,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 2),
              Text(
                'ID: ${mesh.nodeId.substring(0, 12)}...',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                'YOUR NODE',
                style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MeshToggle extends StatelessWidget {
  final MeshProvider mesh;
  const _MeshToggle({required this.mesh});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: mesh.toggleMesh,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: mesh.isRunning
              ? AppTheme.primary.withOpacity(0.1)
              : AppTheme.danger.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: mesh.isRunning ? AppTheme.primary : AppTheme.danger,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              mesh.isRunning ? Icons.wifi_tethering : Icons.wifi_tethering_off,
              color: mesh.isRunning ? AppTheme.primary : AppTheme.danger,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mesh.isRunning ? 'Mesh Active' : 'Mesh Offline',
                    style: TextStyle(
                      color: mesh.isRunning ? AppTheme.primary : AppTheme.danger,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    mesh.isRunning
                        ? '${mesh.connectedCount} connected · ${mesh.totalVisible} visible'
                        : 'Tap to start broadcasting',
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Switch(
              value: mesh.isRunning,
              onChanged: (_) => mesh.toggleMesh(),
              activeColor: AppTheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _PeerList extends StatelessWidget {
  final List<MeshPeer> peers;
  const _PeerList({required this.peers});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NEARBY NODES (${peers.length})',
          style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (peers.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('No nodes detected yet',
                  style: TextStyle(color: AppTheme.textMuted)),
            ),
          )
        else
          ...peers.map((peer) => _PeerTile(peer: peer)),
      ],
    );
  }
}

class _PeerTile extends StatelessWidget {
  final MeshPeer peer;
  const _PeerTile({required this.peer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: peer.isConnected
            ? Border.all(color: AppTheme.primary.withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          Icon(
            peer.connectionType == 'bluetooth'
                ? Icons.bluetooth
                : Icons.wifi,
            color: peer.isConnected ? AppTheme.primary : AppTheme.textMuted,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(peer.name,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500)),
                Text(
                  peer.connectionType.toUpperCase(),
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          _SignalBar(strength: peer.signalStrength),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: peer.isConnected
                  ? AppTheme.primary.withOpacity(0.15)
                  : AppTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              peer.isConnected ? 'Connected' : 'Visible',
              style: TextStyle(
                color:
                peer.isConnected ? AppTheme.primary : AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalBar extends StatelessWidget {
  final int strength; // 0-100
  const _SignalBar({required this.strength});

  @override
  Widget build(BuildContext context) {
    final bars = (strength / 25).ceil().clamp(0, 4);
    return Row(
      children: List.generate(4, (i) {
        return Container(
          margin: const EdgeInsets.only(right: 2),
          width: 4,
          height: 8.0 + (i * 3),
          decoration: BoxDecoration(
            color: i < bars ? AppTheme.primary : AppTheme.surfaceAlt,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}