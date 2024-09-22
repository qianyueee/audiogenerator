import 'package:flutter/material.dart';
import 'dart:math' as math;

class WaveformPainter extends CustomPainter {
  final List<double> harmonics;
  final List<double> harmonicVolumes;
  final List<double> dampingFactors;
  final List<double> bpmValues;
  final double animationValue;

  final double _compressionThreshold = 0.8;
  final double _compressionRatio = 0.5;

  WaveformPainter({
    required this.harmonics,
    required this.harmonicVolumes,
    required this.dampingFactors,
    required this.bpmValues,
    required this.animationValue,
  });

  List<double> _applyDynamicVolumeCompression(List<double> volumes) {
    double totalVolume = volumes.reduce((a, b) => a + b);
    
    if (totalVolume <= _compressionThreshold) {
      return List.from(volumes);
    } else {
      double excess = totalVolume - _compressionThreshold;
      double compressionFactor = 1 - (excess * _compressionRatio / totalVolume);
      
      return volumes.map((v) => v * compressionFactor).toList();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final width = size.width;
    final height = size.height;
    final middleY = height / 2;

    List<double> compressedVolumes = _applyDynamicVolumeCompression(harmonicVolumes);

    for (int x = 0; x < width; x++) {
      double t = (x / width + animationValue) % 1.0;
      double y = 0;

      for (int i = 0; i < harmonics.length; i++) {
        double frequency = harmonics[i];
        double volume = compressedVolumes[i];
        double dampingFactor = dampingFactors[i];
        double bpm = bpmValues[i];

        if (bpm > 0) {
          double cyclePosition = (t * bpm / 60) % 1.0;
          double envelope = math.exp(-dampingFactor * cyclePosition);
          y += math.sin(2 * math.pi * frequency * t) * volume * envelope;
        } else {
          y += math.sin(2 * math.pi * frequency * t) * volume;
        }
      }

      double scaledY = y * height / 4;
      if (x == 0) {
        path.moveTo(x.toDouble(), middleY + scaledY);
      } else {
        path.lineTo(x.toDouble(), middleY + scaledY);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.harmonics != harmonics ||
           oldDelegate.harmonicVolumes != harmonicVolumes ||
           oldDelegate.dampingFactors != dampingFactors ||
           oldDelegate.bpmValues != bpmValues;
  }
}