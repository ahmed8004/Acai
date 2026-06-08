import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';

class OrbWidget extends StatefulWidget {
  final OrbState state;
  final double size;
  final bool isListening;
  final VoidCallback? onTap;

  const OrbWidget({
    super.key,
    required this.state,
    this.size = 200,
    this.isListening = false,
    this.onTap,
  });

  @override
  State<OrbWidget> createState() => _OrbWidgetState();
}

class _OrbWidgetState extends State<OrbWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _waveController,
        curve: Curves.easeOut,
      ),
    );

    _updateAnimationState();
  }

  void _updateAnimationState() {
    switch (widget.state) {
      case OrbState.idle:
        _pulseController.repeat(reverse: true);
        _rotationController.stop();
        _waveController.stop();
        break;
      case OrbState.listening:
        _pulseController.repeat(reverse: true);
        _rotationController.repeat();
        _waveController.repeat();
        break;
      case OrbState.thinking:
        _pulseController.repeat(reverse: true);
        _rotationController.repeat();
        _waveController.stop();
        break;
      case OrbState.speaking:
        _pulseController.repeat(reverse: true);
        _rotationController.repeat();
        _waveController.repeat();
        break;
      case OrbState.executing:
        _pulseController.repeat(reverse: true);
        _rotationController.repeat();
        _waveController.stop();
        break;
      case OrbState.error:
        _pulseController.stop();
        _rotationController.stop();
        _waveController.stop();
        break;
      case OrbState.paused:
        _pulseController.stop();
        _rotationController.stop();
        _waveController.stop();
        break;
      case OrbState.stopped:
        _pulseController.stop();
        _rotationController.stop();
        _waveController.stop();
        break;
    }
  }

  @override
  void didUpdateWidget(OrbWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updateAnimationState();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _pulseController,
          _rotationController,
          _waveController,
        ]),
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              _buildOuterGlow(),
              _buildWaveRings(),
              _buildMainOrb(),
              _buildInnerGlow(),
              _buildCore(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOuterGlow() {
    return Container(
      width: widget.size * 1.5 * _pulseAnimation.value,
      height: widget.size * 1.5 * _pulseAnimation.value,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppTheme.getOrbColor(widget.state).withOpacity(0.2),
            AppTheme.getOrbColor(widget.state).withOpacity(0.0),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveRings() {
    if (widget.state != OrbState.listening && widget.state != OrbState.speaking) {
      return const SizedBox.shrink();
    }

    return Stack(
      alignment: Alignment.center,
      children: List.generate(3, (index) {
        final delay = index * 0.3;
        final progress = (_waveAnimation.value + delay) % 1.0;
        
        return Container(
          width: widget.size * (1.0 + progress * 0.5),
          height: widget.size * (1.0 + progress * 0.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.getOrbColor(widget.state).withOpacity(
                (1.0 - progress) * 0.5,
              ),
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMainOrb() {
    return Container(
      width: widget.size * _pulseAnimation.value,
      height: widget.size * _pulseAnimation.value,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [
            AppTheme.getOrbColor(widget.state).withOpacity(0.8),
            AppTheme.getOrbColor(widget.state),
            AppTheme.getOrbColor(widget.state).withOpacity(0.6),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getOrbColor(widget.state).withOpacity(0.5),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: CustomPaint(
        painter: OrbPainter(
          color: AppTheme.getOrbColor(widget.state),
          rotation: _rotationController.value * 2 * math.pi,
        ),
      ),
    );
  }

  Widget _buildInnerGlow() {
    return Container(
      width: widget.size * 0.7 * _pulseAnimation.value,
      height: widget.size * 0.7 * _pulseAnimation.value,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(0.3, 0.3),
          colors: [
            Colors.white.withOpacity(0.3),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildCore() {
    return Container(
      width: widget.size * 0.4,
      height: widget.size * 0.4,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withOpacity(0.9),
            AppTheme.getOrbColor(widget.state).withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: widget.state == OrbState.listening || widget.state == OrbState.speaking
          ? _buildAudioVisualizer()
          : null,
    );
  }

  Widget _buildAudioVisualizer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 4,
          height: 20 + (index % 2 == 0 ? 10 : -5) + (_waveAnimation.value * 15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

class OrbPainter extends CustomPainter {
  final Color color;
  final double rotation;

  OrbPainter({
    required this.color,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 6; i++) {
      final angle = rotation + (i * math.pi / 3);
      final path = Path();
      
      for (double t = 0; t <= 1; t += 0.01) {
        final r = radius * (0.8 + 0.1 * math.sin(t * 6 * math.pi + angle));
        final x = center.dx + r * math.cos(t * 2 * math.pi + angle);
        final y = center.dy + r * math.sin(t * 2 * math.pi + angle);
        
        if (t == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
