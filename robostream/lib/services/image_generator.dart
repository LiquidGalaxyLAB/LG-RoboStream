import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';

class ImageGenerator {
  static Future<Uint8List> generateSensorImage(Map<String, dynamic> sensorInfo) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const double width = 260;
    
    final dataList = sensorInfo['data'] as List<Map<String, String>>? ?? [];
    final baseHeight = 150.0;
    final itemHeight = 65.0;
    final double height = baseHeight + (dataList.length * itemHeight);
    
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, width, height));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), backgroundPaint);
    
    final cardPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    final cardRect = RRect.fromLTRBR(20, 20, width - 20, height - 20, const Radius.circular(15));
    canvas.drawRRect(cardRect, cardPaint);
    
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    canvas.drawRRect(cardRect, borderPaint);
    
    final titlePainter = TextPainter(
      text: TextSpan(
        text: sensorInfo['title'] ?? 'Sensor Data',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout();
    titlePainter.paint(canvas, const Offset(30, 30));
    
    double yOffset = 80;  
    
    for (var dataItem in dataList) {
      final labelPainter = TextPainter(
        text: TextSpan(
          text: dataItem['label'] ?? '',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(canvas, Offset(30, yOffset));
      
      final valuePainter = TextPainter(
        text: TextSpan(
          text: dataItem['value'] ?? '',
          style: const TextStyle(
            color: Color(0xFFFFD700),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      valuePainter.layout();
      valuePainter.paint(canvas, Offset(30, yOffset + 25));
      
      yOffset += 65;
    }
    
    final timestampPainter = TextPainter(
      text: TextSpan(
        text: 'Last Update: ${DateTime.now().toString().substring(0, 19)}',
        style: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    timestampPainter.layout();
    timestampPainter.paint(canvas, Offset(30, height - 47));
    
    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData!.buffer.asUint8List();
  }
  
  static Future<Uint8List> generateTextImage(String text, {
    double width = 300,
    double height = 100,
    Color backgroundColor = const Color(0xFF667eea),
    Color textColor = Colors.white,
    double fontSize = 18,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    final backgroundPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), backgroundPaint);
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout(maxWidth: width - 20);
    
    final xOffset = (width - textPainter.width) / 2;
    final yOffset = (height - textPainter.height) / 2;
    
    textPainter.paint(canvas, Offset(xOffset, yOffset));
    
    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData!.buffer.asUint8List();
  }
}
