import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'audio_generator.dart';
import 'waveform_painter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Harmonic Sine Wave Generator',
      theme: ThemeData(primarySwatch: Colors.blue),
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
  List<double> _harmonics = [];
  List<double> _harmonicVolumes = List.filled(9, 1.0);
  List<TextEditingController> _dampingFactorControllers = List.generate(9, (_) => TextEditingController(text: "1.0"));
  List<TextEditingController> _bpmControllers = List.generate(9, (_) => TextEditingController(text: "60"));
  late AnimationController _animationController;

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
    _dampingFactorControllers.forEach((controller) => controller.dispose());
    _bpmControllers.forEach((controller) => controller.dispose());
    _animationController.dispose();
    super.dispose();
  }

  void _generateHarmonics() {
    double baseFrequency = double.tryParse(_baseFrequencyController.text) ?? 440;
    _harmonics = List.generate(9, (index) => baseFrequency * (index + 1));
  }

  void _playAudio() {
    List<double> dampingFactors = _dampingFactorControllers
        .map((controller) => double.tryParse(controller.text) ?? 0.0)
        .toList();
    List<double> bpmValues = _bpmControllers
        .map((controller) => double.tryParse(controller.text) ?? 0.0)
        .toList();
    
    generateAndPlaySineWave(_harmonics, _harmonicVolumes, dampingFactors, bpmValues);
    setState(() {
      _isPlaying = true;
    });
    _animationController.repeat();  // Start the animation
  }

  void _stopAudio() {
    stopOscillators();
    setState(() {
      _isPlaying = false;
    });
    _animationController.stop();  // Stop the animation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Harmonic Sine Wave Generator')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isPlaying
                      ? CustomPaint(
                          painter: WaveformPainter(
                            harmonics: _harmonics,
                            harmonicVolumes: _harmonicVolumes,
                            dampingFactors: _dampingFactorControllers
                                .map((controller) => double.tryParse(controller.text) ?? 0.0)
                                .toList(),
                            bpmValues: _bpmControllers
                                .map((controller) => double.tryParse(controller.text) ?? 0.0)
                                .toList(),
                            animationValue: _animationController.value,
                          ),
                        )
                      : Center(child: Text('Press Play to see waveform')),
                );
              },
            ),
            SizedBox(height: 20),
            TextField(
              controller: _baseFrequencyController,
              decoration: InputDecoration(labelText: 'Base Frequency (Hz)'),
              keyboardType: TextInputType.number,
              onChanged: (_) {
                _generateHarmonics();
                setState(() {});
              },
            ),
            SizedBox(height: 20),
            Text('Harmonic Controls', style: Theme.of(context).textTheme.titleLarge),
            ..._harmonics.asMap().entries.map((entry) {
              int index = entry.key;
              double frequency = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Harmonic ${index + 1}: ${frequency.toStringAsFixed(2)} Hz'),
                  Row(
                    children: [
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
                            if (_isPlaying) _playAudio();
                          },
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _dampingFactorControllers[index],
                          decoration: InputDecoration(labelText: 'Damping Factor'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))],
                          onChanged: (_) {
                            if (_isPlaying) _playAudio();
                            setState(() {});
                          },
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _bpmControllers[index],
                          decoration: InputDecoration(labelText: 'BPM'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (_) {
                            if (_isPlaying) _playAudio();
                            setState(() {});
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
            ElevatedButton(
              onPressed: _isPlaying ? _stopAudio : _playAudio,
              child: Text(_isPlaying ? 'Stop' : 'Play'),
            ),
          ],
        ),
      ),
    );
  }
}