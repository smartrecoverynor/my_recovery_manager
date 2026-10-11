import 'dart:math';
import 'package:flutter/material.dart';

class SuccessCelebration extends StatefulWidget {
  final VoidCallback onFinished;

  const SuccessCelebration({
    super.key,
    required this.onFinished,
  });

  @override
  State<SuccessCelebration> createState() => _SuccessCelebrationState();
}

class _SuccessCelebrationState extends State<SuccessCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final Random _random = Random();

  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();

    _particles = List.generate(
      55,
          (_) => _Particle(
        angle: _random.nextDouble() * 2 * pi,
        distance: 65 + _random.nextDouble() * 105,
        size: 2.5 + _random.nextDouble() * 3.5,
        rotation: _random.nextDouble() * 2 * pi,
        isSquare: _random.nextBool(),
      ),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _controller.forward().whenComplete(() {
      if (mounted) {
        widget.onFinished();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final cardAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.0,
        0.65,
        curve: Curves.easeOutBack,
      ),
    );

    final contentAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.15,
        0.65,
        curve: Curves.easeOut,
      ),
    );

    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.86 + (cardAnimation.value * 0.14),
            child: Opacity(
              opacity: Curves.easeOut.transform(
                (_controller.value / 0.18).clamp(0.0, 1.0),
              ),
              child: child,
            ),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 320,
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.7),
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.22),
                  blurRadius: 35,
                  offset: const Offset(0, 16),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 210,
                  height: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(210, 150),
                            painter: _FireworkPainter(
                              particles: _particles,
                              progress: _controller.value,
                              primaryColor: colors.primary,
                              secondaryColor: colors.secondary,
                              tertiaryColor: colors.tertiary,
                            ),
                          );
                        },
                      ),

                      AnimatedBuilder(
                        animation: contentAnimation,
                        builder: (context, child) {
                          final value = contentAnimation.value;

                          return Transform.scale(
                            scale: 0.65 + (value * 0.35),
                            child: Opacity(
                              opacity: value,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.primaryContainer,
                            boxShadow: [
                              BoxShadow(
                                color: colors.primary.withValues(alpha: 0.20),
                                blurRadius: 24,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 44,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Godt jobbet!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 27,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: colors.onSurface,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Du har registrert en alkoholfri dag.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.45,
                    color: colors.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  height: 4,
                  width: 42,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
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

class _Particle {
  final double angle;
  final double distance;
  final double size;
  final double rotation;
  final bool isSquare;

  const _Particle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.rotation,
    required this.isSquare,
  });
}

class _FireworkPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;

  const _FireworkPainter({
    required this.particles,
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final particleProgress = Curves.easeOutCubic.transform(
      progress.clamp(0.0, 1.0),
    );

    final opacity = (1 - Curves.easeIn.transform(progress)).clamp(
      0.0,
      1.0,
    );

    final colors = [
      primaryColor,
      secondaryColor,
      tertiaryColor,
      primaryColor.withValues(alpha: 0.75),
      secondaryColor.withValues(alpha: 0.75),
    ];

    for (var i = 0; i < particles.length; i++) {
      final particle = particles[i];

      final currentDistance = particle.distance * particleProgress;

      final position = Offset(
        center.dx + cos(particle.angle) * currentDistance,
        center.dy + sin(particle.angle) * currentDistance,
      );

      final particleOpacity = opacity * 0.9;
      final particleSize =
          particle.size * (1 - (progress * 0.35)).clamp(0.45, 1.0);

      final paint = Paint()
        ..color = colors[i % colors.length].withValues(
          alpha: particleOpacity,
        )
        ..style = PaintingStyle.fill;

      if (particle.isSquare) {
        canvas.save();

        canvas.translate(position.dx, position.dy);
        canvas.rotate(
          particle.rotation + progress * 4,
        );

        final rect = Rect.fromCenter(
          center: Offset.zero,
          width: particleSize * 1.5,
          height: particleSize * 1.5,
        );

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect,
            Radius.circular(particleSize * 0.35),
          ),
          paint,
        );

        canvas.restore();
      } else {
        canvas.drawCircle(
          position,
          particleSize,
          paint,
        );
      }
    }

    // Subtle expanding glow behind the checkmark.
    final glowProgress = Curves.easeOut.transform(
      (progress / 0.7).clamp(0.0, 1.0),
    );

    final glowPaint = Paint()
      ..color = primaryColor.withValues(
        alpha: 0.08 * (1 - glowProgress),
      )
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      center,
      38 + (18 * glowProgress),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FireworkPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.tertiaryColor != tertiaryColor;
  }
}