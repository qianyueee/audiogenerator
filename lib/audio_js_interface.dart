import 'package:js/js.dart';

@JS('generateAndPlaySineWave')
external void generateAndPlaySineWave(List<double> harmonics, List<double> harmonicVolumes, List<double> dampingFactors, List<double> bpmValues, double vibratoDepth, double vibratoSpeed);

@JS('stopOscillators')
external void stopOscillators();

@JS('updateOscillators')
external void updateOscillators(List<double> harmonics, List<double> harmonicVolumes, List<double> dampingFactors, List<double> bpmValues, double vibratoDepth, double vibratoSpeed);