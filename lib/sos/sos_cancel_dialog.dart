// lib/presentation/sos/widgets/sos_cancel_dialog.dart
// Confirmation dialog before cancelling an active SOS.
// Made deliberately hard to dismiss accidentally (no barrier tap, explicit buttons).

import 'package:flutter/material.dart';

class SOSCancelDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;

  const SOSCancelDialog({
    super.key,
    required this.onConfirm,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF141414),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF9B1B1B).withOpacity(0.2),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFD62828),
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cancel SOS?',
              style: TextStyle(
                color: Color(0xFFF5F5F5),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'This will stop all alerts, location tracking, and video recording.\n\nYour emergency contacts will be notified that you are safe.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 13,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onDismiss,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Color(0xFF2A2A2A)),
                      ),
                    ),
                    child: const Text(
                      'Keep Active',
                      style: TextStyle(
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: onConfirm,
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF9B1B1B).withOpacity(0.2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(
                            color: Color(0xFF9B1B1B), width: 0.8),
                      ),
                    ),
                    child: const Text(
                      'Yes, Cancel',
                      style: TextStyle(
                        color: Color(0xFFD62828),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}