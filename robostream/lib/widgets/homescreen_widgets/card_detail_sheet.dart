import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:robostream/services/server.dart';

class CardDetailSheet extends StatefulWidget {
  final Map<String, dynamic> cardData;
  final SensorData? sensorData;
  final ActuatorData? actuatorData;
  final bool isConnected;
  final String serverBaseUrl;

  const CardDetailSheet({
    super.key,
    required this.cardData,
    this.sensorData,
    this.actuatorData,
    required this.isConnected,
    required this.serverBaseUrl,
  });

  @override
  State<CardDetailSheet> createState() => _CardDetailSheetState();
}

class _CardDetailSheetState extends State<CardDetailSheet> {
  int imageRefreshKey = 0;

  @override
  Widget build(BuildContext context) {
    final detailWidgets = _buildDetailWidgets();
    final statusInfo = _getStatusInfo();
    
    double initialSize = 0.5;
    if (detailWidgets.isNotEmpty) {
      if (detailWidgets.length > 5) {
        initialSize = 0.75;
      } else if (detailWidgets.length > 2) {
        initialSize = 0.65;
      } else {
        initialSize = 0.55;
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
      },
      child: Container(
        color: Colors.transparent,
        child: DraggableScrollableSheet(
            initialChildSize: initialSize,
            minChildSize: 0.3,
            maxChildSize: 0.8,
            builder: (context, scrollController) => Container(
              decoration: BoxDecoration(
                gradient: _createCommonGradient(),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: (widget.cardData['color'] as Color).withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, -15),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -8),
                  ),
                ],
                border: Border.all(
                  color: (widget.cardData['color'] as Color).withOpacity(0.08),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
                      child: Column(
                        children: [
                          _buildHeader(statusInfo),
                          if (detailWidgets.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Container(
                              width: double.infinity,
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    (widget.cardData['color'] as Color).withOpacity(0.2),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ...detailWidgets,
                          ],
                          const SizedBox(height: 20),
                        ],
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

  Widget _buildHeader(Map<String, String> statusInfo) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                widget.cardData['color'] as Color,
                (widget.cardData['color'] as Color).withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: (widget.cardData['color'] as Color).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            widget.cardData['icon'] as IconData,
            size: 28,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          widget.cardData['label'] as String,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                (widget.cardData['color'] as Color).withOpacity(0.1),
                (widget.cardData['color'] as Color).withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (widget.cardData['color'] as Color).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getStatusColor(statusInfo['status']!),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                statusInfo['status']!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(statusInfo['status']!),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.white.withOpacity(0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (widget.cardData['color'] as Color).withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Text(
            statusInfo['value']!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }

  Map<String, String> _getStatusInfo() {
    final String label = widget.cardData['label'] as String;
    String status = 'Offline';
    String value = 'N/A';
    
    if (label == 'RGB Camera') {
      final rgbCamera = widget.sensorData?.rgbCamera;
      status = rgbCamera?.status ?? 'Offline';
      value = rgbCamera != null && rgbCamera.status == 'Active' 
          ? '${rgbCamera.resolution}@${rgbCamera.fps}fps' 
          : 'N/A';
    } else if (label == 'LiDAR Sensor') {
      final lidarStatus = widget.sensorData?.lidar ?? 'Disconnected';
      status = lidarStatus;
      value = lidarStatus == 'Connected' ? '360° scan' : 'N/A';
    } else if (label == 'GPS Position') {
      final gpsData = widget.sensorData?.gps;
      status = gpsData != null ? 'Active' : 'Offline';
      value = gpsData != null ? 'Tracking' : 'N/A';
    } else if (label == 'Movement') {
      final gpsData = widget.sensorData?.gps;
      status = gpsData != null ? 'Tracking' : 'Offline';
      value = gpsData != null ? '${gpsData.speed.toStringAsFixed(1)} m/s' : 'N/A';
    } else if (label == 'IMU Sensors') {
      final imuData = widget.sensorData?.imu;
      status = imuData != null ? 'Active' : 'Offline';
      if (imuData != null) {
        final acc = imuData.accelerometer;
        final totalAcceleration = math.sqrt(acc.x * acc.x + acc.y * acc.y + acc.z * acc.z);
        value = '${totalAcceleration.toStringAsFixed(1)} m/s²';
      }
    } else if (label == 'Wheel Motors') {
      status = widget.actuatorData != null ? 'Ready' : 'Offline';
      if (widget.actuatorData != null) {
        final wheels = widget.actuatorData!;
        final avgWheelSpeed = (wheels.frontLeftWheel.speed + 
                              wheels.frontRightWheel.speed + 
                              wheels.backLeftWheel.speed + 
                              wheels.backRightWheel.speed) / 4.0;
        value = '${avgWheelSpeed.toStringAsFixed(0)} RPM';
      }
    } else if (label == 'Temperature') {
      status = widget.actuatorData != null ? 'Monitoring' : 'Offline';
      if (widget.actuatorData != null) {
        final actuators = widget.actuatorData!;
        final avgTemp = (actuators.frontLeftWheel.temperature + 
                        actuators.frontRightWheel.temperature + 
                        actuators.backLeftWheel.temperature + 
                        actuators.backRightWheel.temperature) / 4;
        value = '${avgTemp.toStringAsFixed(1)}°C';
      }
    } else if (label == 'Server Link') {
      status = widget.isConnected ? 'Online' : 'Offline';
      if (widget.isConnected && widget.sensorData?.timestamp != null) {
        final timestamp = widget.sensorData?.timestamp;
        if (timestamp != null) {
          final lastUpdate = DateTime.fromMillisecondsSinceEpoch((timestamp * 1000).toInt());
          final now = DateTime.now();
          final diff = now.difference(lastUpdate).inSeconds;
          value = diff < 60 ? '${diff}s ago' : 'Stale';
        }
      }
    }
    
    return {'status': status, 'value': value};
  }

  List<Widget> _buildDetailWidgets() {
    final String label = widget.cardData['label'] as String;
    List<Widget> detailWidgets = [];

    if (label == 'GPS Position' && widget.sensorData?.gps != null) {
      final gps = widget.sensorData?.gps;
      if (gps != null) {
        detailWidgets.addAll([
          _buildDetailRow('Latitude', '${gps.latitude.toStringAsFixed(6)}°'),
          _buildDetailRow('Longitude', '${gps.longitude.toStringAsFixed(6)}°'),
          _buildDetailRow('Altitude', '${gps.altitude.toStringAsFixed(1)} m'),
          _buildDetailRow('Speed', '${gps.speed.toStringAsFixed(2)} m/s'),
        ]);
      }
    } else if (label == 'Wheel Motors' && widget.actuatorData != null) {
      final actuators = widget.actuatorData!;
      detailWidgets.addAll([
        _buildDetailRow('Front Left', '${actuators.frontLeftWheel.speed} RPM • ${actuators.frontLeftWheel.temperature.toStringAsFixed(1)}°C'),
        _buildDetailRow('Front Right', '${actuators.frontRightWheel.speed} RPM • ${actuators.frontRightWheel.temperature.toStringAsFixed(1)}°C'),
        _buildDetailRow('Back Left', '${actuators.backLeftWheel.speed} RPM • ${actuators.backLeftWheel.temperature.toStringAsFixed(1)}°C'),
        _buildDetailRow('Back Right', '${actuators.backRightWheel.speed} RPM • ${actuators.backRightWheel.temperature.toStringAsFixed(1)}°C'),
        const SizedBox(height: 8),
        _buildDetailRow('Avg Power', '${((actuators.frontLeftWheel.consumption + actuators.frontRightWheel.consumption + actuators.backLeftWheel.consumption + actuators.backRightWheel.consumption) / 4).toStringAsFixed(2)} A'),
        _buildDetailRow('Avg Voltage', '${((actuators.frontLeftWheel.voltage + actuators.frontRightWheel.voltage + actuators.backLeftWheel.voltage + actuators.backRightWheel.voltage) / 4).toStringAsFixed(1)} V'),
      ]);
    } else if (label == 'IMU Sensors' && widget.sensorData?.imu != null) {
      final imu = widget.sensorData?.imu;
      if (imu != null) {
        detailWidgets.addAll([
          _buildSectionTitle('Accelerometer (m/s²)', Icons.speed_rounded),
          const SizedBox(height: 8),
          _buildDetailRow('X-axis', '${imu.accelerometer.x.toStringAsFixed(2)}'),
          _buildDetailRow('Y-axis', '${imu.accelerometer.y.toStringAsFixed(2)}'),
          _buildDetailRow('Z-axis', '${imu.accelerometer.z.toStringAsFixed(2)}'),
          const SizedBox(height: 16),
          _buildSectionTitle('Gyroscope (rad/s)', Icons.rotate_right_rounded),
          const SizedBox(height: 8),
          _buildDetailRow('X-axis', '${imu.gyroscope.x.toStringAsFixed(3)}'),
          _buildDetailRow('Y-axis', '${imu.gyroscope.y.toStringAsFixed(3)}'),
          _buildDetailRow('Z-axis', '${imu.gyroscope.z.toStringAsFixed(3)}'),
          const SizedBox(height: 16),
          _buildSectionTitle('Magnetometer (µT)', Icons.explore_rounded),
          const SizedBox(height: 8),
          _buildDetailRow('X-axis', '${imu.magnetometer.x.toStringAsFixed(2)}'),
          _buildDetailRow('Y-axis', '${imu.magnetometer.y.toStringAsFixed(2)}'),
          _buildDetailRow('Z-axis', '${imu.magnetometer.z.toStringAsFixed(2)}'),
        ]);
      }
    } else if (label == 'Server Link') {
      final timestamp = widget.sensorData?.timestamp;
      detailWidgets.addAll([
        _buildDetailRow('Status', widget.isConnected ? 'Connected' : 'Disconnected'),
        _buildDetailRow('Server URL', widget.serverBaseUrl),
        _buildDetailRow('Update Interval', '2s'),
        if (timestamp != null) ...[
          _buildDetailRow('Last Update', 
            DateTime.fromMillisecondsSinceEpoch((timestamp * 1000).toInt())
              .toString().substring(11, 19)),
          _buildDetailRow('Data Age', 
            '${DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch((timestamp * 1000).toInt())).inSeconds}s'),
        ],
      ]);
    } else if (label == 'Temperature' && widget.actuatorData != null) {
      final actuators = widget.actuatorData!;
      detailWidgets.addAll([
        _buildDetailRow('Front Left Motor', '${actuators.frontLeftWheel.temperature.toStringAsFixed(1)}°C'),
        _buildDetailRow('Front Right Motor', '${actuators.frontRightWheel.temperature.toStringAsFixed(1)}°C'),
        _buildDetailRow('Back Left Motor', '${actuators.backLeftWheel.temperature.toStringAsFixed(1)}°C'),
        _buildDetailRow('Back Right Motor', '${actuators.backRightWheel.temperature.toStringAsFixed(1)}°C'),
        const SizedBox(height: 8),
        _buildDetailRow('Average', '${((actuators.frontLeftWheel.temperature + actuators.frontRightWheel.temperature + actuators.backLeftWheel.temperature + actuators.backRightWheel.temperature) / 4).toStringAsFixed(1)}°C'),
        _buildDetailRow('Max Safe Temp', '80.0°C'),
      ]);
    } else if (label == 'RGB Camera' && widget.sensorData?.rgbCamera != null) {
      final rgbCamera = widget.sensorData?.rgbCamera;
      if (rgbCamera != null) {
        detailWidgets.addAll([
          _buildCameraPreview(),
          const SizedBox(height: 12),
          // Add refresh button for camera
          _buildRefreshButton(),
          const SizedBox(height: 12),
          _buildDetailRow('Camera ID', rgbCamera.cameraId),
          _buildDetailRow('Resolution', rgbCamera.resolution),
          _buildDetailRow('Frame Rate', '${rgbCamera.fps} FPS'),
        ]);
      }
    }

    return detailWidgets;
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: _createCommonGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withOpacity(0.1),
            const Color(0xFF8B5CF6).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withOpacity(0.15),
                  const Color(0xFF8B5CF6).withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF6366F1),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    final imageUrl = '${widget.serverBaseUrl}/rgb-camera/image';
    
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: _createCommonGradient(),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFF59E0B).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          '$imageUrl?refresh=$imageRefreshKey',
          key: ValueKey(imageRefreshKey),
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              decoration: BoxDecoration(
                gradient: _createCommonGradient(
                  colors: [
                    const Color(0xFFF1F5F9),
                    const Color(0xFFF8FAFC),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: const Color(0xFF6366F1),
                      strokeWidth: 3,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading camera feed...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    if (loadingProgress.expectedTotalBytes != null)
                      Text(
                        '${(loadingProgress.cumulativeBytesLoaded / 1024).toStringAsFixed(1)} KB / ${(loadingProgress.expectedTotalBytes! / 1024).toStringAsFixed(1)} KB',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('Error loading camera image: $error');
            return Container(
              decoration: BoxDecoration(
                gradient: _createCommonGradient(
                  colors: [
                    const Color(0xFFF1F5F9),
                    const Color(0xFFF8FAFC),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Camera feed unavailable',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check server connection',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          imageRefreshKey++;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            );
          },
          headers: {
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
          },
        ),
      ),
    );
  }

  // Helper function to determine if a status is positive
  bool _isPositiveStatus(String status) {
    return status == 'Online' || 
           status == 'Active' || 
           status == 'Connected' ||
           status == 'Tracking' ||
           status == 'Ready' ||
           status == 'Monitoring';
  }

  // Helper function to get status color
  Color _getStatusColor(String status) {
    return _isPositiveStatus(status) 
        ? const Color(0xFF10B981) 
        : const Color(0xFFEF4444);
  }

  // Helper function to create common gradient
  LinearGradient _createCommonGradient({
    List<Color>? colors,
    AlignmentGeometry? begin,
    AlignmentGeometry? end,
  }) {
    return LinearGradient(
      colors: colors ?? [
        const Color(0xFFF8FAFC),
        const Color(0xFFF1F5F9),
      ],
      begin: begin ?? Alignment.topCenter,
      end: end ?? Alignment.bottomCenter,
    );
  }

  // Helper function to create refresh button
  Widget _buildRefreshButton() {
    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          imageRefreshKey++;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      icon: const Icon(Icons.refresh, size: 16),
      label: const Text('Refresh Image', style: TextStyle(fontSize: 12)),
    );
  }
}
