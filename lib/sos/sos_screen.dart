// lib/presentation/sos/pages/sos_screen.dart
// The main SOS screen. Three visual states:
//   • Idle   — big pulsing SOS button, ready to trigger
//   • Active — countdown timer, cancel button, status cards
//   • Error  — snackbar + reset to idle

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'sos_bloc.dart';
import 'sos_button.dart';
import 'sos_active_panel.dart';
import 'sos_cancel_dialog.dart';
import 'sos_status_card.dart';

class SOSScreen extends StatelessWidget {
  const SOSScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => context.read<SOSBloc>(),
      child: const _SOSScreenBody(),
    );
  }
}

class _SOSScreenBody extends StatelessWidget {
  const _SOSScreenBody();

  @override
  Widget build(BuildContext context) {
    return BlocListener<SOSBloc, SOSState>(
      listener: _handleStateChanges,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(context),
        body: BlocBuilder<SOSBloc, SOSState>(
          builder: (context, state) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _buildBody(context, state),
            );
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFD62828),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'ROKHOK',
            style: TextStyle(
              color: Color(0xFFF5F5F5),
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.contacts_outlined, color: Color(0xFF888888)),
          tooltip: 'Emergency Contacts',
          onPressed: () => Navigator.pushNamed(context, '/contacts'),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, SOSState state) {
    return switch (state) {
      SOSIdle()        => _IdleView(key: const ValueKey('idle')),
      SOSTriggering()  => _TriggeringView(key: const ValueKey('triggering')),
      SOSActive()      => SOSActivePanel(
        key: const ValueKey('active'),
        state: state,
      ),
      SOSCancelling()  => _CancellingView(key: const ValueKey('cancelling')),
      SOSResolved()    => _ResolvedView(key: const ValueKey('resolved')),
      SOSFailureState()=> _IdleView(key: const ValueKey('idle-error')),
      _                => _IdleView(key: const ValueKey('idle-fallback')),
    };
  }

  void _handleStateChanges(BuildContext context, SOSState state) {
    if (state is SOSActive) {
      // Vibrate on SOS activation
      HapticFeedback.heavyImpact();
    }
    if (state is SOSFailureState) {
      final msg = state.failure.message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFF9B1B1B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        ),
      );
    }
    if (state is SOSResolved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('SOS cancelled. Stay safe.'),
          backgroundColor: const Color(0xFF1A3A1A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}

// ── Idle view — the main SOS button ──────────────────────────
class _IdleView extends StatelessWidget {
  const _IdleView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Spacer(flex: 2),

            // ── Header text ──
            const Text(
              'Press & hold for\n3 seconds to activate',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 14,
                height: 1.6,
                letterSpacing: 0.4,
              ),
            ),

            const Spacer(flex: 2),

            // ── SOS button ──
            const SOSButton(),

            const Spacer(flex: 2),

            // ── Status cards ──
            Row(
              children: [
                Expanded(
                  child: SOSStatusCard(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: 'Active',
                    valueColor: const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SOSStatusCard(
                    icon: Icons.contacts_outlined,
                    label: 'Contacts',
                    value: '3 set',
                    valueColor: const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SOSStatusCard(
                    icon: Icons.wifi_outlined,
                    label: 'Network',
                    value: 'Online',
                    valueColor: const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ── Safe route button ──
            _SafeRouteButton(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SafeRouteButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/map'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.map_outlined, color: Color(0xFF888888), size: 18),
            SizedBox(width: 10),
            Text(
              'View Crime Map & Safe Routes',
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Color(0xFF555555), size: 12),
          ],
        ),
      ),
    );
  }
}

// ── Triggering view — shown while getting location ────────────
class _TriggeringView extends StatelessWidget {
  const _TriggeringView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              color: Color(0xFFD62828),
              strokeWidth: 2.5,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Activating SOS…',
            style: TextStyle(
              color: Color(0xFFD62828),
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Getting your location',
            style: TextStyle(color: Color(0xFF666666), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Cancelling view ───────────────────────────────────────────
class _CancellingView extends StatelessWidget {
  const _CancellingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF888888),
            strokeWidth: 2,
          ),
          SizedBox(height: 20),
          Text(
            'Cancelling SOS…',
            style: TextStyle(color: Color(0xFF888888), fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// ── Resolved view — shows briefly before popping ─────────────
class _ResolvedView extends StatefulWidget {
  const _ResolvedView({super.key});
  @override
  State<_ResolvedView> createState() => _ResolvedViewState();
}

class _ResolvedViewState extends State<_ResolvedView> {
  @override
  void initState() {
    super.initState();
    // Auto-reset to idle after 2s
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) context.read<SOSBloc>().emit(const SOSIdle());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A3A1A),
              border: Border.all(color: const Color(0xFF4CAF50), width: 2),
            ),
            child: const Icon(Icons.check_rounded,
                color: Color(0xFF4CAF50), size: 36),
          ),
          const SizedBox(height: 20),
          const Text(
            'SOS Cancelled',
            style: TextStyle(
              color: Color(0xFFF5F5F5),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your contacts have been notified.',
            style: TextStyle(color: Color(0xFF888888), fontSize: 14),
          ),
        ],
      ),
    );
  }
}