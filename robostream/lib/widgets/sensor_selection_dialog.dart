import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/lg_service.dart';

class SensorSelectionDialog extends StatefulWidget {
  final Function(List<String>) onSelectionConfirmed;

  const SensorSelectionDialog({
    Key? key,
    required this.onSelectionConfirmed,
  }) : super(key: key);

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
      icon: Icons.location_on,
      color: const Color(0xFF10B981),
    ),
    SensorOption(
      id: 'IMU Sensors',
      name: 'IMU Sensors',
      icon: Icons.sensors,
      color: const Color(0xFF8B5CF6),
    ),
    SensorOption(
      id: 'RGB Camera',
      name: 'RGB Camera',
      icon: Icons.camera_alt,
      color: const Color(0xFFF59E0B),
    ),
    SensorOption(
      id: 'LiDAR Status',
      name: 'LiDAR Status',
      icon: Icons.radar,
      color: const Color(0xFFEF4444),
    ),
    SensorOption(
      id: 'Temperature',
      name: 'Motor Temperature',
      icon: Icons.thermostat,
      color: const Color(0xFFEC4899),
    ),
    SensorOption(
      id: 'Wheel Motors',
      name: 'Wheel Motors',
      icon: Icons.settings,
      color: const Color(0xFF06B6D4),
    ),
    SensorOption(
      id: 'Server Link',
      name: 'Server Connection',
      icon: Icons.cloud,
      color: const Color(0xFF84CC16),
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
      _sensorOptions[index].isSelected = !_sensorOptions[index].isSelected;
    });
  }

  void _confirmSelection() {
    final selectedSensors = _sensorOptions
        .where((sensor) => sensor.isSelected)
        .map((sensor) => sensor.id)
        .toList();

    if (selectedSensors.isEmpty) {
      // Mostrar mensaje si no hay sensores seleccionados
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one sensor'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
    widget.onSelectionConfirmed(selectedSensors);
  }

  void _selectAll() {
    HapticFeedback.lightImpact();
    setState(() {
      for (var sensor in _sensorOptions) {
        sensor.isSelected = true;
      }
    });
  }

  void _deselectAll() {
    HapticFeedback.lightImpact();
    setState(() {
      for (var sensor in _sensorOptions) {
        sensor.isSelected = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxDialogHeight = screenHeight * 0.8; // 80% de la altura de la pantalla
    
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
                constraints: BoxConstraints(
                  maxWidth: 400,
                  maxHeight: maxDialogHeight,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: _buildSensorList(),
                    ),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.tune,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Sensors',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Choose which sensors to display on Liquid Galaxy',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorList() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botones de selección rápida
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectAll,
                  icon: const Icon(Icons.select_all, size: 18),
                  label: const Text('Select All'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                    side: const BorderSide(color: Color(0xFF6366F1)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _deselectAll,
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear All'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    side: BorderSide(color: Colors.grey[400]!),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Lista de sensores con scroll independiente
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 300, // Altura máxima para la lista de sensores
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _sensorOptions.length,
              itemBuilder: (context, index) {
                return _buildSensorItem(_sensorOptions[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorItem(SensorOption sensor, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _toggleSensor(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: sensor.isSelected
                  ? sensor.color.withOpacity(0.1)
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: sensor.isSelected
                    ? sensor.color
                    : Colors.grey[300]!,
                width: sensor.isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: sensor.isSelected
                        ? sensor.color
                        : Colors.grey[400],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    sensor.icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    sensor.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: sensor.isSelected
                          ? sensor.color
                          : Colors.grey[700],
                    ),
                  ),
                ),
                AnimatedScale(
                  scale: sensor.isSelected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: sensor.color,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
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

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _confirmSelection,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.rocket_launch, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Start Streaming',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
