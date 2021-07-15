import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text_platform_interface/speech_to_text_platform_interface.dart';

class SpeechToTextHelper {
  SpeechToText _speech = SpeechToText();

  static SpeechToTextHelper? _instance;

  SpeechToTextHelper._();

  factory SpeechToTextHelper() {
    _instance ??= SpeechToTextHelper._();
    return _instance!;
  }

  static const _defaultFinalTimeout = Duration(milliseconds: 2000);

  void init({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
    debugLogging = false,
    Duration finalTimeout = _defaultFinalTimeout,
    List<SpeechConfigOption>? options,
    Function(SpeechToText? speech, bool hasSpeech)? onSpeechInitialized,
  }) async {
    var hasSpeech = await _speech.initialize(
      onError: onError,
      onStatus: onStatus,
      debugLogging: debugLogging,
      options: options,
      finalTimeout: finalTimeout,
    );

    if (hasSpeech) {
      onSpeechInitialized?.call(_speech, hasSpeech);
    } else {
      onSpeechInitialized?.call(null, hasSpeech);
    }
  }

  void startListening({
    Function()? onStarted,
    SpeechResultListener? onResult,
    Duration? listenFor,
    Duration? pauseFor,
    String? localeId,
    SpeechSoundLevelChange? onSoundLevelChange,
    cancelOnError = false,
    partialResults = true,
    onDevice = false,
    ListenMode listenMode = ListenMode.confirmation,
    sampleRate = 0,
  }) {
    _speech
        .listen(
      onResult: onResult,
      listenFor: listenFor,
      pauseFor: pauseFor,
      localeId: localeId,
      onSoundLevelChange: onSoundLevelChange,
      cancelOnError: cancelOnError,
      partialResults: partialResults,
      onDevice: onDevice,
      listenMode: listenMode,
      sampleRate: sampleRate,
    )
        .then((value) {
      onStarted?.call();
    }).catchError((err) {
      throw err;
    });
  }

  void stopListening({Function()? onStopped}) {
    _speech.stop().then((value) {
      onStopped?.call();
    }).catchError((err) {
      throw err;
    });
  }

  void cancelListening({Function()? onCanceled}) {
    _speech.cancel().then((value) {
      onCanceled?.call();
    }).catchError((err) {
      throw err;
    });
  }

  bool get isListening => _speech.isListening;
}
