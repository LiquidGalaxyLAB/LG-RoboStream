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
  final RobotServerService _serverService = RobotServerService();
  RGBCameraData? _cameraData;
  Map<String, dynamic>? _imageMetadata;
  String? _imageBase64;
  bool _isLoading = true;
  bool _useDirectUrl = false; // Fallback para usar URL directa
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
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadCameraData();
    });
  }
  
  Future<void> _loadCameraData() async {
    try {
      // Primero intentar obtener datos básicos de la cámara
      final cameraData = await _serverService.getRGBCameraData();
      
      if (cameraData != null && mounted) {
        setState(() {
          _cameraData = cameraData;
          _isLoading = false;
          _lastError = null;
        });
        
        // Luego intentar obtener datos completos con imagen
        try {
          final imageData = await _serverService.getRGBCameraImageData();
          if (imageData != null && mounted) {
            setState(() {
              _imageMetadata = imageData;
              _imageBase64 = imageData['image_data'];
              _useDirectUrl = false;
            });
            
            // Verificar si la imagen base64 es válida
            if (_imageBase64 != null && _imageBase64!.isNotEmpty) {
              try {
                base64Decode(_imageBase64!);
                print('✅ Imagen base64 decodificada correctamente');
              } catch (e) {
                print('❌ Error decodificando imagen base64: $e');
                setState(() {
                  _useDirectUrl = true;
                  _imageBase64 = null;
                });
              }
            }
          }
        } catch (e) {
          print('⚠️ Error obteniendo datos de imagen, usando URL directa: $e');
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
      print('❌ Error cargando datos de cámara: $e');
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'RGB Camera',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF64748B)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF6366F1)),
            onPressed: _loadCameraData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
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
              backgroundColor: const Color(0xFF6366F1),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6366F1),
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Camera View',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _cameraData?.status == 'Active' 
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _cameraData?.status ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _cameraData?.status == 'Active' 
                          ? const Color(0xFF10B981)
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Mostrar imagen usando base64 o URL directa
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _buildImageWidget(),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  Widget _buildImageWidget() {
    // Intentar usar imagen base64 primero
    if (!_useDirectUrl && _imageBase64 != null && _imageBase64!.isNotEmpty) {
      try {
        final imageBytes = base64Decode(_imageBase64!);
        return Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('❌ Error mostrando imagen base64: $error');
            return _buildImageFromUrl();
          },
        );
      } catch (e) {
        print('❌ Error decodificando base64: $e');
        return _buildImageFromUrl();
      }
    }
    
    // Usar URL directa como fallback
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
        print('❌ Error cargando imagen desde URL: $error');
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Camera Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Camera ID', _cameraData?.cameraId ?? 'Unknown'),
          _buildInfoRow('Resolution', _cameraData?.resolution ?? 'Unknown'),
          _buildInfoRow('Frame Rate', '${_cameraData?.fps ?? 0} FPS'),
          _buildInfoRow('Status', _cameraData?.status ?? 'Unknown'),
          _buildInfoRow('Current Image', _cameraData?.currentImage ?? 'None'),
          _buildInfoRow('Images Available', '${_cameraData?.imagesAvailable ?? 0}'),
          _buildInfoRow('Rotation Interval', '${_cameraData?.rotationInterval ?? 0}s'),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFF06B6D4),
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Timing Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Time Since Last Rotation', '${timing['time_since_last_rotation']?.toStringAsFixed(1) ?? 'N/A'}s'),
          _buildInfoRow('Time Until Next Rotation', '${timing['time_until_next_rotation']?.toStringAsFixed(1) ?? 'N/A'}s'),
          _buildInfoRow('Rotation Interval', '${timing['rotation_interval_seconds']?.toStringAsFixed(0) ?? 'N/A'}s'),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Image Metadata',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Current Index', '${metadata['current_index'] ?? 'N/A'}'),
          _buildInfoRow('Total Images', '${metadata['total_images'] ?? 'N/A'}'),
          _buildInfoRow('Current Filename', metadata['current_filename'] ?? 'N/A'),
          if (allImages != null && allImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Available Images:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            ...allImages.asMap().entries.map((entry) {
              final index = entry.key;
              final imageName = entry.value as String;
              final isCurrent = index == (metadata['current_index'] ?? -1);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isCurrent 
                      ? const Color(0xFF6366F1).withOpacity(0.1)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCurrent 
                        ? const Color(0xFF6366F1).withOpacity(0.3)
                        : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCurrent ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      size: 16,
                      color: isCurrent ? const Color(0xFF6366F1) : Colors.grey[400],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        imageName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                          color: isCurrent ? const Color(0xFF6366F1) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
