import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:robostream/core/widgets/telemetry_card.dart';
import 'package:robostream/core/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fabController;
  late AnimationController _parallaxController;
  late AnimationController _headerController;
  late AnimationController _statsController;
  late AnimationController _pulseController;
  
  late Animation<double> _fabAnimation;
  late Animation<double> _parallaxAnimation;
  late Animation<double> _headerSlideAnimation;
  late Animation<double> _statsAnimation;
  late Animation<double> _pulseAnimation;
  
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  bool _isConnected = false;
  int _activeStreams = 3;
  String _robotStatus = "Active";

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupScrollListener();
    _startContinuousAnimations();
  }

  void _initializeAnimations() {
    _fabController = AnimationController(
      duration: AppTheme.mediumDuration,
      vsync: this,
    );
    _parallaxController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _statsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: AppTheme.bouncyCurve),
    );
    _parallaxAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _parallaxController, curve: Curves.linear),
    );
    _headerSlideAnimation = Tween<double>(begin: -50.0, end: 0.0).animate(
      CurvedAnimation(parent: _headerController, curve: AppTheme.smoothCurve),
    );
    _statsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _statsController, curve: AppTheme.bouncyCurve),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _fabController.forward();
    _headerController.forward();
    _statsController.forward();
  }

  void _startContinuousAnimations() {
    _parallaxController.repeat();
    _pulseController.repeat(reverse: true);
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    _parallaxController.dispose();
    _headerController.dispose();
    _statsController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isConnected = !_isConnected;
      _activeStreams = math.Random().nextInt(5) + 1;
    });
    await Future.delayed(const Duration(milliseconds: 1500));
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final cardsData = [
      {
        'icon': Icons.camera_alt_outlined, 
        'label': 'RGB Camera', 
        'color': const Color(0xFF6366F1),
        'status': 'Online',
        'value': '1080p'
      },
      {
        'icon': Icons.camera_rounded, 
        'label': 'Stereo Camera', 
        'color': const Color(0xFF8B5CF6),
        'status': 'Online',
        'value': '720p'
      },
      {
        'icon': Icons.location_on_outlined, 
        'label': 'Location', 
        'color': const Color(0xFF06B6D4),
        'status': 'Active',
        'value': 'GPS'
      },
      {
        'icon': Icons.speed_outlined, 
        'label': 'Odometry', 
        'color': const Color(0xFF10B981),
        'status': 'Tracking',
        'value': '2.3 m/s'
      },
      {
        'icon': Icons.precision_manufacturing_outlined, 
        'label': 'Servos', 
        'color': const Color(0xFFF59E0B),
        'status': 'Ready',
        'value': '6 DOF'
      },
      {
        'icon': Icons.settings_outlined, 
        'label': 'Connection', 
        'color': const Color(0xFFEF4444),
        'status': _isConnected ? 'Connected' : 'Offline',
        'value': _isConnected ? 'Stable' : 'N/A'
      },
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          backgroundColor: Colors.white,
          color: AppTheme.primaryColor,
          strokeWidth: 3,
          displacement: 120,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildEnhancedAppBar(),
              _buildStatsSection(),
              _buildQuickActionsSection(),
              _buildEnhancedGrid(cardsData),
              _buildFooterSection(),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildEnhancedFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildEnhancedAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      pinned: true,
      expandedHeight: 180.0,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        centerTitle: false,
        title: AnimatedBuilder(
          animation: _headerSlideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_headerSlideAnimation.value, -_scrollOffset * 0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                    child: const Text(
                      'RoboStream',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 32,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _pulseAnimation.value,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isConnected ? AppTheme.successColor : AppTheme.errorColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isConnected ? AppTheme.successColor : AppTheme.errorColor)
                                        .withOpacity(0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isConnected ? 'Robot Connected' : 'Robot Offline',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
        background: AnimatedBuilder(
          animation: _parallaxAnimation,
          builder: (context, child) {
            return Stack(
              children: [
                ...List.generate(6, (index) => _buildBackgroundParticle(index)),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppTheme.backgroundColor.withOpacity(0.3),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeaderButton(
                icon: Icons.settings_outlined,
                onPressed: () => HapticFeedback.lightImpact(),
              ),
              const SizedBox(width: 12),
              _buildHeaderButton(
                icon: Icons.notifications_outlined,
                onPressed: () => HapticFeedback.lightImpact(),
                badge: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool badge = false,
  }) {
    return AnimatedContainer(
      duration: AppTheme.mediumDuration,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Stack(
        children: [
          IconButton(
            icon: Icon(icon),
            color: AppTheme.primaryColor,
            iconSize: 24,
            onPressed: onPressed,
          ),
          if (badge)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.errorColor,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _statsAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 30 * (1 - _statsAnimation.value)),
            child: Opacity(
              opacity: _statsAnimation.value.clamp(0.0, 1.0),
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFFAFBFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Active Streams',
                        '$_activeStreams',
                        Icons.stream,
                        AppTheme.primaryColor,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.shade200,
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Robot Status',
                        _robotStatus,
                        Icons.memory,
                        AppTheme.successColor,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.shade200,
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Uptime',
                        '2h 34m',
                        Icons.timer,
                        AppTheme.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    'Emergency Stop',
                    Icons.stop_circle_outlined,
                    AppTheme.errorColor,
                    () => HapticFeedback.heavyImpact(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    'Reset Position',
                    Icons.home_outlined,
                    AppTheme.warningColor,
                    () => HapticFeedback.mediumImpact(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    'Calibrate',
                    Icons.tune_outlined,
                    AppTheme.accentColor,
                    () => HapticFeedback.lightImpact(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundParticle(int index) {
    final positions = [
      const Offset(50, 30),
      const Offset(250, 80),
      const Offset(150, 40),
      const Offset(300, 60),
      const Offset(100, 120),
      const Offset(200, 100),
    ];
    final sizes = [60.0, 80.0, 70.0, 90.0, 65.0, 75.0];

    return AnimatedBuilder(
      animation: _parallaxAnimation,
      builder: (context, child) {
        final animatedValue = (_parallaxAnimation.value + (index * 0.16)) % 1.0;
        final sinValue = math.sin(animatedValue * math.pi);
        final baseOpacity = 0.04;
        final variation = 0.03 * sinValue.abs();
        final opacity = (baseOpacity + variation).clamp(0.0, 1.0);
        
        return Positioned(
          left: positions[index].dx + (15 * math.sin(animatedValue * 2 * math.pi)),
          top: positions[index].dy + (10 * math.cos(animatedValue * 2 * math.pi)),
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: sizes[index],
              height: sizes[index],
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.12),
                    AppTheme.accentColor.withOpacity(0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedGrid(List<Map<String, dynamic>> cardsData) {
    return SliverPadding(
      padding: const EdgeInsets.all(24.0),
      sliver: SliverGrid.count(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 0.85,
        children: List.generate(cardsData.length, (index) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 600 + (index * 100)),
            curve: AppTheme.bouncyCurve,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 50 * (1 - value)),
                child: Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: TelemetryCard(
                      icon: cardsData[index]['icon'] as IconData,
                      label: cardsData[index]['label'] as String,
                      color: cardsData[index]['color'] as Color,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _showCardDetails(cardsData[index]);
                      },
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildFooterSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withOpacity(0.05),
              AppTheme.accentColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.1),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              color: AppTheme.primaryColor,
              size: 32,
            ),
            const SizedBox(height: 12),
            const Text(
              'System Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ROS2 Humble • Ubuntu 22.04 • Build v1.2.3',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedFAB() {
    return ScaleTransition(
      scale: _fabAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: AppTheme.floatingShadow,
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            HapticFeedback.heavyImpact();
            _toggleStreaming();
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          splashColor: Colors.white.withOpacity(0.3),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Container(
              key: ValueKey(_isConnected),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
              ),
              child: Icon(
                _isConnected ? Icons.stop : Icons.play_arrow,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          label: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _isConnected ? 'Stop Stream' : 'Start Stream',
              key: ValueKey(_isConnected),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleStreaming() {
    setState(() {
      _isConnected = !_isConnected;
      _robotStatus = _isConnected ? "Streaming" : "Standby";
    });
  }

  void _showCardDetails(Map<String, dynamic> cardData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              cardData['icon'] as IconData,
              size: 48,
              color: cardData['color'] as Color,
            ),
            const SizedBox(height: 16),
            Text(
              cardData['label'] as String,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${cardData['status']}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Value: ${cardData['value']}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}