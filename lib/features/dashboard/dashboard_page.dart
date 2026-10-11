import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/daily_checkin_fab.dart';
import '../../core/widgets/menu_drawer.dart';
import '../../core/widgets/panic_button.dart';
import '../../core/widgets/status_widget.dart';
import '../calendar/calendar_page.dart';
import '../resources/resources_page.dart';
import '../today/today_page.dart';
import '../../core/theme/theme_controller.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  Key _statusWidgetKey = UniqueKey();

  Future<void> _onNavigationTap(int index) async {
    if (index == 0) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const TodayPage()));

      if (!mounted) {
        return;
      }

      setState(() {
        _statusWidgetKey = UniqueKey();
      });

      return;
    }

    if (index == 1) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const ResourcesPage()));

      if (!mounted) {
        return;
      }

      setState(() {
        _statusWidgetKey = UniqueKey();
      });

      return;
    }

    if (index == 2) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const CalendarPage()));

      if (!mounted) {
        return;
      }

      setState(() {
        _statusWidgetKey = UniqueKey();
      });

      return;
    }

    if (index == 3) {
      await context.push('/profile');

      if (!mounted) {
        return;
      }

      setState(() {
        _statusWidgetKey = UniqueKey();
      });

      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 20,
        title: const Text(
          'Min oversikt',
          style: TextStyle(fontWeight: FontWeight.w500, letterSpacing: -0.2),
        ),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),

      drawer: MenuDrawer(
        themeController: ThemeScope.of(context),
      ),

      body: Stack(
        children: [
          // ─────────────────────────────────────────
          // Bakgrunn
          // ─────────────────────────────────────────

          Container(
            width: double.infinity,
            height: double.infinity,
            color: isDark ? const Color(0xFF111526) : const Color(0xFFF4F8F8),
          ),

          // Øvre høyre form
          Positioned(
            top: -150,
            right: -110,
            child: _buildBackgroundShape(
              width: 390,
              height: 390,
              color: isDark ? const Color(0xFF34305A) : const Color(0xFFB9DFE2),
              opacity: isDark ? 0.34 : 0.34,
              borderRadius: 220,
            ),
          ),

          // Venstre form
          Positioned(
            top: 250,
            left: -230,
            child: _buildBackgroundShape(
              width: 430,
              height: 430,
              color: isDark ? const Color(0xFF1C3040) : const Color(0xFFD6ECEC),
              opacity: isDark ? 0.55 : 0.55,
              borderRadius: 240,
            ),
          ),

          // Nedre høyre form
          Positioned(
            bottom: -170,
            right: -120,
            child: _buildBackgroundShape(
              width: 420,
              height: 300,
              color: isDark ? const Color(0xFF25394A) : const Color(0xFFCBE5E6),
              opacity: isDark ? 0.38 : 0.38,
              borderRadius: 220,
            ),
          ),

          // Liten lys/mørk organisk form øverst
          Positioned(
            top: 90,
            right: 30,
            child: _buildBackgroundShape(
              width: 180,
              height: 180,
              color: isDark ? const Color(0xFF29314A) : Colors.white,
              opacity: isDark ? 0.42 : 0.50,
              borderRadius: 110,
            ),
          ),

          // ─────────────────────────────────────────
          // Innhold
          // ─────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 130),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'God dag!',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.7,
                      color: colors.onSurface,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Hvordan går det med deg i dag?',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 15,
                      color: colors.onSurface.withValues(alpha: 0.55),
                    ),
                  ),

                  const SizedBox(height: 30),

                  StatusWidget(key: _statusWidgetKey),

                  const SizedBox(height: 42),

                  const PanicButton(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),

      // ───────────────────────────────────────────
      // Bottom navigation
      // ───────────────────────────────────────────
      bottomNavigationBar: BottomAppBar(
        color: colors.surface.withValues(alpha: 0.97),
        elevation: 12,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              Expanded(
                child: _buildNavItem(
                  icon: const _TodayIcon(),
                  label: 'I dag',
                  index: 0,
                ),
              ),

              Expanded(
                child: _buildNavItem(
                  icon: const _ResourcesIcon(),
                  label: 'Ressurser',
                  index: 1,
                ),
              ),

              const SizedBox(width: 82),

              Expanded(
                child: _buildNavItem(
                  icon: const _CalendarIcon(),
                  label: 'Kalender',
                  index: 2,
                ),
              ),

              Expanded(
                child: _buildNavItem(
                  icon: const _ProfileIcon(),
                  label: 'Profil',
                  index: 3,
                ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: const DailyCheckinFab(),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBackgroundShape({
    required double width,
    required double height,
    required Color color,
    required double opacity,
    required double borderRadius,
  }) {
    return IgnorePointer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: color.withValues(alpha: opacity),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required Widget icon,
    required String label,
    required int index,
  }) {
    final colors = Theme.of(context).colorScheme;
    final isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () => _onNavigationTap(index),
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,

            const SizedBox(height: 5),

            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                color: isSelected
                    ? colors.primary
                    : colors.onSurface.withValues(alpha: 0.38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Custom navigation icons
// ═══════════════════════════════════════════════════

class _TodayIcon extends StatelessWidget {
  const _TodayIcon();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return CustomPaint(
      size: const Size(25, 25),
      painter: _TodayIconPainter(
        color: colors.onSurface.withValues(alpha: 0.38),
      ),
    );
  }
}

class _ResourcesIcon extends StatelessWidget {
  const _ResourcesIcon();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return CustomPaint(
      size: const Size(25, 25),
      painter: _ResourcesIconPainter(
        color: colors.onSurface.withValues(alpha: 0.38),
      ),
    );
  }
}

class _CalendarIcon extends StatelessWidget {
  const _CalendarIcon();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return CustomPaint(
      size: const Size(25, 25),
      painter: _CalendarIconPainter(
        color: colors.onSurface.withValues(alpha: 0.38),
      ),
    );
  }
}

class _ProfileIcon extends StatelessWidget {
  const _ProfileIcon();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return CustomPaint(
      size: const Size(25, 25),
      painter: _ProfileIconPainter(
        color: colors.onSurface.withValues(alpha: 0.38),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// I dag
// ═══════════════════════════════════════════════════

class _TodayIconPainter extends CustomPainter {
  final Color color;

  _TodayIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(3, 4, 19, 18),
      const Radius.circular(5),
    );

    canvas.drawRRect(rect, paint);

    canvas.drawLine(const Offset(3.5, 9), const Offset(21.5, 9), paint);

    canvas.drawLine(const Offset(8, 2.5), const Offset(8, 6), paint);

    canvas.drawLine(const Offset(17, 2.5), const Offset(17, 6), paint);

    final checkPath = Path()
      ..moveTo(8, 15)
      ..lineTo(10.5, 17.5)
      ..lineTo(17, 12);

    canvas.drawPath(checkPath, paint);
  }

  @override
  bool shouldRepaint(covariant _TodayIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

// ═══════════════════════════════════════════════════
// Ressurser
// ═══════════════════════════════════════════════════

class _ResourcesIconPainter extends CustomPainter {
  final Color color;

  _ResourcesIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final left = RRect.fromRectAndRadius(
      Rect.fromLTWH(3, 5, 9, 15),
      const Radius.circular(3),
    );

    final right = RRect.fromRectAndRadius(
      Rect.fromLTWH(13, 5, 9, 15),
      const Radius.circular(3),
    );

    canvas.drawRRect(left, paint);
    canvas.drawRRect(right, paint);

    canvas.drawLine(const Offset(7, 9), const Offset(9, 9), paint);

    canvas.drawLine(const Offset(7, 13), const Offset(9, 13), paint);

    canvas.drawLine(const Offset(17, 9), const Offset(19, 9), paint);

    canvas.drawLine(const Offset(17, 13), const Offset(19, 13), paint);
  }

  @override
  bool shouldRepaint(covariant _ResourcesIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

// ═══════════════════════════════════════════════════
// Kalender
// ═══════════════════════════════════════════════════

class _CalendarIconPainter extends CustomPainter {
  final Color color;

  _CalendarIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(3, 4, 19, 18),
      const Radius.circular(5),
    );

    canvas.drawRRect(rect, paint);

    canvas.drawLine(const Offset(3.5, 9), const Offset(21.5, 9), paint);

    canvas.drawLine(const Offset(8, 2.5), const Offset(8, 6), paint);

    canvas.drawLine(const Offset(17, 2.5), const Offset(17, 6), paint);

    // Diskréte prikker som kalenderinnhold.
    canvas.drawCircle(const Offset(8, 13), 0.9, paint);

    canvas.drawCircle(const Offset(13, 13), 0.9, paint);

    canvas.drawCircle(const Offset(18, 13), 0.9, paint);

    canvas.drawCircle(const Offset(8, 17), 0.9, paint);

    canvas.drawCircle(const Offset(13, 17), 0.9, paint);
  }

  @override
  bool shouldRepaint(covariant _CalendarIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

// ═══════════════════════════════════════════════════
// Profil
// ═══════════════════════════════════════════════════

class _ProfileIconPainter extends CustomPainter {
  final Color color;

  _ProfileIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Hode
    canvas.drawCircle(const Offset(12.5, 8), 4, paint);

    // Skuldre / kropp
    final bodyPath = Path()
      ..moveTo(5, 21)
      ..cubicTo(5.5, 16.5, 8.5, 14, 12.5, 14)
      ..cubicTo(16.5, 14, 19.5, 16.5, 20, 21);

    canvas.drawPath(bodyPath, paint);
  }

  @override
  bool shouldRepaint(covariant _ProfileIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
