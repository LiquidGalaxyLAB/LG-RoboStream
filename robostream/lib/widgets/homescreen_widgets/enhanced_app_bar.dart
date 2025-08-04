import 'dart:math' as math;
import 'package:flutter/material.dart';

const _kParticlePositions = [
  Offset(50, 30),
  Offset(250, 80),
  Offset(150, 40),
  Offset(300, 60),
  Offset(100, 120),
  Offset(200, 100),
  Offset(70, 90),
  Offset(320, 100),
];

const _kParticleSizes = [80.0, 60.0, 90.0, 70.0, 85.0, 75.0, 65.0, 95.0];

const _kParticleColors = [
  Color(0xFF6366F1),
  Color(0xFF8B5CF6),
  Color(0xFF06B6D4),
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFFEF4444),
  Color(0xFF6366F1),
  Color(0xFF8B5CF6),
];

class EnhancedAppBar extends StatelessWidget {
  final Animation<double> parallaxAnimation;
  final Animation<double> indicatorsAnimation;
  final bool isConnected;
  final bool isLGConnected;
  final bool isRobotConnected;
  final VoidCallback onConfigTap;

  const EnhancedAppBar({
    super.key,
    required this.parallaxAnimation,
    required this.indicatorsAnimation,
    required this.isConnected,
    required this.isLGConnected,
    required this.isRobotConnected,
    required this.onConfigTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      pinned: true,
      expandedHeight: 200.0,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        centerTitle: true,
        title: HeaderTitle(
          indicatorsAnimation: indicatorsAnimation,
          isConnected: isConnected,
          isLGConnected: isLGConnected,
          isRobotConnected: isRobotConnected,
        ),
        background: AnimatedBuilder(
          animation: parallaxAnimation,
          builder: (context, child) {
            return Stack(
              children: [
                ...List.generate(8, (index) => _buildModernBackgroundParticle(index)),
              ],
            );
          },
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: UnifiedConfigButton(onTap: onConfigTap),
        ),
      ],
    );
  }

  Widget _buildModernBackgroundParticle(int index) {
    return AnimatedBuilder(
      animation: parallaxAnimation,
      builder: (context, child) {
        final animatedValue = (parallaxAnimation.value + (index * 0.125)) % 1.0;
        final sinValue = math.sin(animatedValue * math.pi * 2);
        final cosValue = math.cos(animatedValue * math.pi * 2);
        final baseOpacity = 0.01;
        final variation = 0.005 * sinValue.abs();
        final opacity = (baseOpacity + variation).clamp(0.0, 1.0);
        
        return Positioned(
          left: _kParticlePositions[index].dx + (20 * sinValue),
          top: _kParticlePositions[index].dy + (15 * cosValue),
          child: Transform.rotate(
            angle: animatedValue * math.pi * 2,
            child: Container(
              width: _kParticleSizes[index],
              height: _kParticleSizes[index],
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _kParticleColors[index].withOpacity(opacity),
                    _kParticleColors[index].withOpacity(opacity * 0.5),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class HeaderTitle extends StatelessWidget {
  final Animation<double> indicatorsAnimation;
  final bool isConnected;
  final bool isLGConnected;
  final bool isRobotConnected;

  const HeaderTitle({
    super.key,
    required this.indicatorsAnimation,
    required this.isConnected,
    required this.isLGConnected,
    required this.isRobotConnected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool hasEnoughHeight = constraints.maxHeight > 70;
        bool hasVeryLimitedHeight = constraints.maxHeight < 50;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              Flexible(
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFF06B6D4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    style: TextStyle(
                      fontSize: hasEnoughHeight ? 32 : (hasVeryLimitedHeight ? 18 : 22),
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: hasEnoughHeight ? -1.2 : -0.8,
                      height: hasVeryLimitedHeight ? 0.9 : 0.95,
                    ),
                    child: const Text(
                      'RoboStream',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              if (!hasVeryLimitedHeight)
                AnimatedBuilder(
                  animation: indicatorsAnimation,
                  builder: (context, child) {
                    double opacity = indicatorsAnimation.value.clamp(0.0, 1.0);
                    
                    if (opacity < 0.02) {
                      return const SizedBox.shrink();
                    }
                    
                    return Flexible(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: EdgeInsets.only(top: hasEnoughHeight ? 12 : 4),
                        child: Transform.scale(
                          scale: (0.7 + (0.3 * opacity)).clamp(0.1, 1.0),
                          child: Transform.translate(
                            offset: Offset(
                              (1.0 - opacity) * 2.0,
                              (1.0 - opacity) * 4.0,
                            ),
                            child: Opacity(
                              opacity: opacity,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ModernConnectionStatus(
                                    isConnected: isConnected,
                                    label: 'Server',
                                  ),
                                  const SizedBox(width: 16),
                                  ModernConnectionStatus(
                                    isConnected: isRobotConnected,
                                    label: 'Robot',
                                  ),
                                  const SizedBox(width: 16),
                                  ModernConnectionStatus(
                                    isConnected: isLGConnected,
                                    label: 'LG Connection',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      );
  }
}

class ModernConnectionStatus extends StatelessWidget {
  final bool isConnected;
  final String label;

  const ModernConnectionStatus({
    super.key,
    required this.isConnected,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isConnected 
                ? const Color(0xFF10B981) 
                : const Color(0xFFEF4444),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isConnected 
                    ? const Color(0xFF10B981) 
                    : const Color(0xFFEF4444)).withOpacity(0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isConnected 
                ? const Color(0xFF10B981) 
                : const Color(0xFFEF4444),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class UnifiedConfigButton extends StatelessWidget {
  final VoidCallback onTap;

  const UnifiedConfigButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Colors.white,
            Color(0xFFF8F9FA),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: const Icon(
            Icons.tune_rounded,
            color: Color(0xFF6366F1),
            size: 22,
          ),
        ),
      ),
    );
  }
}
