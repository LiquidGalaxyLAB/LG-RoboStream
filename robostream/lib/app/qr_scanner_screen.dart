import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:robostream/assets/styles/app_styles.dart';

class QRScannerScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onQRScanned;
  
  const QRScannerScreen({
    super.key,
    required this.onQRScanned,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> 
    with TickerProviderStateMixin {
  late MobileScannerController cameraController;
  bool _isScanning = true;
  bool _flashOn = false;
  String? _lastErrorCode;
  DateTime? _lastErrorTime;
  String _scanningMessage = 'Position the QR code within the frame';
  Color _frameColor = AppStyles.primaryColor;
  
  late AnimationController _scanLineController;
  late AnimationController _pulseController;
  late Animation<double> _scanLineAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeCameraController();
    _initializeAnimations();
  }

  void _initializeCameraController() {
    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  void _initializeAnimations() {
    _scanLineController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scanLineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanLineController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _scanLineController.repeat();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _pulseController.dispose();
    
    try {
      cameraController.stop();
    } catch (e) {

    }
    
    try {
      cameraController.dispose();
    } catch (e) {

    }
    
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning || !mounted) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {

        final now = DateTime.now();
        if (_lastErrorCode == code && 
            _lastErrorTime != null &&
            now.difference(_lastErrorTime!).inSeconds < 3) {
          return;
        }
        
        _lastErrorCode = code;
        _lastErrorTime = now;
        
        _processQRCode(code);
        break;
      }
    }
  }

  void _processQRCode(String qrCode) {
    if (!mounted) return;
    
    setState(() {
      _isScanning = false;
      _scanningMessage = 'Processing QR code...';
      _frameColor = Colors.orange;
    });
    
    HapticFeedback.lightImpact();
    
    try {
      final Map<String, dynamic> data = json.decode(qrCode);
      
      if (data.containsKey('username') &&
          data.containsKey('ip') &&
          data.containsKey('port') &&
          data.containsKey('password') &&
          data.containsKey('screens')) {
        
        if (data['port'] is int) {
          data['port'] = data['port'].toString();
        }
        if (data['screens'] is int) {
          data['screens'] = data['screens'].toString();
        }
        
        if (!mounted) return;
        
        setState(() {
          _scanningMessage = 'QR code detected successfully!';
          _frameColor = Colors.green;
        });
        
        HapticFeedback.heavyImpact();

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            widget.onQRScanned(data);
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          }
        });
      } else {
        _showError('Missing required fields in QR code', qrCode);
      }
    } catch (e) {
      _showError('Invalid QR code format', qrCode);
    }
  }

  void _showError(String message, String code) {
    if (!mounted) return;
    
    _lastErrorCode = code;
    _lastErrorTime = DateTime.now();
    
    setState(() {
      _scanningMessage = message;
      _frameColor = Colors.red;
    });
    
    HapticFeedback.mediumImpact();
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isScanning = true;
          _scanningMessage = 'Position the QR code within the frame';
          _frameColor = AppStyles.primaryColor;
        });
      }
    });
  }

  void _toggleFlash() {
    setState(() {
      _flashOn = !_flashOn;
    });
    cameraController.toggleTorch();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Scan LG Configuration',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 64,
                        color: Colors.white54,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Camera Error',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Unable to initialize camera\nPlease check camera permissions',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Close'),
                      ),
                    ],
                  ),
                ),
              );
            },
            placeholderBuilder: (context, child) {
              return Container(
                color: Colors.black,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppStyles.primaryColor,
                  ),
                ),
              );
            },
          ),
          
          AnimatedBuilder(
            animation: Listenable.merge([_scanLineController, _pulseController]),
            builder: (context, child) {
              return IgnorePointer(
                child: CustomPaint(
                  painter: EnhancedScannerOverlayPainter(
                    frameColor: _frameColor,
                    scanLineProgress: _scanLineAnimation.value,
                    pulseScale: _pulseAnimation.value,
                  ),
                  child: Container(),
                ),
              );
            },
          ),
          
          Positioned(
            top: 120,
            left: 20,
            right: 20,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: _frameColor.withOpacity(0.9),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: _frameColor.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isScanning) ...[
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ] else if (_frameColor == Colors.green) ...[
                    const Icon(Icons.check_circle, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                  ] else if (_frameColor == Colors.red) ...[
                    const Icon(Icons.error, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      _scanningMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Positioned(
            bottom: 120,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppStyles.primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppStyles.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.qr_code_scanner,
                      color: AppStyles.primaryColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'LG Configuration QR Scanner',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hold your device steady and align the QR code within the scanning area',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          Positioned(
            bottom: 40,
            right: 20,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _flashOn 
                    ? AppStyles.primaryColor 
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: _toggleFlash,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _flashOn ? Icons.flash_on : Icons.flash_off,
                        key: ValueKey(_flashOn),
                        color: _flashOn ? Colors.white : AppStyles.primaryColor,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EnhancedScannerOverlayPainter extends CustomPainter {
  final Color frameColor;
  final double scanLineProgress;
  final double pulseScale;

  EnhancedScannerOverlayPainter({
    required this.frameColor,
    required this.scanLineProgress,
    required this.pulseScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final scanLinePaint = Paint()
      ..color = frameColor.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final double scanAreaSize = size.width * 0.75;
    final double left = (size.width - scanAreaSize) / 2;
    final double top = (size.height - scanAreaSize) / 2;
    final double right = left + scanAreaSize;
    final double bottom = top + scanAreaSize;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, top), paint);
    canvas.drawRect(Rect.fromLTWH(0, bottom, size.width, size.height - bottom), paint);
    canvas.drawRect(Rect.fromLTWH(0, top, left, bottom - top), paint);
    canvas.drawRect(Rect.fromLTWH(right, top, size.width - right, bottom - top), paint);

    final double scanLineY = top + (bottom - top) * scanLineProgress;
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        frameColor.withOpacity(0.0),
        frameColor.withOpacity(0.8),
        frameColor.withOpacity(0.0),
      ],
    );

    final rect = Rect.fromLTRB(left + 10, scanLineY - 1, right - 10, scanLineY + 1);
    final shader = gradient.createShader(rect);
    scanLinePaint.shader = shader;
    canvas.drawRect(rect, scanLinePaint);

    final double cornerLength = 25;
    final double cornerThickness = 4;
    final double pulseOffset = (pulseScale - 1.0) * 10;

    final cornerPaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = cornerThickness
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(
      Path()
        ..moveTo(left - pulseOffset, top + cornerLength)
        ..lineTo(left - pulseOffset, top - pulseOffset)
        ..lineTo(left + cornerLength, top - pulseOffset),
      cornerPaint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(right - cornerLength, top - pulseOffset)
        ..lineTo(right + pulseOffset, top - pulseOffset)
        ..lineTo(right + pulseOffset, top + cornerLength),
      cornerPaint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(left - pulseOffset, bottom - cornerLength)
        ..lineTo(left - pulseOffset, bottom + pulseOffset)
        ..lineTo(left + cornerLength, bottom + pulseOffset),
      cornerPaint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(right - cornerLength, bottom + pulseOffset)
        ..lineTo(right + pulseOffset, bottom + pulseOffset)
        ..lineTo(right + pulseOffset, bottom - cornerLength),
      cornerPaint,
    );

    final guidePaint = Paint()
      ..color = frameColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final centerX = (left + right) / 2;
    final centerY = (top + bottom) / 2;
    final guideLength = 20;

    canvas.drawLine(
      Offset(centerX - guideLength, centerY),
      Offset(centerX + guideLength, centerY),
      guidePaint,
    );

    canvas.drawLine(
      Offset(centerX, centerY - guideLength),
      Offset(centerX, centerY + guideLength),
      guidePaint,
    );

    final decorationPaint = Paint()
      ..color = frameColor.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final decorationSize = 6.0;
    
    canvas.drawCircle(Offset(left, top), decorationSize, decorationPaint);
    canvas.drawCircle(Offset(right, top), decorationSize, decorationPaint);
    canvas.drawCircle(Offset(left, bottom), decorationSize, decorationPaint);
    canvas.drawCircle(Offset(right, bottom), decorationSize, decorationPaint);
  }

  @override
  bool shouldRepaint(EnhancedScannerOverlayPainter oldDelegate) {
    return oldDelegate.frameColor != frameColor ||
           oldDelegate.scanLineProgress != scanLineProgress ||
           oldDelegate.pulseScale != pulseScale;
  }
}
