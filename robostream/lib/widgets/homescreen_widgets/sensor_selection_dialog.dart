import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SensorOption {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  bool isSelected;

  SensorOption({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isSelected = false,
  });
}

class SensorSelectionDialog extends StatefulWidget {
  final Function(List<String>) onSelectionConfirmed;

  const SensorSelectionDialog({
    super.key,
    required this.onSelectionConfirmed,
  });

  @override
  State<SensorSelectionDialog> createState() => _SensorSelectionDialogState();
}

class _SensorSelectionDialogState extends State<SensorSelectionDialog>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  List<SensorOption> _sensorOptions = [
    SensorOption(
      id: 'GPS Position',
      name: 'GPS Position',
      icon: Icons.location_on_outlined,
      color: const Color(0xFF06B6D4),
      isSelected: true, 
    ),
    SensorOption(
      id: 'IMU Sensors',
      name: 'IMU Sensors',
      icon: Icons.settings_input_component_outlined,
      color: const Color(0xFFF59E0B),
    ),
    SensorOption(
      id: 'LiDAR Status',
      name: 'LiDAR Sensor',
      icon: Icons.radar_outlined,
      color: const Color(0xFF8B5CF6),
    ),
    SensorOption(
      id: 'Temperature',
      name: 'Temperature',
      icon: Icons.thermostat_outlined,
      color: const Color(0xFFEF4444),
    ),
    SensorOption(
      id: 'Wheel Motors',
      name: 'Wheel Motors',
      icon: Icons.precision_manufacturing_outlined,
      color: const Color(0xFF8B5CF6),
    ),
    SensorOption(
      id: 'Server Link',
      name: 'Server Link',
      icon: Icons.cloud_outlined,
      color: const Color(0xFF10B981),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleSensor(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      // Allow multiple selection for checkboxes
      _sensorOptions[index].isSelected = !_sensorOptions[index].isSelected;
    });
  }

  void _confirmSelection() {
    final selectedSensors = _sensorOptions
        .where((sensor) => sensor.isSelected)
        .map((sensor) => sensor.id)
        .toList();

    // If no sensors selected, select GPS Position by default
    if (selectedSensors.isEmpty) {
      selectedSensors.add('GPS Position');
    }

    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
    widget.onSelectionConfirmed(selectedSensors);
  }



  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 500,
                  maxHeight: 750,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF8FAFC),
                      Color(0xFFF1F5F9),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFF6366F1).withOpacity(0.08),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModernHeader(),
                    Expanded(
                      child: _buildModernSensorList(),
                    ),
                    _buildModernActionButtons(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.all(28),
      child: Column(
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
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.sensors_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Select a Sensor',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose sensors to stream to Liquid Galaxy',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }



  Widget _buildModernSensorList() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        itemCount: _sensorOptions.length,
        itemBuilder: (context, index) {
          return _buildModernSensorCard(_sensorOptions[index], index);
        },
      ),
    );
  }

  Widget _buildModernSensorCard(SensorOption sensor, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: sensor.isSelected
              ? [
                  sensor.color.withOpacity(0.1),
                  sensor.color.withOpacity(0.05),
                ]
              : [
                  Colors.white,
                  Colors.white.withOpacity(0.95),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: sensor.isSelected
                ? sensor.color.withOpacity(0.15)
                : Colors.black.withOpacity(0.04),
            blurRadius: sensor.isSelected ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: sensor.isSelected
              ? sensor.color.withOpacity(0.3)
              : Colors.grey.withOpacity(0.1),
          width: sensor.isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _toggleSensor(index),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        sensor.color.withOpacity(0.1),
                        sensor.color.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(
                    sensor.icon,
                    color: sensor.color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sensor.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getSensorDescription(sensor.id),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6), // Square corners for checkbox
                    color: sensor.isSelected ? sensor.color : Colors.transparent,
                    border: Border.all(
                      color: sensor.isSelected ? sensor.color : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: sensor.isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getSensorDescription(String sensorId) {
    switch (sensorId) {
      case 'GPS Position':
        return 'Location coordinates and altitude';
      case 'IMU Sensors':
        return 'Accelerometer, gyroscope & magnetometer';
      case 'RGB Camera':
        return 'Real-time camera feed';
      case 'LiDAR Status':
        return '360° laser scanning status';
      case 'Temperature':
        return 'Motor temperature monitoring';
      case 'Wheel Motors':
        return 'Motor speed and power consumption';
      case 'Server Link':
        return 'Robot server connection status';
      default:
        return 'Sensor data streaming';
    }
  }

  Widget _buildModernActionButtons() {
    final selectedSensors = _sensorOptions.where((sensor) => sensor.isSelected).toList();
    final selectedCount = selectedSensors.length;
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (selectedCount > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: selectedCount == 1 
                    ? selectedSensors.first.color.withOpacity(0.1)
                    : const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selectedCount == 1 
                      ? selectedSensors.first.color.withOpacity(0.2)
                      : const Color(0xFF6366F1).withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selectedCount == 1 
                            ? selectedSensors.first.icon
                            : Icons.sensors,
                        color: selectedCount == 1 
                            ? selectedSensors.first.color
                            : const Color(0xFF6366F1),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        selectedCount == 1 
                            ? '${selectedSensors.first.name} selected'
                            : '$selectedCount sensors selected',
                        style: TextStyle(
                          color: selectedCount == 1 
                              ? selectedSensors.first.color
                              : const Color(0xFF6366F1),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (selectedCount > 1) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: selectedSensors.map((sensor) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: sensor.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: sensor.color.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          sensor.name,
                          style: TextStyle(
                            color: sensor.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: const Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _confirmSelection,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.rocket_launch,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Start Streaming',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
