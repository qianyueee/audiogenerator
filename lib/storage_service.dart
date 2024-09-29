import 'dart:html' as html;
import 'dart:convert';

class StorageService {
  static const String _presetsKey = 'sineWavePresets';

  static void savePreset(String name, Map<String, dynamic> settings) {
    Map<String, dynamic> presets = loadAllPresets();
    presets[name] = settings;
    final presetsJson = json.encode(presets);
    html.window.localStorage[_presetsKey] = presetsJson;
  }

  static Map<String, dynamic>? loadPreset(String name) {
    Map<String, dynamic> presets = loadAllPresets();
    return presets[name];
  }

  static Map<String, dynamic> loadAllPresets() {
    final presetsJson = html.window.localStorage[_presetsKey];
    if (presetsJson != null) {
      return json.decode(presetsJson);
    }
    return {};
  }

  static List<String> getPresetNames() {
    Map<String, dynamic> presets = loadAllPresets();
    return presets.keys.toList();
  }

  static void deletePreset(String name) {
    Map<String, dynamic> presets = loadAllPresets();
    presets.remove(name);
    final presetsJson = json.encode(presets);
    html.window.localStorage[_presetsKey] = presetsJson;
  }
}