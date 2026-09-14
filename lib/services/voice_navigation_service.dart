import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';

/// Service for handling voice navigation (Text-to-Speech)
/// Wraps FlutterTTS with production-grade error handling
class VoiceNavigationService {
  VoiceNavigationService._();

  static VoiceNavigationService? _instance;
  static VoiceNavigationService get instance => _instance ??= VoiceNavigationService._();

  FlutterTts? _flutterTts;
  bool _isInitialized = false;
  bool _isMuted = false;

  final Set<String> _announcedInstructions = {};

  /// Initialize TTS engine
  Future<bool> initialize({
    String language = 'en-US',
    double speechRate = 0.9,
    double volume = 1.0,
  }) async {
    try {
      _flutterTts = FlutterTts();
      
      await _flutterTts!.setLanguage(language);
      await _flutterTts!.setSpeechRate(speechRate);
      await _flutterTts!.setVolume(volume);
      
      // Check if language is available
      final languages = await _flutterTts!.getLanguages;
      if (languages != null && !languages.contains(language)) {
        // Fallback to English if language not available
        await _flutterTts!.setLanguage('en-US');
      }

      _isInitialized = true;
      return true;
    } catch (e) {
      _isInitialized = false;
      return false;
    }
  }

  /// Speak navigation instruction
  Future<void> speak(String instruction) async {
    if (!_isInitialized || _isMuted) return;
    
    // Prevent duplicate announcements
    final normalized = instruction.toLowerCase().trim();
    if (_announcedInstructions.contains(normalized)) {
      return;
    }

    try {
      await _flutterTts!.speak(instruction);
      _announcedInstructions.add(normalized);
      
      // Clean up old announcements to prevent memory bloat
      if (_announcedInstructions.length > 50) {
        _announcedInstructions.remove(_announcedInstructions.first);
      }
    } catch (e) {
      // Silently fail - don't crash navigation
    }
  }

  /// Speak navigation instruction with distance prefix
  Future<void> speakWithDistance(String instruction, double distanceMeters) async {
    if (!_isInitialized || _isMuted) return;

    final distanceText = _formatDistance(distanceMeters);
    final fullInstruction = 'In $distanceText, $instruction';
    
    await speak(fullInstruction);
  }

  /// Speak arrival announcement
  Future<void> speakArrival(String destinationName) async {
    if (!_isInitialized || _isMuted) return;

    await speak('You have arrived at $destinationName');
  }

  /// Speak rerouting announcement
  Future<void> speakRerouting() async {
    if (!_isInitialized || _isMuted) return;

    await speak('Rerouting');
  }

  /// Stop current speech
  Future<void> stop() async {
    if (!_isInitialized) return;
    
    try {
      await _flutterTts!.stop();
    } catch (e) {
      // Silently fail
    }
  }

  /// Clear announced instructions cache
  void clearAnnouncedInstructions() {
    _announcedInstructions.clear();
  }

  /// Toggle mute
  void toggleMute() {
    _isMuted = !_isMuted;
  }

  bool get isMuted => _isMuted;
  bool get isInitialized => _isInitialized;

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} meters';
    }
    return '${(meters / 1000).toStringAsFixed(1)} kilometers';
  }

  void dispose() {
    stop();
    _flutterTts = null;
    _isInitialized = false;
  }
}
