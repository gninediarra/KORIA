import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'api_service.dart';

class VoiceService {
  static final AudioPlayer _player = AudioPlayer();
  static final AudioRecorder _recorder = AudioRecorder();
  static bool _isRecording = false;

  static bool get isRecording => _isRecording;

  /// Play TTS audio streamed from backend /api/tts
  static Future<void> speak(String text, {String lang = 'fr'}) async {
    if (text.isEmpty) return;
    try {
      final uri = ApiService.ttsUri(text, lang: lang);
      await _player.play(UrlSource(uri.toString()));
    } catch (e) {
      debugPrint('[VoiceService] speak error: $e');
    }
  }

  static Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  /// Start microphone recording — returns tmp file path or null on failure
  static Future<String?> startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) return null;

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      _isRecording = true;
      return path;
    } catch (e) {
      debugPrint('[VoiceService] startRecording error: $e');
      return null;
    }
  }

  /// Stop recording and send bytes to backend Whisper for transcription
  static Future<String?> stopAndTranscribe({String langue = 'fr'}) async {
    if (!_isRecording) return null;
    try {
      final path = await _recorder.stop();
      _isRecording = false;
      if (path == null) return null;

      final file = File(path);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      await file.delete();

      final result = await ApiService.transcribe(bytes, lang: langue, mimeType: 'audio/mp4');
      return result?['text'] as String?;
    } catch (e) {
      _isRecording = false;
      debugPrint('[VoiceService] stopAndTranscribe error: $e');
      return null;
    }
  }

  static Future<void> dispose() async {
    try {
      await _player.dispose();
      await _recorder.dispose();
    } catch (_) {}
  }
}
