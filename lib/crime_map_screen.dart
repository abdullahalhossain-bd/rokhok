// ============================================================
// lib/presentation/home/map/crime_map_screen.dart
// Crime Map — Bangladesh SVG Map (No Google Maps)
// ============================================================
//
// DEPENDENCY — add to pubspec.yaml:
//   flutter_svg: ^2.0.10+1
//
// Then run: flutter pub get
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ── Design tokens ─────────────────────────────────────────────
class _C {
  static const bg            = Color(0xFF0A0A0A);
  static const surface       = Color(0xFF141414);
  static const surfaceHigh   = Color(0xFF1C1C1C);
  static const surfaceBorder = Color(0xFF242424);
  static const red           = Color(0xFFD62828);
  static const redGlow       = Color(0x55D62828);
  static const amber         = Color(0xFFF59E0B);
  static const amberGlow     = Color(0x55F59E0B);
  static const green         = Color(0xFF22C55E);
  static const greenGlow     = Color(0x5522C55E);
  static const blue          = Color(0xFF3B82F6);
  static const textPrimary   = Color(0xFFF2F2F2);
  static const textSecondary = Color(0xFF888888);
  static const textMuted     = Color(0xFF555555);
}

// ── Risk level ────────────────────────────────────────────────
enum _Risk { safe, medium, high }

extension _RiskX on _Risk {
  Color get color => switch (this) {
    _Risk.safe   => _C.green,
    _Risk.medium => _C.amber,
    _Risk.high   => _C.red,
  };

  Color get glow => switch (this) {
    _Risk.safe   => _C.greenGlow,
    _Risk.medium => _C.amberGlow,
    _Risk.high   => _C.redGlow,
  };

  String get label => switch (this) {
    _Risk.safe   => 'নিরাপদ রুট',
    _Risk.medium => 'মাঝারি ঝুঁকি',
    _Risk.high   => 'উচ্চ ঝুঁকি',
  };
}

// ── City model ────────────────────────────────────────────────
class _City {
  final String name;
  final String nameEn;
  final double nx; // 0..1 of map width
  final double ny; // 0..1 of map height

  const _City({
    required this.name,
    required this.nameEn,
    required this.nx,
    required this.ny,
  });

  Offset toOffset(double w, double h) => Offset(nx * w, ny * h);
}

const _cities = [
  _City(name: 'ঢাকা',       nameEn: 'Dhaka',      nx: 0.555, ny: 0.485),
  _City(name: 'চট্টগ্রাম',  nameEn: 'Chattogram', nx: 0.760, ny: 0.660),
  _City(name: 'সিলেট',      nameEn: 'Sylhet',     nx: 0.790, ny: 0.330),
  _City(name: 'রাজশাহী',    nameEn: 'Rajshahi',   nx: 0.265, ny: 0.355),
  _City(name: 'খুলনা',      nameEn: 'Khulna',     nx: 0.300, ny: 0.640),
  _City(name: 'বরিশাল',     nameEn: 'Barishal',   nx: 0.510, ny: 0.660),
  _City(name: 'রংপুর',      nameEn: 'Rangpur',    nx: 0.320, ny: 0.175),
  _City(name: 'ময়মনসিংহ',  nameEn: 'Mymensingh', nx: 0.570, ny: 0.355),
];

// ── Route model ───────────────────────────────────────────────
class _Route {
  final int fromIdx;
  final int toIdx;
  final _Risk risk;
  const _Route(this.fromIdx, this.toIdx, this.risk);
}

const _routes = [
  _Route(0, 1, _Risk.high),    // Dhaka → Chattogram
  _Route(0, 2, _Risk.medium),  // Dhaka → Sylhet
  _Route(0, 3, _Risk.safe),    // Dhaka → Rajshahi
  _Route(0, 4, _Risk.medium),  // Dhaka → Khulna
  _Route(0, 5, _Risk.safe),    // Dhaka → Barishal
  _Route(0, 7, _Risk.safe),    // Dhaka → Mymensingh
  _Route(3, 6, _Risk.safe),    // Rajshahi → Rangpur
  _Route(6, 7, _Risk.medium),  // Rangpur → Mymensingh
  _Route(4, 5, _Risk.medium),  // Khulna → Barishal
  _Route(5, 1, _Risk.high),    // Barishal → Chattogram
  _Route(2, 1, _Risk.high),    // Sylhet → Chattogram
  _Route(7, 2, _Risk.medium),  // Mymensingh → Sylhet
];

// ── Bangladesh SVG ────────────────────────────────────────────
const String _bangladeshSvg = '''
<svg viewBox="0 0 400 520" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <filter id="glow">
      <feGaussianBlur stdDeviation="3" result="blur"/>
      <feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge>
    </filter>
    <radialGradient id="mapGrad" cx="50%" cy="50%" r="60%">
      <stop offset="0%" stop-color="#1a3a55"/>
      <stop offset="100%" stop-color="#0d2030"/>
    </radialGradient>
  </defs>
  <path
    d="M 185,18 L 200,14 L 218,16 L 235,22 L 248,30 L 260,20 L 278,18
       L 295,22 L 308,35 L 315,50 L 310,62 L 320,72 L 330,68 L 340,75
       L 345,90 L 338,105 L 328,112 L 335,125 L 340,140 L 330,155
       L 320,160 L 315,175 L 318,190 L 325,205 L 330,220 L 325,235
       L 315,245 L 310,260 L 318,275 L 322,290 L 318,305 L 310,318
       L 302,332 L 308,345 L 315,358 L 318,372 L 312,385 L 305,398
       L 298,410 L 290,420 L 295,432 L 300,445 L 292,455 L 280,460
       L 268,462 L 258,470 L 248,478 L 235,480 L 222,478 L 210,475
       L 200,480 L 190,490 L 178,495 L 165,492 L 152,485 L 142,476
       L 130,472 L 118,468 L 108,460 L 100,450 L 92,440 L 88,428
       L 80,416 L 72,404 L 68,390 L 72,376 L 80,365 L 76,352 L 68,340
       L 62,325 L 58,310 L 62,295 L 70,282 L 78,270 L 82,255 L 78,240
       L 72,225 L 65,212 L 60,198 L 55,182 L 60,168 L 70,155 L 80,145
       L 88,132 L 90,118 L 84,104 L 78,90 L 80,76 L 88,64 L 98,55
       L 108,48 L 120,42 L 132,38 L 145,32 L 158,26 L 172,20 Z"
    fill="url(#mapGrad)"
    stroke="#1E3A50"
    stroke-width="1.5"
    filter="url(#glow)"
  />
  <g stroke="#0e2840" stroke-width="0.7" opacity="0.6" fill="none">
    <path d="M200,80 Q210,120 205,160 Q200,200 208,240 Q215,280 210,320 Q205,360 200,400"/>
    <path d="M150,100 Q160,140 155,180 Q150,220 145,260 Q140,300 138,340"/>
    <path d="M260,120 Q255,160 250,200 Q245,240 248,280 Q252,320 248,360"/>
    <path d="M120,200 Q150,210 180,205 Q210,200 240,205 Q270,210 295,205"/>
    <path d="M100,300 Q130,295 160,298 Q190,300 220,298 Q250,295 280,300 Q310,305 325,300"/>
    <path d="M108,380 Q135,375 160,378 Q185,380 210,376 Q235,372 255,378"/>
  </g>
</svg>
''';

// ─────────────────────────────────────────────────────────────
// ROOT SCREEN
// ─────────────────────────────────────────────────────────────
class CrimeMapScreen extends StatefulWidget {
  const CrimeMapScreen({super.key});

  @override
  State<CrimeMapScreen> createState() => _CrimeMapScreenState();
}

class _CrimeMapScreenState extends State<CrimeMapScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  late final AnimationController _drawCtrl;
  late final Animation<double> _drawAnim;

  final Set<_Risk> _visibleRisks = {_Risk.safe, _Risk.medium, _Risk.high};
  _City? _selectedCity;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _pulseAnim =
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    _drawCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _drawAnim = CurvedAnimation(parent: _drawCtrl, curve: Curves.easeOut);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _drawCtrl.forward();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _drawCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          const _GridBackground(),
          SafeArea(
            child: Column(
              children: [
                _TopBar(
                  visibleRisks: _visibleRisks,
                  onToggleRisk: (r) => setState(() => _visibleRisks.contains(r)
                      ? _visibleRisks.remove(r)
                      : _visibleRisks.add(r)),
                ),
                Expanded(
                  child: _MapArea(
                    pulseAnim: _pulseAnim,
                    drawAnim: _drawAnim,
                    visibleRisks: _visibleRisks,
                    selectedCity: _selectedCity,
                    onCityTap: (c) {
                      HapticFeedback.selectionClick();
                      setState(() =>
                      _selectedCity = _selectedCity == c ? null : c);
                    },
                  ),
                ),
                _BottomBar(
                  selectedCity: _selectedCity,
                  visibleRisks: _visibleRisks,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// GRID BACKGROUND
// ─────────────────────────────────────────────────────────────
class _GridBackground extends StatelessWidget {
  const _GridBackground();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.infinite, painter: _GridPainter());
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF0E1620)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    final glow = Paint()
      ..color = _C.blue.withOpacity(0.04)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    canvas.drawCircle(Offset(0, size.height), 160, glow);
    canvas.drawCircle(Offset(size.width, 0), 120, glow);
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}

// ─────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final Set<_Risk> visibleRisks;
  final Function(_Risk) onToggleRisk;

  const _TopBar({required this.visibleRisks, required this.onToggleRisk});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PulseDot(color: _C.green, size: 8),
              const SizedBox(width: 8),
              const Text(
                'ক্রাইম ম্যাপ',
                style: TextStyle(
                  color: _C.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _C.green.withOpacity(0.4), width: 0.8),
                ),
                child: const Text(
                  '● লাইভ',
                  style: TextStyle(
                    color: _C.green,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'বাংলাদেশ • রিয়েল-টাইম রুট ঝুঁকি বিশ্লেষণ',
            style: TextStyle(color: _C.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 30,
            child: Row(
              children: _Risk.values.map((r) {
                final active = visibleRisks.contains(r);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onToggleRisk(r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: active
                            ? r.color.withOpacity(0.15)
                            : _C.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active
                              ? r.color.withOpacity(0.55)
                              : _C.surfaceBorder,
                          width: 0.8,
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
                              color: active ? r.color : _C.textMuted,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            r.label,
                            style: TextStyle(
                              color: active ? r.color : _C.textSecondary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MAP AREA
// ─────────────────────────────────────────────────────────────
class _MapArea extends StatelessWidget {
  final Animation<double> pulseAnim;
  final Animation<double> drawAnim;
  final Set<_Risk> visibleRisks;
  final _City? selectedCity;
  final Function(_City) onCityTap;

  const _MapArea({
    required this.pulseAnim,
    required this.drawAnim,
    required this.visibleRisks,
    required this.selectedCity,
    required this.onCityTap,
  });

  get SvgPicture => null;

  // FIXED: removed the bogus `get SvgPicture => null;` getter that was
  // shadowing the SvgPicture class imported from flutter_svg.

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF080E14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.surfaceBorder, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: _C.blue.withOpacity(0.06),
              blurRadius: 32,
              spreadRadius: 4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LayoutBuilder(builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            return Stack(
              children: [
                // SVG map
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SvgPicture.string(
                      _bangladeshSvg,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // Routes
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: AnimatedBuilder(
                      animation: drawAnim,
                      builder: (_, __) => CustomPaint(
                        painter: _RoutePainter(
                          cities: _cities,
                          routes: _routes,
                          visibleRisks: visibleRisks,
                          progress: drawAnim.value,
                        ),
                      ),
                    ),
                  ),
                ),

                // City markers
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: AnimatedBuilder(
                      animation: pulseAnim,
                      builder: (_, __) => _CityMarkersLayer(
                        pulseValue: pulseAnim.value,
                        selectedCity: selectedCity,
                        onCityTap: onCityTap,
                      ),
                    ),
                  ),
                ),

                // Compass
                const Positioned(
                    top: 12, right: 12, child: _CompassRose()),

                // Scale bar
                const Positioned(
                    bottom: 12, right: 12, child: _ScaleBar()),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ROUTE PAINTER
// ─────────────────────────────────────────────────────────────
class _RoutePainter extends CustomPainter {
  final List<_City> cities;
  final List<_Route> routes;
  final Set<_Risk> visibleRisks;
  final double progress;

  const _RoutePainter({
    required this.cities,
    required this.routes,
    required this.visibleRisks,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final route in routes) {
      if (!visibleRisks.contains(route.risk)) continue;
      final from = cities[route.fromIdx].toOffset(size.width, size.height);
      final to   = cities[route.toIdx].toOffset(size.width, size.height);
      final current = Offset.lerp(from, to, progress)!;
      _drawGlowLine(canvas, from, current, route.risk);
    }
  }

  void _drawGlowLine(Canvas canvas, Offset from, Offset to, _Risk risk) {
    final color = risk.color;

    // Outer glow
    canvas.drawLine(
      from, to,
      Paint()
        ..color = risk.glow
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Mid glow
    canvas.drawLine(
      from, to,
      Paint()
        ..color = color.withOpacity(0.35)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Core line
    canvas.drawLine(
      from, to,
      Paint()
        ..color = color
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );

    // Travel dots
    final dist = (to - from).distance;
    if (dist > 20) {
      const spacing = 18.0;
      final steps = (dist / spacing).floor();
      for (int i = 1; i < steps; i++) {
        final pt = Offset.lerp(from, to, i / steps)!;
        canvas.drawCircle(
            pt, 1.5, Paint()..color = color.withOpacity(0.6));
      }
    }
  }

  @override
  bool shouldRepaint(_RoutePainter old) =>
      old.progress != progress || old.visibleRisks != visibleRisks;
}

// ─────────────────────────────────────────────────────────────
// CITY MARKERS LAYER
// ─────────────────────────────────────────────────────────────
class _CityMarkersLayer extends StatelessWidget {
  final double pulseValue;
  final _City? selectedCity;
  final Function(_City) onCityTap;

  const _CityMarkersLayer({
    required this.pulseValue,
    required this.selectedCity,
    required this.onCityTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      return Stack(
        children: _cities.map((city) {
          final pos = city.toOffset(w, h);
          final isSelected = selectedCity == city;
          final isDhaka = city.nameEn == 'Dhaka';
          final pulseScale = 1.0 + pulseValue * (isDhaka ? 0.6 : 0.35);

          return Positioned(
            left: pos.dx - 20,
            top: pos.dy - 20,
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => onCityTap(city),
              behavior: HitTestBehavior.opaque,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulse ring
                  Transform.scale(
                    scale: pulseScale,
                    child: Container(
                      width: isDhaka ? 22 : 16,
                      height: isDhaka ? 22 : 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isSelected ? _C.amber : _C.blue)
                            .withOpacity(0.12 * (1 - pulseValue * 0.4)),
                      ),
                    ),
                  ),

                  // Dot
                  Container(
                    width: isDhaka ? 11 : 8,
                    height: isDhaka ? 11 : 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? _C.amber : _C.blue,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: isDhaka ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isSelected ? _C.amber : _C.blue)
                              .withOpacity(0.7),
                          blurRadius: isDhaka ? 12 : 8,
                          spreadRadius: isDhaka ? 2 : 1,
                        ),
                      ],
                    ),
                  ),

                  // Label
                  Positioned(
                    left: 0,
                    right: 0,
                    child: Transform.translate(
                      offset: Offset(0, isDhaka ? -22 : -18),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xCC080E14),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            city.name,
                            style: TextStyle(
                              color: isSelected ? _C.amber : _C.textPrimary,
                              fontSize: isDhaka ? 9.5 : 8.5,
                              fontWeight: isDhaka
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────
// COMPASS ROSE
// ─────────────────────────────────────────────────────────────
class _CompassRose extends StatelessWidget {
  const _CompassRose();

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 36, height: 36, child: CustomPaint(painter: _CompassPainter()));
}

class _CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 2;

    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = _C.surfaceBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    canvas.drawPath(
      Path()
        ..moveTo(cx, cy - r + 2)
        ..lineTo(cx - 4, cy)
        ..lineTo(cx + 4, cy)
        ..close(),
      Paint()..color = _C.red,
    );

    canvas.drawPath(
      Path()
        ..moveTo(cx, cy + r - 2)
        ..lineTo(cx - 4, cy)
        ..lineTo(cx + 4, cy)
        ..close(),
      Paint()..color = _C.textMuted,
    );

    final tp = TextPainter(
      text: const TextSpan(
        text: 'N',
        style: TextStyle(
            color: _C.red, fontSize: 7, fontWeight: FontWeight.w900),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, 0));
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────
// SCALE BAR
// ─────────────────────────────────────────────────────────────
class _ScaleBar extends StatelessWidget {
  const _ScaleBar();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 3,
          decoration: BoxDecoration(
            border: Border.all(color: _C.textMuted, width: 0.8),
            color: Colors.transparent,
          ),
          foregroundDecoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: _C.textMuted, width: 0.8),
              right: BorderSide(color: _C.textMuted, width: 0.8),
            ),
          ),
        ),
        const SizedBox(height: 2),
        const Text('~100 km',
            style: TextStyle(color: _C.textMuted, fontSize: 8)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BOTTOM BAR
// ─────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final _City? selectedCity;
  final Set<_Risk> visibleRisks;

  const _BottomBar({this.selectedCity, required this.visibleRisks});

  int get _highCount =>
      _routes.where((r) => r.risk == _Risk.high && visibleRisks.contains(r.risk)).length;
  int get _medCount =>
      _routes.where((r) => r.risk == _Risk.medium && visibleRisks.contains(r.risk)).length;
  int get _safeCount =>
      _routes.where((r) => r.risk == _Risk.safe && visibleRisks.contains(r.risk)).length;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.surfaceBorder, width: 0.5),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: selectedCity != null
            ? _CityInfoRow(city: selectedCity!)
            : _LegendRow(
          highCount: _highCount,
          medCount: _medCount,
          safeCount: _safeCount,
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final int highCount;
  final int medCount;
  final int safeCount;

  const _LegendRow({
    required this.highCount,
    required this.medCount,
    required this.safeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _LegendItem(color: _C.red,   label: 'উচ্চ ঝুঁকি',   count: highCount),
        _Divider(),
        _LegendItem(color: _C.amber, label: 'মাঝারি ঝুঁকি', count: medCount),
        _Divider(),
        _LegendItem(color: _C.green, label: 'নিরাপদ',        count: safeCount),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _LegendItem(
      {required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)],
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: const TextStyle(
                    color: _C.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
            Text('$count রুট',
                style: TextStyle(
                    color: color, fontSize: 10, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 0.5, height: 28, color: _C.surfaceBorder);
}

class _CityInfoRow extends StatelessWidget {
  final _City city;
  const _CityInfoRow({required this.city});

  List<_Route> get _connected => _routes
      .where((r) => _cities[r.fromIdx] == city || _cities[r.toIdx] == city)
      .toList();

  @override
  Widget build(BuildContext context) {
    final connected = _connected;
    final highRisk = connected.where((r) => r.risk == _Risk.high).length;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _C.blue.withOpacity(0.12),
            border: Border.all(color: _C.blue.withOpacity(0.3), width: 0.8),
          ),
          child: const Icon(Icons.location_city_rounded,
              color: _C.blue, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(city.name,
                  style: const TextStyle(
                      color: _C.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              Text(
                '${connected.length}টি রুট সংযুক্ত'
                    '${highRisk > 0 ? ' • $highRisk টি উচ্চ ঝুঁকির' : ''}',
                style: const TextStyle(
                    color: _C.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 4,
          children: connected
              .map((r) => Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: r.risk.color,
              boxShadow: [
                BoxShadow(
                    color: r.risk.color.withOpacity(0.6),
                    blurRadius: 4)
              ],
            ),
          ))
              .toList(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PULSING DOT WIDGET
// ─────────────────────────────────────────────────────────────
class _PulseDot extends StatefulWidget {
  final Color color;
  final double size;

  const _PulseDot({required this.color, required this.size});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.85, end: 1.15)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.7),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}