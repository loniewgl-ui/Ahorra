// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/ahorra_colors.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Navigate after the animation + a small hold
    Future.delayed(const Duration(milliseconds: 2400), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AuthGate(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AhorraColors.bgTop, AhorraColors.bgBottom],
          ),
        ),
        child: Stack(
          children: [
            // Floating finance particles
            const _FinanceParticles(),

            // Central content
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => FadeTransition(
                  opacity: _fadeAnimation,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Wallet icon with glow
                          SizedBox(
                            width: size.width * 0.24,
                            height: size.width * 0.24,
                            child: CustomPaint(
                              painter: _PulsingGlowPainter(),
                              child: Center(
                                child: Container(
                                  width: size.width * 0.22,
                                  height: size.width * 0.22,
                                  decoration: BoxDecoration(
                                    color: AhorraColors.teal.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(
                                        size.width * 0.06),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            AhorraColors.teal.withOpacity(0.35),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet_outlined,
                                    color: Colors.white,
                                    size: 46,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: size.height * 0.04),

                          // App name
                          Text(
                            'Ahorra',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: size.width * 0.14,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 2.5,
                              height: 1.0,
                            ),
                          ),

                          SizedBox(height: size.height * 0.012),

                          // Tagline
                          Text(
                            'Your personal finance companion',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: size.width * 0.034,
                              letterSpacing: 0.4,
                              fontWeight: FontWeight.w400,
                            ),
                          ),

                          SizedBox(height: size.height * 0.06),

                          // Loading bar
                          Container(
                            width: size.width * 0.25,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _LoadingBar(width: size.width * 0.25),
                          ),
                        ],
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
  }
}

// ─── Finance floating particles (currency symbols + chart line) ──────────────
class _FinanceParticles extends StatefulWidget {
  const _FinanceParticles();

  @override
  State<_FinanceParticles> createState() => _FinanceParticlesState();
}

class _FinanceParticlesState extends State<_FinanceParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _particlesController;
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    final rng = math.Random(42);

    const symbols = ['₱', '\$', '€', '¥', '₹', '💵', '💳', '📈'];

    for (int i = 0; i < 12; i++) {
      _particles.add(_Particle(
        symbol: symbols[rng.nextInt(symbols.length)],
        xFraction: rng.nextDouble(),
        yFraction: rng.nextDouble() * 1.2,
        size: 12 + rng.nextDouble() * 18,
        speed: 0.3 + rng.nextDouble() * 0.5,
        opacity: 0.06 + rng.nextDouble() * 0.1,
      ));
    }

    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addListener(() {
        setState(() {
          for (final p in _particles) {
            p.offset = -p.speed * _particlesController.value;
          }
        });
      });

    _particlesController.repeat();
  }

  @override
  void dispose() {
    _particlesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _ParticlePainter(
          particles: _particles,
          progress: _particlesController.value,
        ),
      ),
    );
  }
}

class _Particle {
  final String symbol;
  final double xFraction;
  final double yFraction;
  final double size;
  final double speed;
  final double opacity;
  double offset = 0;

  _Particle({
    required this.symbol,
    required this.xFraction,
    required this.yFraction,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      double y = (p.yFraction * size.height) + p.offset * size.height;
      y = y % (size.height * 1.2);
      if (y < -20) y += size.height * 1.2;

      final x = p.xFraction * size.width;

      final textStyle = TextStyle(
        fontSize: p.size,
        fontWeight: FontWeight.w300,
        color: Colors.white.withOpacity(p.opacity),
      );
      final tp = TextPainter(
        text: TextSpan(text: p.symbol, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x, y));
    }

    // Subtle chart line
    final chartPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    path.moveTo(0, size.height * 0.6);
    for (double x = 0; x < size.width; x += 30) {
      path.lineTo(
          x, size.height * 0.6 + math.sin(x * 0.02 + progress * 6.28 * 2) * 30);
    }
    canvas.drawPath(path, chartPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ─── Pulsing glow around the wallet icon ─────────────────────────────────────
class _PulsingGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.45;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AhorraColors.teal.withOpacity(0.25),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Loading bar (animated) ─────────────────────────────────────────────────
class _LoadingBar extends StatefulWidget {
  final double width;
  const _LoadingBar({required this.width});

  @override
  State<_LoadingBar> createState() => _LoadingBarState();
}

class _LoadingBarState extends State<_LoadingBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _barController;
  late Animation<double> _barAnimation;

  @override
  void initState() {
    super.initState();
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _barAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _barController, curve: Curves.easeInOut),
    );
    _barController.forward();
  }

  @override
  void dispose() {
    _barController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _barAnimation,
      builder: (_, __) {
        return FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: _barAnimation.value,
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
    );
  }
}
