import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class CelebrationBurst extends StatefulWidget {
  const CelebrationBurst({super.key, this.child});

  final Widget? child;

  @override
  State<CelebrationBurst> createState() => _CelebrationBurstState();
}

class _CelebrationBurstState extends State<CelebrationBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _BurstPainter(_controller.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(7);
    final center = size.center(Offset.zero);
    const colors = [SplytPalette.mint, SplytPalette.coral, SplytPalette.gold];
    for (var i = 0; i < 18; i++) {
      final angle = (i / 18) * pi * 2 + t;
      final dist = 24 + t * (40 + rnd.nextInt(50));
      final paint = Paint()..color = colors[i % 3].withOpacity(1 - t);
      canvas.drawCircle(
        center + Offset(cos(angle) * dist, sin(angle) * dist),
        4 + rnd.nextDouble() * 3,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) => oldDelegate.t != t;
}
