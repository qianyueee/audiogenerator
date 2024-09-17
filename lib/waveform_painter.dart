import 'package:flutter/material.dart';
import 'dart:math' as math;

class WaveformPainter extends CustomPainter {
  final List<double> harmonics;
  final List<double> harmonicVolumes;
  final List<double> dampingFactors;
  final List<double> bpmValues;
  final double animationValue;

  WaveformPainter({
    required this.harmonics,
    required this.harmonicVolumes,
    required this.dampingFactors,
    required this.bpmValues,
    required this.animationValue,
  });

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

    // Calculate the total volume to use for normalization
    final totalVolume = harmonicVolumes.reduce((sum, volume) => sum + volume);
    final normalizer = totalVolume > 0 ? 1 / totalVolume : 1;

    for (int x = 0; x < width; x++) {
      double t = (x / width + animationValue) % 1.0;
      double y = 0;

      for (int i = 0; i < harmonics.length; i++) {
        double frequency = harmonics[i];
        double volume = harmonicVolumes[i] * normalizer; // Normalize the volume
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

      double scaledY = y * height / 4;  // Scale the waveform to fit the height
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