import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';

class ImageGenerator {
  static Future<Uint8List> generateSensorImage(Map<String, dynamic> sensorInfo) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const double width = 520; // Doubled from 260
    
    final dataList = sensorInfo['data'] as List<Map<String, String>>? ?? [];
    final baseHeight = 300.0; // Doubled from 150
    final itemHeight = 130.0; // Doubled from 65
    final double height = baseHeight + (dataList.length * itemHeight);
    
    _drawBackground(canvas, width, height);
    _drawCard(canvas, width, height);
    _drawTitle(canvas, sensorInfo['title'] ?? 'Sensor Data');
    _drawDataItems(canvas, dataList);
    _drawTimestamp(canvas, height);
    
    return await _finishImage(recorder, width, height);
  }
  
  static Future<Uint8List> generateTextImage(String text, {
    double width = 600, // Doubled from 300
    double height = 200, // Doubled from 100
    Color backgroundColor = const Color(0xFF667eea),
    Color textColor = Colors.white,
    double fontSize = 36, // Doubled from 18
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
    textPainter.layout(maxWidth: width - 40); // Doubled from 20
    
    final xOffset = (width - textPainter.width) / 2;
    final yOffset = (height - textPainter.height) / 2;
    
    textPainter.paint(canvas, Offset(xOffset, yOffset));
    
    return await _finishImage(recorder, width, height);
  }

  static void _drawBackground(Canvas canvas, double width, double height) {
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, width, height));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), backgroundPaint);
  }

  static void _drawCard(Canvas canvas, double width, double height) {
    final cardPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    final cardRect = RRect.fromLTRBR(40, 40, width - 40, height - 40, const Radius.circular(30)); // Doubled padding and radius
    canvas.drawRRect(cardRect, cardPaint);
    
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2; // Doubled from 1
    
    canvas.drawRRect(cardRect, borderPaint);
  }

  static void _drawTitle(Canvas canvas, String title) {
    final titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36, // Doubled from 18
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout();
    titlePainter.paint(canvas, const Offset(60, 60)); // Doubled from 30, 30
  }

  static void _drawDataItems(Canvas canvas, List<Map<String, String>> dataList) {
    double yOffset = 160; // Doubled from 80
    
    for (var dataItem in dataList) {
      final labelPainter = TextPainter(
        text: TextSpan(
          text: dataItem['label'] ?? '',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 28, // Doubled from 14
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(canvas, Offset(60, yOffset)); // Doubled from 30
      
      final valuePainter = TextPainter(
        text: TextSpan(
          text: dataItem['value'] ?? '',
          style: const TextStyle(
            color: Color(0xFFFFD700),
            fontSize: 32, // Doubled from 16
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      valuePainter.layout();
      valuePainter.paint(canvas, Offset(60, yOffset + 50)); // Doubled from 30 and 25
      
      yOffset += 130; // Doubled from 65
    }
  }

  static void _drawTimestamp(Canvas canvas, double height) {
    final timestampPainter = TextPainter(
      text: TextSpan(
        text: 'Last Update: ${DateTime.now().toString().substring(0, 19)}',
        style: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 20, // Doubled from 10
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    timestampPainter.layout();
    timestampPainter.paint(canvas, Offset(60, height - 94)); // Doubled from 30 and 47
  }

  static Future<Uint8List> _finishImage(ui.PictureRecorder recorder, double width, double height) async {
    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData!.buffer.asUint8List();
  }
}
