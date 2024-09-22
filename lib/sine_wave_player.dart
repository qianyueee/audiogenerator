import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'waveform_painter.dart';
import 'audio_js_interface.dart';

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

  double _vibratoDepth = 0.03; // 默认值设置为 3%，最大值将是 6%
  double _vibratoSpeed = 5.0;

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
    
    generateAndPlaySineWave(harmonics, compressedVolumes, dampingFactors, bpmValues, _vibratoDepth, _vibratoSpeed);
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
      
      updateOscillators(harmonics, compressedVolumes, dampingFactors, bpmValues, _vibratoDepth, _vibratoSpeed);
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
            SizedBox(height: 20),
            Text('Vibrato Controls', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text('Depth (Semitones)'),
                      Slider(
                        value: _vibratoDepth,
                        min: 0.0,
                        max: 0.06, // 最大值设置为 6%，相当于一个半音
                        divisions: 120,
                        label: (_vibratoDepth * 200).toStringAsFixed(2),
                        onChanged: (value) {
                          setState(() {
                            _vibratoDepth = value;
                          });
                          _updatePlayback();
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('Speed (Hz)'),
                      Slider(
                        value: _vibratoSpeed,
                        min: 0.1,
                        max: 20.0,
                        divisions: 199,
                        label: _vibratoSpeed.toStringAsFixed(1),
                        onChanged: (value) {
                          setState(() {
                            _vibratoSpeed = value;
                          });
                          _updatePlayback();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
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