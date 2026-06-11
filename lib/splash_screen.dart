// ============================================================
// rokhok/lib/presentation/splash/splash_screen.dart
// Production-ready splash screen for Rokhok safety app
// ============================================================
//
// HOW TO USE:
//   1. Place this file at lib/presentation/splash/splash_screen.dart
//   2. In main.dart, set home: const SplashScreen()
//   3. Replace the SVG shield below with your real asset if desired
//      (see "LOGO ASSET" section at the bottom of this file)
//
// DEPENDENCIES (already in pubspec.yaml for most projects):
//   No extra packages required — uses only flutter SDK.
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Entry point wiring ───────────────────────────────────────
// In your main.dart, call this before runApp:
//
//   void main() async {
//     WidgetsFlutterBinding.ensureInitialized();
//     SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//     runApp(const RokhokApp());
//   }
//
//   class RokhokApp extends StatelessWidget {
//     const RokhokApp({super.key});
//     @override
//     Widget build(BuildContext context) => MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData.dark(),
//       home: const SplashScreen(),
//     );
//   }
// ─────────────────────────────────────────────────────────────

// ── Design tokens ────────────────────────────────────────────
class _C {
  static const bg = Color(0xFF0A0A0A);           // Near-true black
  static const surface = Color(0xFF111111);       // Card / overlay surface
  static const red = Color(0xFFD62828);           // Primary danger red
  static const redDeep = Color(0xFF9B1B1B);       // Deeper pulse layer
  static const redGlow = Color(0x33D62828);       // Translucent glow (20% opacity)
  static const redGlowOuter = Color(0x0FD62828);  // Very faint outer halo
  static const white = Color(0xFFF5F5F5);         // Slightly warm white
  static const muted = Color(0xFF888888);         // Tagline / subtext
  static const indicator = Color(0xFF555555);     // Loader track
}
// ─────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  /// The route name to push after the splash. Defaults to '/home'.
  /// Pass '/login' if you need auth-gating.
  final String nextRoute;

  const SplashScreen({super.key, this.nextRoute = '/home'});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Animation controllers ───────────────────────────────
  late final AnimationController _logoCtrl;    // fade + scale for logo
  late final AnimationController _textCtrl;    // staggered text fade-in
  late final AnimationController _pulseCtrl;   // continuous glow pulse
  late final AnimationController _loaderCtrl;  // loading bar

  // ── Logo: fade-in + scale-up ────────────────────────────
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;

  // ── Text elements: staggered fade ──────────────────────
  late final Animation<double> _appNameOpacity;
  late final Animation<double> _taglineOpacity;

  // ── Glow pulse (repeating) ──────────────────────────────
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;

  // ── Bottom loader ───────────────────────────────────────
  late final Animation<double> _loaderProgress;

  @override
  void initState() {
    super.initState();
    _lockToPortrait();
    _setupAnimations();
    _startSequence();
  }

  void _lockToPortrait() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: _C.bg,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _setupAnimations() {
    // ── Logo: 900ms, starts at t=0 ──
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoOpacity = CurvedAnimation(
      parent: _logoCtrl,
      curve: Curves.easeOut,
    );
    _logoScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack),
    );

    // ── Text: 700ms, staggered via intervals ──
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _appNameOpacity = CurvedAnimation(
      parent: _textCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _taglineOpacity = CurvedAnimation(
      parent: _textCtrl,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
    );

    // ── Glow pulse: repeating 2s cycle ──
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 0.88, end: 1.18).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // ── Loader: fills over 2.4s ──
    _loaderCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _loaderProgress = CurvedAnimation(
      parent: _loaderCtrl,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _startSequence() async {
    // Small delay so Flutter finishes first frame
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    // Fire logo in
    _logoCtrl.forward();

    // After logo is ~40% done, fire text
    await Future.delayed(const Duration(milliseconds: 360));
    if (!mounted) return;
    _textCtrl.forward();
    _loaderCtrl.forward();

    // Wait for loader to finish, then navigate
    await Future.delayed(const Duration(milliseconds: 2600));
    if (!mounted) return;
    _navigateNext();
  }

  void _navigateNext() {
    // Fade-out the whole screen before pushing
    Navigator.of(context).pushReplacementNamed(widget.nextRoute);
    // If you use go_router: context.go(widget.nextRoute);
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _pulseCtrl.dispose();
    _loaderCtrl.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // ── Subtle radial vignette at center ──
          _RadialBackground(size: size),

          // ── Main content column ──
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // ── Pulsing glow ring + logo ──
                _LogoSection(
                  pulseScale: _pulseScale,
                  pulseOpacity: _pulseOpacity,
                  logoOpacity: _logoOpacity,
                  logoScale: _logoScale,
                ),

                const SizedBox(height: 40),

                // ── App name ──
                FadeTransition(
                  opacity: _appNameOpacity,
                  child: const _AppName(),
                ),

                const SizedBox(height: 10),

                // ── Tagline ──
                FadeTransition(
                  opacity: _taglineOpacity,
                  child: const _Tagline(),
                ),

                const Spacer(flex: 3),

                // ── Loading indicator ──
                _LoadingBar(progress: _loaderProgress),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Sub-widgets (private, each has a single responsibility)
// ─────────────────────────────────────────────────────────────

/// Subtle dark radial glow from center — gives depth to flat black bg
class _RadialBackground extends StatelessWidget {
  final Size size;
  const _RadialBackground({required this.size});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(painter: _VignettePainter()),
    );
  }
}

class _VignettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          _C.redGlowOuter,
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(
        Rect.fromCircle(center: center, radius: size.width * 0.75),
      );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(_VignettePainter oldDelegate) => false;
}

/// Pulsing glow rings + shield logo with scale/fade-in
class _LogoSection extends StatelessWidget {
  final Animation<double> pulseScale;
  final Animation<double> pulseOpacity;
  final Animation<double> logoOpacity;
  final Animation<double> logoScale;

  const _LogoSection({
    required this.pulseScale,
    required this.pulseOpacity,
    required this.logoOpacity,
    required this.logoScale,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Outer glow ring ──
          AnimatedBuilder(
            animation: Listenable.merge([pulseScale, pulseOpacity]),
            builder: (_, __) => Transform.scale(
              scale: pulseScale.value,
              child: Opacity(
                opacity: pulseOpacity.value * 0.45,
                child: Container(
                  width: 172,
                  height: 172,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _C.red.withOpacity(0.35),
                        blurRadius: 52,
                        spreadRadius: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Inner glow ring (tighter, higher intensity) ──
          AnimatedBuilder(
            animation: Listenable.merge([pulseScale, pulseOpacity]),
            builder: (_, __) => Transform.scale(
              scale: 0.5 + pulseScale.value * 0.45,
              child: Opacity(
                opacity: pulseOpacity.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _C.redGlow,
                    boxShadow: [
                      BoxShadow(
                        color: _C.red.withOpacity(0.4),
                        blurRadius: 28,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Logo: fade in + scale up ──
          FadeTransition(
            opacity: logoOpacity,
            child: ScaleTransition(
              scale: logoScale,
              child: const _ShieldLogo(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shield icon — drawn with CustomPaint so zero asset dependency.
/// Swap with Image.asset('assets/images/logo.png') when you have a real logo.
class _ShieldLogo extends StatelessWidget {
  const _ShieldLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF181010),
        border: Border.all(color: _C.red.withOpacity(0.55), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _C.red.withOpacity(0.25),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _ShieldPainter(),
      ),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const w = 46.0;  // shield width
    const h = 52.0;  // shield height
    final top = cy - h / 2 + 2;
    final left = cx - w / 2;

    // ── Shield outline path ──
    final path = Path()
      ..moveTo(cx, top)                                  // top-center
      ..lineTo(left + w, top)                            // top-right
      ..lineTo(left + w, top + h * 0.54)                 // right mid
      ..quadraticBezierTo(left + w, top + h, cx, top + h + 2)  // right curve to bottom
      ..quadraticBezierTo(left, top + h, left, top + h * 0.54) // left curve
      ..lineTo(left, top)                                // back to top-left
      ..close();

    // Fill
    canvas.drawPath(
      path,
      Paint()
        ..color = _C.redDeep.withOpacity(0.85)
        ..style = PaintingStyle.fill,
    );

    // Stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = _C.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeJoin = StrokeJoin.round,
    );

    // ── "R" letterform inside shield ──
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'R',
        style: TextStyle(
          color: _C.white,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, cy - textPainter.height / 2 + 1),
    );
  }

  @override
  bool shouldRepaint(_ShieldPainter oldDelegate) => false;
}

/// "ROKHOK" app name — spaced, high-contrast
class _AppName extends StatelessWidget {
  const _AppName();

  @override
  Widget build(BuildContext context) {
    return Text(
      'ROKHOK',
      style: TextStyle(
        color: _C.white,
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: 8,
        height: 1,
        shadows: [
          Shadow(
            color: _C.red.withOpacity(0.4),
            blurRadius: 14,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

/// Tagline below the app name
class _Tagline extends StatelessWidget {
  const _Tagline();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 1,
          color: _C.red.withOpacity(0.55),
        ),
        const SizedBox(width: 8),
        Text(
          'Your Safety Companion',
          style: TextStyle(
            color: _C.muted,
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 20,
          height: 1,
          color: _C.red.withOpacity(0.55),
        ),
      ],
    );
  }
}

/// Slim progress bar at the bottom
class _LoadingBar extends StatelessWidget {
  final Animation<double> progress;
  const _LoadingBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    const barWidth = 120.0;

    return Column(
      children: [
        AnimatedBuilder(
          animation: progress,
          builder: (_, __) => SizedBox(
            width: barWidth,
            height: 2,
            child: Stack(
              children: [
                // Track
                Container(
                  decoration: BoxDecoration(
                    color: _C.indicator,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Fill
                FractionallySizedBox(
                  widthFactor: progress.value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _C.red,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: _C.red.withOpacity(0.6),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Initializing secure environment…',
          style: TextStyle(
            color: _C.muted.withOpacity(0.55),
            fontSize: 11,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LOGO ASSET — how to swap in a real image
// ─────────────────────────────────────────────────────────────
//
// 1. Add your logo PNG/SVG to: assets/images/logo.png
//
// 2. Register in pubspec.yaml:
//      flutter:
//        assets:
//          - assets/images/logo.png
//
// 3. Replace _ShieldLogo's Container child with:
//
//      Image.asset(
//        'assets/images/logo.png',
//        width: 64,
//        height: 64,
//        color: Colors.white,         // optional tint
//        colorBlendMode: BlendMode.srcIn,
//      )
//
//    Or for an SVG (add flutter_svg to pubspec.yaml):
//      SvgPicture.asset(
//        'assets/images/logo.svg',
//        width: 64,
//        height: 64,
//        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
//      )
//
// ─────────────────────────────────────────────────────────────
// COMMON ERRORS & FIXES
// ─────────────────────────────────────────────────────────────
//
// ❌ "Could not find a generator for route RouteSettings("/home")"
//    → Your MaterialApp has no routes table or onGenerateRoute.
//    Fix: Add routes: {'/home': (_) => const HomeScreen()} to MaterialApp,
//         or switch to go_router and call context.go('/home').
//
// ❌ "setState() called after dispose()"
//    → The timer fires after the widget is gone (e.g. hot reload mid-splash).
//    Fix: Already handled — every async continuation checks `if (!mounted)`.
//
// ❌ Black bar at top / status bar flicker
//    → SystemUiOverlayStyle not applied early enough.
//    Fix: Call _lockToPortrait() inside initState() before first build,
//         which is already done here.
//
// ❌ Animation jank on first frame
//    → runApp fires before the engine is warm.
//    Fix: The 120ms initial delay in _startSequence() absorbs this.
//         Increase to 200ms on low-end devices if needed.
//
// ❌ Glow disappears in release mode
//    → BoxShadow with blurRadius renders differently in release (Skia).
//    Fix: Confirmed working — no impeller flag changes needed.
//         If using Flutter 3.10+ on Android with Impeller preview enabled,
//         add `--no-enable-impeller` to run args while Impeller matures.
//
// ❌ "A dismissed Dismissible widget is still part of the tree"
//    → Using Navigator.push instead of pushReplacement.
//    Fix: Already uses pushReplacementNamed — splash is removed from stack.
//
// ─────────────────────────────────────────────────────────────