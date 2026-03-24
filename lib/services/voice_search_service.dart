import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

/// Centralized voice recognition service wrapping `speech_to_text`.
///
/// Usage:
/// ```dart
/// final service = VoiceSearchService();
/// final ok = await service.initialize();
/// if (ok) {
///   await service.startListening(
///     onPartialResult: (words) => setState(() => _words = words),
///     onResult: (words) => _performSearch(words),
///   );
/// }
/// ```
class VoiceSearchService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;

  // Stored per-session callbacks — propagated by the engine's onError /
  // onStatus handlers, which run outside the listen() callback scope.
  void Function(String message)? _onError;
  void Function()? _onDone;
  bool _doneSignaled = false;

  // ─── Getters ────────────────────────────────────────────────────────────────

  bool get isAvailable => _initialized && _speech.isAvailable;
  bool get isListening => _speech.isListening;

  // ─── Lifecycle ───────────────────────────────────────────────────────────────

  /// Initialize the speech engine. Returns `true` on success.
  Future<bool> initialize() async {
    try {
      _initialized = await _speech.initialize(
        onError: _handleError,
        onStatus: _handleStatus,
      );
      return _initialized;
    } catch (_) {
      _initialized = false;
      return false;
    }
  }

  /// Start listening. Calls [onPartialResult] continuously and [onResult] once
  /// a final utterance is detected. Calls [onError] with a human-readable
  /// message if microphone access is unavailable or a permanent hardware error
  /// occurs. Calls [onDone] when the session ends for any reason.
  Future<void> startListening({
    required void Function(String words) onPartialResult,
    required void Function(String words) onResult,
    void Function(String message)? onError,
    void Function()? onDone,
  }) async {
    // Store callbacks so the engine's error/status handlers can reach them.
    _onError = onError;
    _onDone = onDone;
    _doneSignaled = false;

    if (!_initialized) {
      final ok = await initialize();
      if (!ok) {
        onError?.call('Could not initialize microphone. Check device permissions.');
        return;
      }
    }

    if (!_speech.isAvailable) {
      onError?.call('Speech recognition is not available on this device.');
      return;
    }

    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        onPartialResult(result.recognizedWords);
        if (result.finalResult) {
          onResult(result.recognizedWords);
          _signalDone();
        }
      },
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 3),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.search,
      ),
    );
  }

  /// Stop listening immediately.
  Future<void> stopListening() async => _speech.stop();

  /// Cancel without returning a result.
  Future<void> cancel() async => _speech.cancel();

  /// Dispose the underlying engine.
  Future<void> dispose() async => _speech.cancel();

  // ─── Private ─────────────────────────────────────────────────────────────────

  /// Fires [_onDone] exactly once, regardless of which event triggers it.
  void _signalDone() {
    if (_doneSignaled) return;
    _doneSignaled = true;
    _onDone?.call();
  }

  void _handleError(SpeechRecognitionError error) {
    // Only surface permanent errors (permission denied, hardware failure) as
    // blocking error messages. Transient errors (no match, network blip,
    // silence timeout) just end the session so the user can tap to retry.
    if (error.permanent) {
      _onError?.call(_readableError(error.errorMsg));
    }
    _signalDone();
  }

  void _handleStatus(String status) {
    // 'done' and 'notListening' both mean the engine has stopped.
    if (status == 'done' || status == 'notListening') {
      _signalDone();
    }
  }

  String _readableError(String errorCode) {
    switch (errorCode) {
      case 'error_permission':
        return 'Microphone permission denied. Enable it in Settings.';
      case 'error_audio':
        return 'Microphone error. Please try again.';
      default:
        return 'Microphone unavailable. Check device permissions.';
    }
  }
}
