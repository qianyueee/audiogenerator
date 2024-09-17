@JS()
library audio_generator;

import 'package:js/js.dart';

@JS('generateAndPlaySineWave')
external void generateAndPlaySineWave(List<double> harmonics, List<double> harmonicVolumes, List<double> dampingFactors, List<double> bpmValues);

@JS('stopOscillators')
external void stopOscillators();