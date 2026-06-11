// lib/presentation/sos/widgets/sos_button.dart
// The centrepiece of the app.
// Press-and-hold for 3 seconds to trigger — prevents accidental activation.
// Visual feedback: circular fill progress + pulsing glow rings.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'sos_bloc.dart';
import 'vibration_channel.dart';

class SOSButton extends StatefulWidget {
  const SOSButton({super.key});

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton> with TickerProviderStateMixin {
  // ── Hold-to-trigger progress ──────────────────────────
  late final AnimationController _holdCtrl;
  late final Animation<double> _holdProgress;

  // ── Continuous idle pulse ─────────────────────────────
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;

  // ── Scale down on press ───────────────────────────────
  late final AnimationController _pressCtrl;
  late final Animation<double> _pressScale;

  bool _isHolding = false;
  static const Duration _holdDuration = Duration(milliseconds: 3000);

  @override
  void initState() {
    super.initState();

    _holdCtrl = AnimationController(vsync: this, duration: _holdDuration);
    _holdProgress = CurvedAnimation(parent: _holdCtrl, curve: Curves.linear);
    _holdCtrl.addStatusListener(_onHoldComplete);

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.14).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.18, end: 0.42).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _pressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _pressScale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  void _onHoldComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed && _isHolding) {
      _triggerSOS();
    }
  }

  void _triggerSOS() async {
    HapticFeedback.heavyImpact();
    await VibrationChannel.vibrateSOS();

    // TODO: Replace with real user data from AuthBloc / user provider
    context.read<SOSBloc>().add(const SOSTriggerRequested(
      userId: 'current_user_id',
      userName: 'Current User',
      emergencyContacts: [
        {'name': 'Contact 1', 'phone': '+8801700000000'},
      ],
    ));
  }

  void _onTapDown(TapDownDetails _) {
    setState(() => _isHolding = true);
    _pressCtrl.forward();
    _holdCtrl.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails _) => _onRelease();
  void _onTapCancel() => _onRelease();

  void _onRelease() {
    if (!_isHolding) return;
    setState(() => _isHolding = false);
    _pressCtrl.reverse();
    _holdCtrl.reverse(from: _holdCtrl.value);
  }

  @override
  void dispose() {
    _holdCtrl.dispose();
    _pulseCtrl.dispose();
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: SizedBox(
        width: 220,
        height: 220,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _pulseScale,
            _pulseOpacity,
            _holdProgress,
            _pressScale,
          ]),
          builder: (context, _) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // ── Outer pulse ring ──
                Transform.scale(
                  scale: _pulseScale.value * (_isHolding ? 1.06 : 1.0),
                  child: Opacity(
                    opacity: _pulseOpacity.value * (_isHolding ? 1.6 : 1.0),
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD62828).withOpacity(0.3),
                            blurRadius: 40,
                            spreadRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Mid ring ──
                Container(
                  width: 176,
                  height: 176,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD62828).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),

                // ── Hold progress arc ──
                if (_isHolding)
                  SizedBox(
                    width: 176,
                    height: 176,
                    child: CircularProgressIndicator(
                      value: _holdProgress.value,
                      strokeWidth: 3,
                      backgroundColor: Colors.transparent,
                      color: const Color(0xFFD62828),
                    ),
                  ),

                // ── Main button ──
                Transform.scale(
                  scale: _pressScale.value,
                  child: Container(
                    width: 148,
                    height: 148,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: _isHolding
                            ? [
                          const Color(0xFFD62828),
                          const Color(0xFF9B1B1B),
                        ]
                            : [
                          const Color(0xFF8B1A1A),
                          const Color(0xFF5A0E0E),
                        ],
                        center: const Alignment(-0.2, -0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD62828)
                              .withOpacity(_isHolding ? 0.55 : 0.3),
                          blurRadius: _isHolding ? 36 : 20,
                          spreadRadius: _isHolding ? 4 : 0,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          color: Colors.white
                              .withOpacity(_isHolding ? 1.0 : 0.9),
                          size: 40,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'SOS',
                          style: TextStyle(
                            color: Colors.white
                                .withOpacity(_isHolding ? 1.0 : 0.95),
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isHolding ? 'HOLD…' : 'HOLD 3s',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 11,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}