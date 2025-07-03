import 'package:flutter/material.dart';
import 'package:robostream/services/server.dart';
import 'dart:async';
import 'dart:convert';

class RGBCameraScreen extends StatefulWidget {
  const RGBCameraScreen({super.key});

  @override
  State<RGBCameraScreen> createState() => _RGBCameraScreenState();
}

class _RGBCameraScreenState extends State<RGBCameraScreen> {
  static const Duration _autoRefreshInterval = Duration(seconds: 5);
  static const Color _primaryColor = Color(0xFF6366F1);
  static const Color _backgroundColor = Color(0xFFF8FAFC);
  static const Color _textColor = Color(0xFF1E293B);
  static const Color _subtitleColor = Color(0xFF64748B);
  
  final RobotServerService _serverService = RobotServerService();
  RGBCameraData? _cameraData;
  Map<String, dynamic>? _imageMetadata;
  String? _imageBase64;
  bool _isLoading = true;
  bool _useDirectUrl = false;
  Timer? _refreshTimer;
  String? _lastError;
  
  @override
  void initState() {
    super.initState();
    _loadCameraData();
    _startAutoRefresh();
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
  
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(_autoRefreshInterval, (timer) {
      _loadCameraData();
    });
  }
  
  Future<void> _loadCameraData() async {
    try {
      final cameraData = await _serverService.getRGBCameraData();
      
      if (cameraData != null && mounted) {
        setState(() {
          _cameraData = cameraData;
          _isLoading = false;
          _lastError = null;
        });
        
        try {
          final imageData = await _serverService.getRGBCameraImageData();
          if (imageData != null && mounted) {
            setState(() {
              _imageMetadata = imageData;
              _imageBase64 = imageData['image_data'];
              _useDirectUrl = false;
            });
            
            if (_imageBase64 != null && _imageBase64!.isNotEmpty) {
              try {
                base64Decode(_imageBase64!);
              } catch (e) {
                setState(() {
                  _useDirectUrl = true;
                  _imageBase64 = null;
                });
              }
            }
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _useDirectUrl = true;
              _lastError = 'Error loading image data: $e';
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _lastError = 'No camera data available';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _lastError = 'Connection error: $e';
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'RGB Camera',
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: _subtitleColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: _primaryColor),
            onPressed: _loadCameraData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              ),
            )
          : _cameraData == null
              ? _buildErrorState()
              : _buildCameraContent(),
    );
  }
  
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Camera not available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _lastError ?? 'Check server connection',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadCameraData,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCameraContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageViewer(),
          const SizedBox(height: 24),
          _buildCameraInfo(),
          const SizedBox(height: 24),
          _buildTimingInfo(),
          const SizedBox(height: 24),
          _buildImageMetadata(),
        ],
      ),
    );
  }
  
  Widget _buildImageViewer() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFF59E0B).withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF59E0B).withOpacity(0.1),
                        const Color(0xFFF59E0B).withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Color(0xFFF59E0B),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Camera View',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Real-time RGB camera feed',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _cameraData?.status == 'Active' 
                          ? [
                              const Color(0xFF10B981).withOpacity(0.15),
                              const Color(0xFF10B981).withOpacity(0.08),
                            ]
                          : [
                              Colors.grey.withOpacity(0.15),
                              Colors.grey.withOpacity(0.08),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _cameraData?.status == 'Active' 
                          ? const Color(0xFF10B981).withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
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
                          shape: BoxShape.circle,
                          color: _cameraData?.status == 'Active' 
                              ? const Color(0xFF10B981)
                              : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _cameraData?.status ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _cameraData?.status == 'Active' 
                              ? const Color(0xFF10B981)
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF8FAFC),
                  const Color(0xFFF1F5F9),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withOpacity(0.08),
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
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _buildImageWidget(),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildImageWidget() {
    if (!_useDirectUrl && _imageBase64 != null && _imageBase64!.isNotEmpty) {
      try {
        final imageBytes = base64Decode(_imageBase64!);
        return Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildImageFromUrl();
          },
        );
      } catch (e) {
        return _buildImageFromUrl();
      }
    }
    
    return _buildImageFromUrl();
  }
  
  Widget _buildImageFromUrl() {
    final imageUrl = _serverService.getRGBCameraImageUrl();
    
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[100],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Loading image...',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[100],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.image_not_supported,
                  size: 48,
                  color: Colors.grey,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Image not available',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                if (_lastError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _lastError!,
                    style: TextStyle(
                      color: Colors.red[400],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        );
      },
      headers: {
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      },
    );
  }
  
  Widget _buildCameraInfo() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF8B5CF6).withOpacity(0.08),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF8B5CF6).withOpacity(0.1),
                      const Color(0xFF8B5CF6).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF8B5CF6),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Camera Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Detailed camera specifications',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildModernInfoRow('Camera ID', _cameraData?.cameraId ?? 'Unknown', Icons.videocam_rounded),
          const SizedBox(height: 16),
          _buildModernInfoRow('Resolution', _cameraData?.resolution ?? 'Unknown', Icons.high_quality_rounded),
          const SizedBox(height: 16),
          _buildModernInfoRow('Frame Rate', '${_cameraData?.fps ?? 0} FPS', Icons.speed_rounded),
          const SizedBox(height: 16),
          _buildModernInfoRow('Status', _cameraData?.status ?? 'Unknown', Icons.power_settings_new_rounded),
          const SizedBox(height: 16),
          _buildModernInfoRow('Current Image', _cameraData?.currentImage ?? 'None', Icons.image_rounded),
          const SizedBox(height: 16),
          _buildModernInfoRow('Images Available', '${_cameraData?.imagesAvailable ?? 0}', Icons.photo_library_rounded),
          const SizedBox(height: 16),
          _buildModernInfoRow('Rotation Interval', '${_cameraData?.rotationInterval ?? 0}s', Icons.rotate_right_rounded),
        ],
      ),
    );
  }
  
  Widget _buildTimingInfo() {
    final timing = _imageMetadata?['timing'] as Map<String, dynamic>?;
    if (timing == null) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF06B6D4).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF06B6D4).withOpacity(0.08),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF06B6D4).withOpacity(0.1),
                      const Color(0xFF06B6D4).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  color: Color(0xFF06B6D4),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Timing Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Rotation timing and intervals',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildModernTimingRow('Time Since Last Rotation', '${timing['time_since_last_rotation']?.toStringAsFixed(1) ?? 'N/A'}s', Icons.history_rounded),
          const SizedBox(height: 16),
          _buildModernTimingRow('Time Until Next Rotation', '${timing['time_until_next_rotation']?.toStringAsFixed(1) ?? 'N/A'}s', Icons.schedule_rounded),
          const SizedBox(height: 16),
          _buildModernTimingRow('Rotation Interval', '${timing['rotation_interval_seconds']?.toStringAsFixed(0) ?? 'N/A'}s', Icons.sync_rounded),
        ],
      ),
    );
  }
  
  Widget _buildImageMetadata() {
    final metadata = _imageMetadata?['image_metadata'] as Map<String, dynamic>?;
    if (metadata == null) return const SizedBox.shrink();
    
    final allImages = metadata['all_images'] as List<dynamic>?;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.08),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF10B981).withOpacity(0.1),
                      const Color(0xFF10B981).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.dataset_rounded,
                  color: Color(0xFF10B981),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Image Metadata',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Image collection information',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildModernMetadataRow('Current Index', '${metadata['current_index'] ?? 'N/A'}', Icons.bookmark_rounded),
          const SizedBox(height: 16),
          _buildModernMetadataRow('Total Images', '${metadata['total_images'] ?? 'N/A'}', Icons.collections_rounded),
          const SizedBox(height: 16),
          _buildModernMetadataRow('Current Filename', metadata['current_filename'] ?? 'N/A', Icons.insert_drive_file_rounded),
          if (allImages != null && allImages.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFF1F5F9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.08),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF10B981).withOpacity(0.1),
                              const Color(0xFF10B981).withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(
                          Icons.photo_library_rounded,
                          color: Color(0xFF10B981),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Available Images',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...allImages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final imageName = entry.value as String;
                    final isCurrent = index == (metadata['current_index'] ?? -1);
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isCurrent 
                              ? [
                                  const Color(0xFF10B981).withOpacity(0.15),
                                  const Color(0xFF10B981).withOpacity(0.08),
                                ]
                              : [
                                  Colors.white.withOpacity(0.8),
                                  Colors.white.withOpacity(0.6),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCurrent 
                              ? const Color(0xFF10B981).withOpacity(0.3)
                              : Colors.grey.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCurrent ? const Color(0xFF10B981) : Colors.transparent,
                              border: Border.all(
                                color: isCurrent ? const Color(0xFF10B981) : Colors.grey.shade400,
                                width: 2,
                              ),
                            ),
                            child: isCurrent
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 14,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              imageName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                                color: isCurrent ? const Color(0xFF10B981) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF10B981).withOpacity(0.15),
                                    const Color(0xFF10B981).withOpacity(0.08),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF10B981).withOpacity(0.2),
                                ),
                              ),
                              child: const Text(
                                'Current',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernMetadataRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF8FAFC),
            const Color(0xFFF1F5F9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF10B981).withOpacity(0.1),
                  const Color(0xFF10B981).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF10B981),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF8FAFC),
            const Color(0xFFF1F5F9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8B5CF6).withOpacity(0.1),
                  const Color(0xFF8B5CF6).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF8B5CF6),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTimingRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF8FAFC),
            const Color(0xFFF1F5F9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF06B6D4).withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF06B6D4).withOpacity(0.1),
                  const Color(0xFF06B6D4).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF06B6D4),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
