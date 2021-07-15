import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:voice_and_face_detecting/utils/noise_meter_helper.dart';

class NoiseMeterView extends StatefulWidget {
  const NoiseMeterView({Key? key}) : super(key: key);

  @override
  _NoiseMeterViewState createState() => _NoiseMeterViewState();
}

class _NoiseMeterViewState extends State<NoiseMeterView> {
  bool _isRecording = false;
  NoiseReading _noiseReading = NoiseReading([0]);

  @override
  void dispose() {
    NoiseMeterHelper().stop();
    super.dispose();
  }

  void onData(NoiseReading noiseReading) {
    setState(() {
      _noiseReading = noiseReading;
      if (!_isRecording) {
        _isRecording = true;
      }
    });
    print(noiseReading.toString());
  }

  void onError(Exception e) {
    print(e.toString());
    _isRecording = false;
  }

  List<Widget> getContent() => <Widget>[
        Container(
          margin: EdgeInsets.all(25),
          child: Column(
            children: [
              Container(
                child: Text(
                  _isRecording ? "Mic: ON" : "Mic: OFF",
                  style: TextStyle(fontSize: 25, color: Colors.blue),
                ),
                margin: EdgeInsets.only(top: 20),
              ),
              Container(
                child: Text(
                  _isRecording ? _noiseReading.toString() : "0 db",
                  style: TextStyle(fontSize: 25, color: Colors.blue),
                ),
                margin: EdgeInsets.only(top: 40),
              ),
            ],
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: getContent(),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: _isRecording ? Colors.red : Colors.green,
          onPressed: () {
            setState(() {
              _isRecording = !_isRecording;

              if (_isRecording) {
                NoiseMeterHelper().start(
                  onData: onData,
                  onError: onError,
                );
              } else {
                NoiseMeterHelper().stop();
              }
            });
          },
          child: _isRecording ? Icon(Icons.stop) : Icon(Icons.mic),
        ),
      ),
    );
  }
}
