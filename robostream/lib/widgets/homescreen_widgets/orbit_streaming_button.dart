import 'package:flutter/material.dart';

class OrbitStreamingButton extends StatefulWidget {
  final bool isConnected;
  final bool isStreamingToLG;
  final bool isOrbitRunning;
  final List<String> selectedSensors;
  final VoidCallback onStreamingTap;
  final VoidCallback onOrbitTap;

  const OrbitStreamingButton({
    super.key,
    required this.isConnected,
    required this.isStreamingToLG,
    required this.isOrbitRunning,
    required this.selectedSensors,
    required this.onStreamingTap,
    required this.onOrbitTap,
  });

  @override
  State<OrbitStreamingButton> createState() => _OrbitStreamingButtonState();
}

class _OrbitStreamingButtonState extends State<OrbitStreamingButton> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isStreamingGPS = widget.isStreamingToLG && 
                          widget.selectedSensors.contains('GPS Position');
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStreamingButton(),
        const SizedBox(height: 12),
        if (isStreamingGPS) _buildOrbitButton(),
      ],
    );
  }

  Widget _buildStreamingButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: widget.isConnected
                ? (widget.isStreamingToLG
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF6366F1))
                : Colors.grey.shade400,
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(28),
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: widget.isConnected ? widget.onStreamingTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: widget.isConnected
                  ? LinearGradient(
                      colors: widget.isStreamingToLG
                          ? [
                              const Color(0xFFEF4444),
                              const Color(0xFFDC2626),
                            ]
                          : [
                              const Color(0xFF6366F1),
                              const Color(0xFF8B5CF6),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        Colors.grey.shade500,
                        Colors.grey.shade600,
                      ],
                    ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: Container(
                    key: ValueKey(widget.isStreamingToLG),
                    width: 20,
                    height: 20,
                    child: Icon(
                      widget.isStreamingToLG
                          ? Icons.stop_rounded
                          : Icons.rocket_launch_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    widget.isStreamingToLG
                        ? 'Stop Streaming'
                        : (widget.isConnected ? 'Start Streaming' : 'Robot Offline'),
                    key: ValueKey('${widget.isStreamingToLG}_${widget.isConnected}'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrbitButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: widget.isOrbitRunning
                ? const Color(0xFFEF4444)
                : const Color(0xFF10B981),
            blurRadius: widget.isOrbitRunning ? 25 : 15,
            offset: const Offset(0, 6),
            spreadRadius: widget.isOrbitRunning ? 2 : 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(28),
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: widget.onOrbitTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: widget.isOrbitRunning
                    ? [
                        const Color(0xFFEF4444),
                        const Color(0xFFDC2626),
                      ]
                    : [
                        const Color(0xFF10B981),
                        const Color(0xFF059669),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return RotationTransition(
                      turns: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: Container(
                    key: ValueKey(widget.isOrbitRunning),
                    width: 18,
                    height: 18,
                    child: widget.isOrbitRunning
                        ? const Icon(
                            Icons.stop_circle_outlined,
                            color: Colors.white,
                            size: 18,
                          )
                        : const Icon(
                            Icons.threesixty_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    widget.isOrbitRunning ? 'Stop Orbit' : 'Start Orbit',
                    key: ValueKey(widget.isOrbitRunning),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
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

class OrbitInfoIndicator extends StatelessWidget {
  final bool isOrbitRunning;
  final Map<String, dynamic>? orbitInfo;

  const OrbitInfoIndicator({
    super.key,
    required this.isOrbitRunning,
    this.orbitInfo,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOrbitRunning) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.threesixty_rounded,
            color: Color(0xFF10B981),
            size: 16,
          ),
          const SizedBox(width: 8),
          const Text(
            'Orbit Active',
            style: TextStyle(
              color: Color(0xFF10B981),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (orbitInfo != null && orbitInfo!['steps'] != null) ...[
            const SizedBox(width: 8),
            Text(
              '${orbitInfo!['steps']} steps',
              style: TextStyle(
                color: const Color(0xFF10B981).withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
