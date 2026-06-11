// lib/presentation/sos/widgets/sos_active_panel.dart
// Shown when an SOS is live. Displays:
//   • Live elapsed timer
//   • Status indicators (SMS sent, location tracking, video recording)
//   • Location coordinates
//   • Cancel button (with confirmation dialog)

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'sos_bloc.dart';
import 'sos_cancel_dialog.dart';

class SOSActivePanel extends StatefulWidget {
  final SOSActive state;

  const SOSActivePanel({super.key, required this.state});

  @override
  State<SOSActivePanel> createState() => _SOSActivePanelState();
}

class _SOSActivePanelState extends State<SOSActivePanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blinkCtrl;
  late final Animation<double> _blinkOpacity;
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = widget.state.event.timestamp;

    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _blinkOpacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _blinkCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _blinkCtrl.dispose();
    super.dispose();
  }

  String _formatElapsed() {
    final elapsed = DateTime.now().difference(_startTime);
    final m = elapsed.inMinutes.toString().padLeft(2, '0');
    final s = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.state.event;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ── LIVE badge ──
            AnimatedBuilder(
              animation: _blinkOpacity,
              builder: (_, __) => Opacity(
                opacity: _blinkOpacity.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD62828).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFFD62828).withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.circle, color: Color(0xFFD62828), size: 8),
                      SizedBox(width: 6),
                      Text(
                        'SOS ACTIVE',
                        style: TextStyle(
                          color: Color(0xFFD62828),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Elapsed timer ──
            StreamBuilder(
              stream: Stream.periodic(const Duration(seconds: 1)),
              builder: (context, _) {
                return Text(
                  _formatElapsed(),
                  style: const TextStyle(
                    color: Color(0xFFF5F5F5),
                    fontSize: 64,
                    fontWeight: FontWeight.w200,
                    letterSpacing: 4,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                );
              },
            ),

            const Text(
              'elapsed',
              style: TextStyle(
                color: Color(0xFF555555),
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 32),

            // ── Status items ──
            _StatusItem(
              icon: Icons.send_rounded,
              label: 'SMS sent to emergency contacts',
              status: 'Done',
              statusColor: const Color(0xFF4CAF50),
            ),
            const SizedBox(height: 10),
            _StatusItem(
              icon: Icons.location_on_rounded,
              label: 'Live location: ${event.latitude.toStringAsFixed(5)}, '
                  '${event.longitude.toStringAsFixed(5)}',
              status: 'Tracking',
              statusColor: const Color(0xFFD62828),
            ),
            const SizedBox(height: 10),
            _StatusItem(
              icon: Icons.videocam_rounded,
              label: 'Video recording in progress',
              status: 'Recording',
              statusColor: const Color(0xFFD62828),
            ),
            const SizedBox(height: 10),
            _StatusItem(
              icon: Icons.people_outline_rounded,
              label: 'Nearby users alerted',
              status: 'Sent',
              statusColor: const Color(0xFF4CAF50),
            ),

            const Spacer(),

            // ── Cancel button ──
            _CancelSOSButton(eventId: event.id),

            const SizedBox(height: 12),
            const Text(
              'Cancelling will stop all alerts and recordings.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF444444),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String status;
  final Color statusColor;

  const _StatusItem({
    required this.icon,
    required this.label,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E1E1E)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF555555), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFAAAAAA),
                fontSize: 13,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelSOSButton extends StatelessWidget {
  final String eventId;
  const _CancelSOSButton({required this.eventId});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _showCancelDialog(context),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF333333)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text(
          'Cancel SOS',
          style: TextStyle(
            color: Color(0xFF888888),
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SOSCancelDialog(
        onConfirm: () {
          Navigator.pop(context);
          context
              .read<SOSBloc>()
              .add(SOSCancelRequested(eventId));
        },
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }
}