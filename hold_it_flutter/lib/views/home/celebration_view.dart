import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/app_state.dart';
import '../../viewmodels/store_manager.dart';
import '../../models/models.dart';
import '../../utils/constants.dart';
import 'record_sheet.dart';

class CelebrationView extends StatefulWidget {
  const CelebrationView({super.key});

  @override
  State<CelebrationView> createState() => _CelebrationViewState();
}

class _CelebrationViewState extends State<CelebrationView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final List<String> _emojis = ['🎉', '✨', '🎊', '💪', '🔥', '🌟', '❤️', '👏'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _spawnParticles();
    _controller.forward();
  }

  void _spawnParticles() {
    final size = MediaQuery.of(context).size;
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle(
        emoji: _emojis[i % _emojis.length],
        startX: size.width * 0.2 + (size.width * 0.6 * (i / 30)),
        endX: size.width * 0.1 + (size.width * 0.8 * (i / 30)),
        startY: size.height + 40,
        endY: size.height * 0.1 + (size.height * 0.4 * (i / 30)),
        delay: i * 0.05,
        duration: 0.8 + (i % 5) * 0.1,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: _particles.map((p) => _ParticleWidget(particle: p, controller: _controller)).toList(),
      ),
    );
  }
}

class _Particle {
  final String emoji;
  final double startX;
  final double endX;
  final double startY;
  final double endY;
  final double delay;
  final double duration;

  _Particle({
    required this.emoji,
    required this.startX,
    required this.endX,
    required this.startY,
    required this.endY,
    required this.delay,
    required this.duration,
  });
}

class _ParticleWidget extends StatelessWidget {
  final _Particle particle;
  final AnimationController controller;

  const _ParticleWidget({required this.particle, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final progress = ((controller.value - particle.delay) / particle.duration).clamp(0.0, 1.0);
        if (progress <= 0) return const SizedBox.shrink();

        final x = particle.startX + (particle.endX - particle.startX) * progress;
        final y = particle.startY + (particle.endY - particle.startY) * progress;
        final opacity = progress < 0.8 ? 1.0 : 1.0 - (progress - 0.8) / 0.2;
        final scale = progress < 0.1 ? progress / 0.1 : 1.0;

        return Positioned(
          left: x - 18,
          top: y - 18,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Text(
                particle.emoji,
                style: const TextStyle(fontSize: 36),
              ),
            ),
          ),
        );
      },
    );
  }
}
