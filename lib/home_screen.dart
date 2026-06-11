import 'crime_map_screen.dart';
import 'map/crime_map_screen.dart';
// ============================================================
// lib/presentation/home/home_screen.dart
// Home Dashboard + Bottom Navigation Shell for Rokhok
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'sos/sos_bloc.dart';
import 'sos/sos_screen.dart';

// ── Design tokens ─────────────────────────────────────────────
class _AppColors {
  static const bg = Color(0xFF0A0A0A);
  static const surface = Color(0xFF141414);
  static const surfaceHigh = Color(0xFF1C1C1C);
  static const surfaceBorder = Color(0xFF242424);
  static const red = Color(0xFFD62828);
  static const redDim = Color(0xFF9B1B1B);
  static const redGlow = Color(0x22D62828);
  static const redSubtle = Color(0xFF1A0A0A);
  static const textPrimary = Color(0xFFF2F2F2);
  static const textSecondary = Color(0xFF888888);
  static const textMuted = Color(0xFF555555);
  static const green = Color(0xFF22C55E);
  static const amber = Color(0xFFF59E0B);
  static const greenDim = Color(0xFF052010);
  static const amberDim = Color(0xFF1A1000);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const List<Widget> _tabs = [
    _HomeTab(),
    _MapTab(),
    _TrackingTab(),
    _ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0F0F0F),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.bg,
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: const _TopBar(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const _SOSHeroCard(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const _StatusGrid(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const _QuickActions(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nearby alerts',
                    style: TextStyle(
                      color: _AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: _AppColors.red,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'See all',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          const SliverToBoxAdapter(child: _RecentAlerts()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _AppColors.redDim,
            border: Border.all(color: _AppColors.red.withOpacity(0.4), width: 1.5),
          ),
          child: const Center(
            child: Text(
              'R',
              style: TextStyle(
                color: _AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Good morning',
                style: TextStyle(
                  color: _AppColors.textSecondary,
                  fontSize: 12,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 1),
              const Text(
                'Stay safe today',
                style: TextStyle(
                  color: _AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _AppColors.greenDim,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _AppColors.green.withOpacity(0.3),
              width: 0.5,
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
                  color: _AppColors.green,
                  boxShadow: [
                    BoxShadow(
                      color: _AppColors.green.withOpacity(0.6),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                'Safe',
                style: TextStyle(
                  color: _AppColors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _IconBtn(
          icon: Icons.notifications_outlined,
          onTap: () {},
          badgeCount: 2,
        ),
      ],
    );
  }
}

class _SOSHeroCard extends StatefulWidget {
  const _SOSHeroCard();

  @override
  State<_SOSHeroCard> createState() => _SOSHeroCardState();
}

class _SOSHeroCardState extends State<_SOSHeroCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.2, end: 0.55).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _openSOSScreen() {
    HapticFeedback.heavyImpact();
    Navigator.of(context).pushNamed('/sos');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SOSBloc, SOSState>(
      builder: (context, state) {
        final sosActive = state is SOSActive || state is SOSCancelling;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: sosActive ? _AppColors.redSubtle : _AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: sosActive
                  ? _AppColors.red.withOpacity(0.6)
                  : _AppColors.surfaceBorder,
              width: sosActive ? 1.5 : 0.5,
            ),
            boxShadow: sosActive
                ? [
              BoxShadow(
                color: _AppColors.red.withOpacity(0.18),
                blurRadius: 32,
                spreadRadius: 4,
              ),
            ]
                : null,
          ),
          child: Column(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: Listenable.merge([_pulseScale, _pulseOpacity]),
                      builder: (_, __) => Transform.scale(
                        scale: _pulseScale.value,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _AppColors.red.withOpacity(
                                  sosActive
                                      ? _pulseOpacity.value
                                      : _pulseOpacity.value * 0.4,
                                ),
                                blurRadius: 28,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _AppColors.red.withOpacity(0.18),
                          width: 1,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _openSOSScreen,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: sosActive ? _AppColors.red : _AppColors.redDim,
                          border: Border.all(
                            color: _AppColors.red,
                            width: sosActive ? 2.5 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _AppColors.red.withOpacity(
                                sosActive ? 0.45 : 0.2,
                              ),
                              blurRadius: sosActive ? 24 : 12,
                              spreadRadius: sosActive ? 4 : 0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                sosActive ? Icons.shield : Icons.shield_outlined,
                                color: Colors.white,
                                size: 22,
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'SOS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: sosActive
                    ? const _SOSActiveLabel()
                    : const _SOSIdleLabel(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SOSIdleLabel extends StatelessWidget {
  const _SOSIdleLabel();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('idle'),
      children: const [
        Text(
          'Tap to open SOS',
          style: TextStyle(
            color: _AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Alerts your emergency contacts immediately',
          style: TextStyle(
            color: _AppColors.textSecondary,
            fontSize: 12,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SOSActiveLabel extends StatelessWidget {
  const _SOSActiveLabel();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('active'),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _AppColors.red,
                boxShadow: [
                  BoxShadow(
                    color: _AppColors.red.withOpacity(0.7),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const Text(
              'SOS ACTIVE',
              style: TextStyle(
                color: _AppColors.red,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Alerting contacts • Tracking location',
          style: TextStyle(
            color: _AppColors.textSecondary,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _StatusGrid extends StatelessWidget {
  const _StatusGrid();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Contacts',
            value: '3',
            sub: 'emergency',
            icon: Icons.people_outline_rounded,
            iconColor: _AppColors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Crimes nearby',
            value: '2',
            sub: 'within 500m',
            icon: Icons.warning_amber_rounded,
            iconColor: _AppColors.amber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Safe zones',
            value: '5',
            sub: 'around you',
            icon: Icons.location_on_outlined,
            iconColor: _AppColors.green,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _AppColors.surfaceBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: _AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            sub,
            style: const TextStyle(
              color: _AppColors.textSecondary,
              fontSize: 10,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: _AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  static const _actions = [
    _QuickAction(icon: Icons.share_location_outlined, label: 'Share\nlocation'),
    _QuickAction(icon: Icons.videocam_outlined,        label: 'Silent\nvideo'),
    _QuickAction(icon: Icons.sms_outlined,             label: 'Alert\ncontacts'),
    _QuickAction(icon: Icons.bluetooth_searching_rounded, label: 'Nearby\nalert'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick actions',
          style: TextStyle(
            color: _AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: _actions
              .map((a) => Expanded(child: _QuickActionBtn(action: a)))
              .toList(),
        ),
      ],
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  const _QuickAction({required this.icon, required this.label});
}

class _QuickActionBtn extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionBtn({required this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          splashColor: _AppColors.redGlow,
          highlightColor: _AppColors.redGlow,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _AppColors.surfaceBorder, width: 0.5),
            ),
            child: Column(
              children: [
                Icon(action.icon, color: _AppColors.red, size: 22),
                const SizedBox(height: 8),
                Text(
                  action.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _AppColors.textSecondary,
                    fontSize: 10.5,
                    height: 1.35,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentAlerts extends StatelessWidget {
  const _RecentAlerts();

  static const _alerts = [
    _AlertData(type: 'SOS',   title: 'SOS alert triggered',       sub: '320m away · 4 min ago',  severity: _AlertSeverity.high),
    _AlertData(type: 'CRIME', title: 'Theft reported',             sub: '480m away · 22 min ago', severity: _AlertSeverity.medium),
    _AlertData(type: 'ZONE',  title: 'Entering moderate risk zone',sub: '150m ahead · Just now',  severity: _AlertSeverity.medium),
    _AlertData(type: 'SOS',   title: 'SOS resolved',               sub: '1.2km away · 1 hr ago',  severity: _AlertSeverity.resolved),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _alerts
            .map((a) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _AlertCard(data: a),
        ))
            .toList(),
      ),
    );
  }
}

enum _AlertSeverity { high, medium, resolved }

class _AlertData {
  final String type;
  final String title;
  final String sub;
  final _AlertSeverity severity;
  const _AlertData({
    required this.type,
    required this.title,
    required this.sub,
    required this.severity,
  });
}

class _AlertCard extends StatelessWidget {
  final _AlertData data;
  const _AlertCard({required this.data});

  Color get _dotColor => switch (data.severity) {
    _AlertSeverity.high     => _AppColors.red,
    _AlertSeverity.medium   => _AppColors.amber,
    _AlertSeverity.resolved => _AppColors.green,
  };

  Color get _bgColor => switch (data.severity) {
    _AlertSeverity.high     => _AppColors.redSubtle,
    _AlertSeverity.medium   => _AppColors.amberDim,
    _AlertSeverity.resolved => _AppColors.greenDim,
  };

  Color get _borderColor => switch (data.severity) {
    _AlertSeverity.high     => _AppColors.red.withOpacity(0.25),
    _AlertSeverity.medium   => _AppColors.amber.withOpacity(0.2),
    _AlertSeverity.resolved => _AppColors.green.withOpacity(0.2),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _dotColor,
              boxShadow: [
                BoxShadow(color: _dotColor.withOpacity(0.5), blurRadius: 5, spreadRadius: 1),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: _dotColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              data.type,
              style: TextStyle(
                color: _dotColor,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title,
                    style: const TextStyle(
                        color: _AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(data.sub,
                    style: const TextStyle(
                        color: _AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: _AppColors.textMuted, size: 18),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItem(icon: Icons.home_outlined,        activeIcon: Icons.home_rounded,        label: 'Home'),
    _NavItem(icon: Icons.map_outlined,         activeIcon: Icons.map_rounded,         label: 'Map'),
    _NavItem(icon: Icons.my_location_outlined, activeIcon: Icons.my_location_rounded, label: 'Track'),
    _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded,    label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        border: Border(top: BorderSide(color: _AppColors.surfaceBorder, width: 0.5)),
      ),
      child: Row(
        children: List.generate(
          _items.length,
              (i) => Expanded(
            child: _NavBarItem(
              item: _items[i],
              isActive: i == currentIndex,
              onTap: () => onTap(i),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

class _NavBarItem extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarItem({required this.item, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 18 : 0,
              height: isActive ? 3 : 0,
              decoration: BoxDecoration(
                color: _AppColors.red,
                borderRadius: BorderRadius.circular(2),
                boxShadow: isActive
                    ? [BoxShadow(color: _AppColors.red.withOpacity(0.6), blurRadius: 6)]
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? item.activeIcon : item.icon,
                key: ValueKey(isActive),
                color: isActive ? _AppColors.red : _AppColors.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                color: isActive ? _AppColors.red : _AppColors.textMuted,
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  const _IconBtn({required this.icon, required this.onTap, this.badgeCount = 0});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: _AppColors.surfaceBorder, width: 0.5),
              ),
              child: Icon(icon, color: _AppColors.textSecondary, size: 20),
            ),
            if (badgeCount > 0)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _AppColors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: _AppColors.bg, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Tabs ──────────────────────────────────────────────────────

// ✅ FIXED: was `crime_map_screen()` — now correctly `CrimeMapScreen()`
class _MapTab extends StatelessWidget {
  const _MapTab();

  @override
  Widget build(BuildContext context) => const CrimeMapScreen();
}

class _TrackingTab extends StatelessWidget {
  const _TrackingTab();

  @override
  Widget build(BuildContext context) => const _PlaceholderTab(
    icon: Icons.my_location_rounded,
    label: 'Live Tracking',
    phase: 'Phase 2',
  );
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) => const _PlaceholderTab(
    icon: Icons.person_rounded,
    label: 'Profile',
    phase: 'Phase 5',
  );
}

class _PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final String phase;

  const _PlaceholderTab({
    required this.icon,
    required this.label,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _AppColors.textMuted, size: 40),
            const SizedBox(height: 14),
            Text(label,
                style: const TextStyle(
                    color: _AppColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _AppColors.surfaceBorder, width: 0.5),
              ),
              child: Text(
                'Coming in $phase',
                style: const TextStyle(color: _AppColors.textMuted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}