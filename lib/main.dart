import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:js/js.dart';

@JS('generateAndPlaySineWave')
external void generateAndPlaySineWave(List<double> harmonics, List<double> harmonicVolumes, List<double> dampingFactors, List<double> bpmValues);

@JS('stopOscillators')
external void stopOscillators();

@JS('updateOscillators')
external void updateOscillators(List<double> harmonics, List<double> harmonicVolumes, List<double> dampingFactors, List<double> bpmValues);

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Harmonic Sine Wave Generator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SineWavePlayer(),
    );
  }
}

class SineWavePlayer extends StatefulWidget {
  @override
  _SineWavePlayerState createState() => _SineWavePlayerState();
}

class _SineWavePlayerState extends State<SineWavePlayer> with SingleTickerProviderStateMixin {
  final TextEditingController _baseFrequencyController = TextEditingController(text: "440");
  bool _isPlaying = false;
  List<TextEditingController> _harmonicControllers = [];
  List<double> _harmonicVolumes = List.filled(9, 1.0);
  List<TextEditingController> _dampingFactorControllers = List.generate(9, (_) => TextEditingController(text: "1.0"));
  List<TextEditingController> _bpmControllers = List.generate(9, (_) => TextEditingController(text: "60"));
  late AnimationController _animationController;

  final double _compressionThreshold = 0.8;
  final double _compressionRatio = 0.5;

  @override
  void initState() {
    super.initState();
    _generateHarmonics();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _baseFrequencyController.dispose();
    _harmonicControllers.forEach((controller) => controller.dispose());
    _dampingFactorControllers.forEach((controller) => controller.dispose());
    _bpmControllers.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _generateHarmonics() {
    double baseFrequency = double.tryParse(_baseFrequencyController.text) ?? 440;
    _harmonicControllers = List.generate(9, (index) {
      return TextEditingController(text: (baseFrequency * (index + 1)).toStringAsFixed(2));
    });
  }

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

  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    if (_isPlaying) {
      _startPlayback();
      _animationController.repeat();
    } else {
      stopOscillators();
      _animationController.stop();
    }
  }

  void _startPlayback() {
    List<double> harmonics = _harmonicControllers
        .map((controller) => double.tryParse(controller.text) ?? 0.0)
        .toList();
    List<double> dampingFactors = _dampingFactorControllers
        .map((controller) => double.tryParse(controller.text) ?? 0.0)
        .toList();
    List<double> bpmValues = _bpmControllers
        .map((controller) => double.tryParse(controller.text) ?? 0.0)
        .toList();
    
    List<double> compressedVolumes = _applyDynamicVolumeCompression(_harmonicVolumes);
    
    generateAndPlaySineWave(harmonics, compressedVolumes, dampingFactors, bpmValues);
  }

  void _updatePlayback() {
    if (_isPlaying) {
      List<double> harmonics = _harmonicControllers
          .map((controller) => double.tryParse(controller.text) ?? 0.0)
          .toList();
      List<double> dampingFactors = _dampingFactorControllers
          .map((controller) => double.tryParse(controller.text) ?? 0.0)
          .toList();
      List<double> bpmValues = _bpmControllers
          .map((controller) => double.tryParse(controller.text) ?? 0.0)
          .toList();
      
      List<double> compressedVolumes = _applyDynamicVolumeCompression(_harmonicVolumes);
      
      updateOscillators(harmonics, compressedVolumes, dampingFactors, bpmValues);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Harmonic Sine Wave Generator'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isPlaying)
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomPaint(
                      painter: WaveformPainter(
                        harmonics: _harmonicControllers
                            .map((controller) => double.tryParse(controller.text) ?? 0.0)
                            .toList(),
                        harmonicVolumes: _harmonicVolumes,
                        dampingFactors: _dampingFactorControllers
                            .map((controller) => double.tryParse(controller.text) ?? 0.0)
                            .toList(),
                        bpmValues: _bpmControllers
                            .map((controller) => double.tryParse(controller.text) ?? 0.0)
                            .toList(),
                        animationValue: _animationController.value,
                      ),
                      size: Size.infinite,
                    ),
                  );
                },
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: Text('Press Play to see waveform')),
              ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _baseFrequencyController,
                    decoration: InputDecoration(
                      labelText: 'Base Frequency (Hz)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      _generateHarmonics();
                      _updatePlayback();
                      setState(() {});
                    },
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    _generateHarmonics();
                    _updatePlayback();
                    setState(() {});
                  },
                  child: Text('Generate Harmonics'),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text('Harmonic Controls', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 10),
            ..._harmonicControllers.asMap().entries.map((entry) {
              int index = entry.key;
              var controller = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Harmonic ${index + 1}'),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(labelText: 'Frequency (Hz)'),
                          keyboardType: TextInputType.number,
                          onChanged: (_) {
                            _updatePlayback();
                          },
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: _harmonicVolumes[index],
                          min: 0,
                          max: 1,
                          divisions: 100,
                          label: 'Volume: ${_harmonicVolumes[index].toStringAsFixed(2)}',
                          onChanged: (value) {
                            setState(() {
                              _harmonicVolumes[index] = value;
                            });
                            _updatePlayback();
                          },
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _dampingFactorControllers[index],
                          decoration: InputDecoration(labelText: 'Damping Factor'),
                          keyboardType: TextInputType.number,
                          onChanged: (_) {
                            _updatePlayback();
                          },
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _bpmControllers[index],
                          decoration: InputDecoration(labelText: 'BPM'),
                          keyboardType: TextInputType.number,
                          onChanged: (_) {
                            _updatePlayback();
                          },
                        ),
                      ),
                    ],
                  ),
                  Divider(),
                ],
              );
            }).toList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _togglePlayback,
        child: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
        tooltip: _isPlaying ? 'Stop' : 'Play',
      ),
    );
  }
}

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