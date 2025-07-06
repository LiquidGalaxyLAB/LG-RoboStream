import 'package:flutter/material.dart';
import 'package:robostream/assets/styles/app_styles.dart';

class SystemInfoCard extends StatelessWidget {
  final bool isConnected;
  final String rosVersion;
  final String operatingSystem;
  final String buildVersion;

  const SystemInfoCard({
    super.key,
    required this.isConnected,
    this.rosVersion = 'ROS2 Humble',
    this.operatingSystem = 'Ubuntu 22.04',
    this.buildVersion = 'v1.2.3',
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      decoration: _cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildSystemDetailsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppStyles.primaryColor.withOpacity(0.2),
                AppStyles.secondaryColor.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.memory,
            color: AppStyles.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'System Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Text(
                'Robot Operating System Details',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSystemDetailsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SystemDetailCard(
                label: 'ROS Version',
                value: rosVersion,
                icon: Icons.settings_outlined,
                color: AppStyles.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SystemDetailCard(
                label: 'OS',
                value: operatingSystem,
                icon: Icons.computer_outlined,
                color: AppStyles.secondaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SystemDetailCard(
                label: 'Build',
                value: buildVersion,
                icon: Icons.build_outlined,
                color: AppStyles.accentColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SystemDetailCard(
                label: 'Status',
                value: isConnected ? 'Online' : 'Offline',
                icon: isConnected ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                color: isConnected ? AppStyles.successColor : AppStyles.errorColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
    gradient: LinearGradient(
      colors: [
        AppStyles.primaryColor.withOpacity(0.05),
        AppStyles.secondaryColor.withOpacity(0.03),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: AppStyles.primaryColor.withOpacity(0.1),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: AppStyles.primaryColor.withOpacity(0.1),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

class _SystemDetailCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SystemDetailCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}
