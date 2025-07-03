import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:robostream/assets/styles/app_styles.dart';

class CustomCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final CustomCardStyle cardStyle;
  final bool isInteractive;
  final Color? customColor;

  const CustomCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.cardStyle = CustomCardStyle.standard,
    this.isInteractive = false,
    this.customColor,
  });

  CustomCard.info({
    super.key,
    required IconData icon,
    required String title,
    required String subtitle,
    this.onTap,
    this.padding,
    this.margin,
    this.isInteractive = false,
    this.customColor,
  })  : child = _InfoCardContent(
          icon: icon,
          title: title,
          subtitle: subtitle,
          color: customColor ?? AppStyles.primaryColor,
        ),
        cardStyle = CustomCardStyle.info;

  CustomCard.stat({
    super.key,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    this.onTap,
    this.padding,
    this.margin,
    this.isInteractive = false,
  })  : child = _StatCardContent(
          icon: icon,
          label: label,
          value: value,
          color: color,
        ),
        cardStyle = CustomCardStyle.stat,
        customColor = color;
  CustomCard.config({
    super.key,
    required IconData icon,
    required String title,
    required String description,
    this.onTap,
    this.padding,
    this.margin,
    this.isInteractive = true,
    this.customColor,
  })  : child = _ConfigCardContent(
          icon: icon,
          title: title,
          description: description,
          color: customColor ?? AppStyles.secondaryColor,
        ),
        cardStyle = CustomCardStyle.config;
  CustomCard.status({
    super.key,
    required IconData icon,
    required String title,
    required String status,
    required bool isActive,
    this.onTap,
    this.padding,
    this.margin,
    this.isInteractive = false,
  })  : child = _StatusCardContent(
          icon: icon,
          title: title,
          status: status,
          isActive: isActive,
        ),
        cardStyle = CustomCardStyle.status,
        customColor = null;

  CustomCard.simple({
    super.key,
    required IconData icon,
    required String name,
    required Color color,
    this.onTap,
    this.padding,
    this.margin,
    this.isInteractive = true,
  })  : child = _SimpleCardContent(
          icon: icon,
          name: name,
          color: color,
        ),
        cardStyle = CustomCardStyle.simple,
        customColor = color;

  @override
  State<CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard>
    with SingleTickerProviderStateMixin {
  static const Duration _animationDuration = Duration(milliseconds: 200);
  static const double _pressedScale = 0.98;
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: _pressedScale,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.isInteractive && widget.onTap != null) {
      setState(() => _isPressed = true);
      HapticFeedback.lightImpact();
      _animationController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.isInteractive) {
      setState(() => _isPressed = false);
      _animationController.reverse();
      widget.onTap?.call();
    }
  }

  void _onTapCancel() {
    if (widget.isInteractive) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  void _onHover(bool hover) {
    if (widget.isInteractive) {
      setState(() => _isHovered = hover);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: widget.margin ?? _getDefaultMargin(),
              child: AnimatedContainer(
                duration: AppStyles.mediumDuration,
                curve: AppStyles.primaryCurve,
                decoration: _getCardDecoration(),
                child: Material(
                  color: Colors.transparent,
                  child: widget.isInteractive && widget.onTap != null
                      ? InkWell(
                          borderRadius: BorderRadius.circular(_getBorderRadius()),
                          onTapDown: _onTapDown,
                          onTapUp: _onTapUp,
                          onTapCancel: _onTapCancel,
                          splashColor: _getSplashColor(),
                          highlightColor: _getHighlightColor(),
                          child: _buildCardContent(),
                        )
                      : _buildCardContent(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardContent() {
    return Container(
      padding: widget.padding ?? _getDefaultPadding(),
      child: widget.child,
    );
  }

  double _getBorderRadius() {
    switch (widget.cardStyle) {
      case CustomCardStyle.standard:
        return 16.0;
      case CustomCardStyle.info:
        return 20.0;
      case CustomCardStyle.stat:
        return 24.0;
      case CustomCardStyle.config:
        return 18.0;
      case CustomCardStyle.status:
        return 16.0;
      case CustomCardStyle.simple:
        return 12.0;
    }
  }

  EdgeInsets _getDefaultPadding() {
    switch (widget.cardStyle) {
      case CustomCardStyle.standard:
        return const EdgeInsets.all(16);
      case CustomCardStyle.info:
        return const EdgeInsets.all(20);
      case CustomCardStyle.stat:
        return const EdgeInsets.all(24);
      case CustomCardStyle.config:
        return const EdgeInsets.all(18);
      case CustomCardStyle.status:
        return const EdgeInsets.all(16);
      case CustomCardStyle.simple:
        return const EdgeInsets.all(12);
    }
  }

  EdgeInsets _getDefaultMargin() {
    switch (widget.cardStyle) {
      case CustomCardStyle.standard:
      case CustomCardStyle.info:
      case CustomCardStyle.config:
      case CustomCardStyle.status:
        return const EdgeInsets.only(bottom: 16);
      case CustomCardStyle.stat:
        return const EdgeInsets.only(bottom: 12);
      case CustomCardStyle.simple:
        return const EdgeInsets.only(bottom: 8);
    }
  }
  BoxDecoration _getCardDecoration() {
    List<BoxShadow> shadows;
    
    if (_isHovered && widget.isInteractive) {
      shadows = AppStyles.floatingShadow;
    } else if (_isPressed && widget.isInteractive) {
      shadows = AppStyles.cardShadow;
    } else {
      shadows = _getCardShadows();
    }

    switch (widget.cardStyle) {
      case CustomCardStyle.standard:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          color: Colors.white,
          boxShadow: shadows,
        );
      
      case CustomCardStyle.info:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: shadows,
        );
      
      case CustomCardStyle.stat:
        final color = widget.customColor ?? AppStyles.primaryColor;
        return BoxDecoration(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: color.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: shadows,
        );
      
      case CustomCardStyle.config:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          gradient: AppStyles.cardGradient,
          boxShadow: shadows,
        );
      
      case CustomCardStyle.status:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          color: Colors.white,
          boxShadow: shadows,
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
        );
      case CustomCardStyle.simple:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          color: Colors.white,
          boxShadow: shadows,
        );
    }
  }

  List<BoxShadow> _getCardShadows() {
    switch (widget.cardStyle) {
      case CustomCardStyle.standard:
      case CustomCardStyle.info:
      case CustomCardStyle.config:
      case CustomCardStyle.status:
        return AppStyles.cardShadow;
      case CustomCardStyle.stat:
        return AppStyles.elevatedShadow;
      case CustomCardStyle.simple:
        return AppStyles.cardShadow;
    }
  }

  Color _getSplashColor() {
    final color = widget.customColor ?? AppStyles.primaryColor;
    return color.withOpacity(0.1);
  }

  Color _getHighlightColor() {
    final color = widget.customColor ?? AppStyles.primaryColor;
    return color.withOpacity(0.05);
  }
}

class _InfoCardContent extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _InfoCardContent({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCardContent extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCardContent({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 12),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ConfigCardContent extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _ConfigCardContent({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            height: 1.4,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _StatusCardContent extends StatelessWidget {
  final IconData icon;
  final String title;
  final String status;
  final bool isActive;

  const _StatusCardContent({
    required this.icon,
    required this.title,
    required this.status,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isActive ? AppStyles.successColor : AppStyles.errorColor;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: statusColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.5),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SimpleCardContent extends StatelessWidget {
  final IconData icon;
  final String name;
  final Color color;

  const _SimpleCardContent({
    required this.icon,
    required this.name,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 32,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

enum CustomCardStyle {
  standard,
  info,
  stat,
  config,
  status,
  simple,
}
