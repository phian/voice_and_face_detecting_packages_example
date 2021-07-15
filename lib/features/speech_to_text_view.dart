import 'dart:math';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:voice_and_face_detecting/utils/speech_to_text_helper.dart';

class SpeechToTextView extends StatefulWidget {
  const SpeechToTextView({Key? key}) : super(key: key);

  @override
  _SpeechToTextViewState createState() => _SpeechToTextViewState();
}

class _SpeechToTextViewState extends State<SpeechToTextView> {
  bool _hasSpeech = false;
  double level = 0.0, minSoundLevel = 50000, maxSoundLevel = -50000;
  String lastWords = '', lastError = '', lastStatus = '', _currentLocaleId = '';
  int resultListened = 0;
  List<LocaleName> _localeNames = [];

  Future<void> initSpeechState() async {
    SpeechToTextHelper().init(
        onError: errorListener,
        onStatus: statusListener,
        debugLogging: true,
        finalTimeout: Duration.zero,
        onSpeechInitialized: (speech, hasSpeech) async {
          if (hasSpeech) {
            _localeNames = await speech!.locales();

            var systemLocale = await speech.systemLocale();
            _currentLocaleId = systemLocale?.localeId ?? '';
          }

          setState(() {
            _hasSpeech = hasSpeech;
          });
        });

    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Speech to Text Example'),
        ),
        body: Column(children: [
          Center(
            child: Text(
              'Speech recognition available',
              style: TextStyle(fontSize: 22.0),
            ),
          ),
          Container(
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    TextButton(
                      onPressed: _hasSpeech ? null : initSpeechState,
                      child: Text('Initialize'),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    TextButton(
                      onPressed: !_hasSpeech || SpeechToTextHelper().isListening
                          ? null
                          : startListening,
                      child: Text('Start'),
                    ),
                    TextButton(
                      onPressed: SpeechToTextHelper().isListening
                          ? stopListening
                          : null,
                      child: Text('Stop'),
                    ),
                    TextButton(
                      onPressed: SpeechToTextHelper().isListening
                          ? cancelListening
                          : null,
                      child: Text('Cancel'),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    DropdownButton(
                      onChanged: (selectedVal) => _switchLang(selectedVal),
                      value: _currentLocaleId,
                      items: _localeNames
                          .map(
                            (localeName) => DropdownMenuItem(
                              value: localeName.localeId,
                              child: Text(localeName.name),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                )
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              children: <Widget>[
                Center(
                  child: Text(
                    'Recognized Words',
                    style: TextStyle(fontSize: 22.0),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: <Widget>[
                      Container(
                        color: Theme.of(context).selectedRowColor,
                        child: Center(
                          child: Text(
                            lastWords,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        bottom: 10,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                    blurRadius: .26,
                                    spreadRadius: level * 1.5,
                                    color: Colors.black.withOpacity(.05))
                              ],
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(50)),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.mic),
                              onPressed: () => null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              children: <Widget>[
                Center(
                  child: Text(
                    'Error Status',
                    style: TextStyle(fontSize: 22.0),
                  ),
                ),
                Center(
                  child: Text(lastError),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 20),
            color: Theme.of(context).backgroundColor,
            child: Center(
              child: SpeechToTextHelper().isListening
                  ? Text(
                      "I'm listening...",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    )
                  : Text(
                      'Not listening',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ]),
      ),
    );
  }

  void startListening() {
    SpeechToTextHelper().startListening(
      onResult: resultListener,
      listenFor: Duration(seconds: 30),
      pauseFor: Duration(seconds: 5),
      partialResults: true,
      localeId: _currentLocaleId,
      onSoundLevelChange: soundLevelListener,
      cancelOnError: true,
      listenMode: ListenMode.confirmation,
      onStarted: () {
        lastWords = '';
        lastError = '';
        setState(() {});
      },
    );
  }

  void stopListening() {
    SpeechToTextHelper().stopListening(onStopped: () {
      setState(() {
        level = 0.0;
      });
    });
  }

  void cancelListening() {
    SpeechToTextHelper().cancelListening(onCanceled: () {
      setState(() {
        level = 0.0;
      });
    });
  }

  void resultListener(SpeechRecognitionResult result) {
    ++resultListened;
    print('Result listener $resultListened');
    setState(() {
      lastWords = '${result.recognizedWords} - ${result.finalResult}';
    });
  }

  void soundLevelListener(double level) {
    minSoundLevel = min(minSoundLevel, level);
    maxSoundLevel = max(maxSoundLevel, level);
    setState(() {
      this.level = level;
    });
  }

  void errorListener(SpeechRecognitionError error) {
    setState(() {
      lastError = '${error.errorMsg} - ${error.permanent}';
    });
  }

  void statusListener(String status) {
    setState(() {
      lastStatus = '$status';
    });
  }

  void _switchLang(selectedVal) {
    setState(() {
      _currentLocaleId = selectedVal;
    });
    print(selectedVal);
  }
}
