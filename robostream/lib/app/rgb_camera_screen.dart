import 'package:flutter/material.dart';
import 'package:robostream/services/server.dart';
import 'dart:async';
import 'dart:convert';

final GlobalKey<_RGBCameraScreenState> rgbCameraScreenKey = GlobalKey<_RGBCameraScreenState>();

class RGBCameraScreen extends StatefulWidget {
  const RGBCameraScreen({Key? key}) : super(key: key);

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
        
        // Intentar cargar metadata de imagen
        await _loadImageMetadata();
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

  Future<void> loadCameraData() async {
    await _loadCameraData();
  }

  Future<void> _loadImageMetadata() async {
    try {
      final imageData = await _serverService.getRGBCameraImageData();
      if (imageData != null && mounted) {
        setState(() {
          _imageMetadata = imageData;
          _imageBase64 = imageData['image_data'];
          _useDirectUrl = !_isValidBase64(_imageBase64);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _useDirectUrl = true;
          _lastError = 'Error loading image data: $e';
        });
      }
    }
  }

  bool _isValidBase64(String? base64String) {
    if (base64String == null || base64String.isEmpty) return false;
    try {
      base64Decode(base64String);
      return true;
    } catch (e) {
      return false;
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
      return _buildBase64Image();
    }
    return _buildNetworkImage();
  }

  Widget _buildBase64Image() {
    try {
      final imageBytes = base64Decode(_imageBase64!);
      return Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildNetworkImage(),
      );
    } catch (e) {
      return _buildNetworkImage();
    }
  }

  Widget _buildNetworkImage() {
    final imageUrl = _serverService.getRGBCameraImageUrl();
    
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildLoadingWidget(loadingProgress);
      },
      errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      headers: {
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      },
    );
  }

  Widget _buildLoadingWidget(ImageChunkEvent loadingProgress) {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Loading image...',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            const Text(
              'Image not available',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            if (_lastError != null) ...[
              const SizedBox(height: 4),
              Text(
                _lastError!,
                style: TextStyle(color: Colors.red[400], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildCameraInfo() {
    const Color themeColor = Color(0xFF8B5CF6);
    
    return _buildThemeContainer(
      themeColor,
      'Camera Information',
      'Detailed camera specifications',
      Icons.info_outline_rounded,
      Column(
        children: [
          _buildModernInfoRow('Camera ID', _cameraData?.cameraId ?? 'Unknown', Icons.videocam_rounded, themeColor),
          const SizedBox(height: 16),
          _buildModernInfoRow('Resolution', _cameraData?.resolution ?? 'Unknown', Icons.high_quality_rounded, themeColor),
          const SizedBox(height: 16),
          _buildModernInfoRow('Frame Rate', '${_cameraData?.fps ?? 0} FPS', Icons.speed_rounded, themeColor),
          const SizedBox(height: 16),
          _buildModernInfoRow('Status', _cameraData?.status ?? 'Unknown', Icons.power_settings_new_rounded, themeColor),
          const SizedBox(height: 16),
          _buildModernInfoRow('Current Image', _cameraData?.currentImage ?? 'None', Icons.image_rounded, themeColor),
          const SizedBox(height: 16),
          _buildModernInfoRow('Images Available', '${_cameraData?.imagesAvailable ?? 0}', Icons.photo_library_rounded, themeColor),
          const SizedBox(height: 16),
          _buildModernInfoRow('Rotation Interval', '${_cameraData?.rotationInterval ?? 0}s', Icons.rotate_right_rounded, themeColor),
        ],
      ),
    );
  }
  
  Widget _buildTimingInfo() {
    final timing = _imageMetadata?['timing'] as Map<String, dynamic>?;
    if (timing == null) return const SizedBox.shrink();
    
    const Color themeColor = Color(0xFF06B6D4);
    
    return _buildThemeContainer(
      themeColor,
      'Timing Information',
      'Rotation timing and intervals',
      Icons.access_time_rounded,
      Column(
        children: [
          _buildModernInfoRow('Time Since Last Rotation', '${timing['time_since_last_rotation']?.toStringAsFixed(1) ?? 'N/A'}s', Icons.history_rounded, themeColor),
          const SizedBox(height: 16),
          _buildModernInfoRow('Time Until Next Rotation', '${timing['time_until_next_rotation']?.toStringAsFixed(1) ?? 'N/A'}s', Icons.schedule_rounded, themeColor),
          const SizedBox(height: 16),
          _buildModernInfoRow('Rotation Interval', '${timing['rotation_interval_seconds']?.toStringAsFixed(0) ?? 'N/A'}s', Icons.sync_rounded, themeColor),
        ],
      ),
    );
  }
  
  Widget _buildImageMetadata() {
    final metadata = _imageMetadata?['image_metadata'] as Map<String, dynamic>?;
    if (metadata == null) return const SizedBox.shrink();
    
    final allImages = metadata['all_images'] as List<dynamic>?;
    const Color themeColor = Color(0xFF10B981);
    
    return _buildThemeContainer(
      themeColor,
      'Image Metadata',
      'Image collection information',
      Icons.dataset_rounded,
      Column(
        children: [
          _buildModernInfoRow('Current Index', '${metadata['current_index'] ?? 'N/A'}', Icons.bookmark_rounded, themeColor),
          const SizedBox(height: 16),
          _buildModernInfoRow('Total Images', '${metadata['total_images'] ?? 'N/A'}', Icons.collections_rounded, themeColor),
          const SizedBox(height: 16),
          _buildModernInfoRow('Current Filename', metadata['current_filename'] ?? 'N/A', Icons.insert_drive_file_rounded, themeColor),
          if (allImages != null && allImages.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildImagesList(allImages, metadata, themeColor),
          ],
        ],
      ),
    );
  }

  Widget _buildImagesList(List<dynamic> allImages, Map<String, dynamic> metadata, Color themeColor) {
    return Container(
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
          color: themeColor.withOpacity(0.08),
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
                      themeColor.withOpacity(0.1),
                      themeColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  Icons.photo_library_rounded,
                  color: themeColor,
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
            
            return _buildImageItem(imageName, isCurrent, themeColor);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildImageItem(String imageName, bool isCurrent, Color themeColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCurrent 
              ? [
                  themeColor.withOpacity(0.15),
                  themeColor.withOpacity(0.08),
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
              ? themeColor.withOpacity(0.3)
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
              color: isCurrent ? themeColor : Colors.transparent,
              border: Border.all(
                color: isCurrent ? themeColor : Colors.grey.shade400,
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
                color: isCurrent ? themeColor : const Color(0xFF64748B),
              ),
            ),
          ),
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    themeColor.withOpacity(0.15),
                    themeColor.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: themeColor.withOpacity(0.2),
                ),
              ),
              child: Text(
                'Current',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: themeColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Método unificado para crear filas de información modernas
  Widget _buildModernInfoRow(String label, String value, IconData icon, Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _buildUnifiedDecoration(themeColor: themeColor),
      child: Row(
        children: [
          _buildIconContainer(icon, themeColor),
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

  // Unified decoration method that handles all box decoration patterns
  BoxDecoration _buildUnifiedDecoration({
    required Color themeColor,
    double borderRadius = 16,
    bool useGradient = true,
    double shadowOpacity = 0.08,
  }) {
    return BoxDecoration(
      gradient: useGradient ? LinearGradient(
        colors: [
          const Color(0xFFF8FAFC),
          const Color(0xFFF1F5F9),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ) : null,
      color: useGradient ? null : Colors.white,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: themeColor.withOpacity(shadowOpacity),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: themeColor.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Enhanced icon container with configurable size
  Widget _buildIconContainer(IconData icon, Color themeColor, {double size = 40}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: LinearGradient(
          colors: [
            themeColor.withOpacity(0.1),
            themeColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        icon,
        color: themeColor,
        size: size * 0.5,
      ),
    );
  }

  // Simplified theme container using unified decoration
  Widget _buildThemeContainer(Color themeColor, String title, String subtitle, IconData headerIcon, Widget child) {
    return Container(
      width: double.infinity,
      decoration: _buildUnifiedDecoration(
        themeColor: themeColor, 
        borderRadius: 24,
        useGradient: false,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIconContainer(headerIcon, themeColor, size: 48),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
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
          child,
        ],
      ),
    );
  }
}
