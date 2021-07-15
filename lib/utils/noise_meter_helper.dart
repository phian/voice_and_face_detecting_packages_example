import 'dart:async';

import 'package:flutter/services.dart';
import 'package:noise_meter/noise_meter.dart';

class NoiseMeterHelper {
  static NoiseMeterHelper? _instance;

  factory NoiseMeterHelper() {
    _instance ??= NoiseMeterHelper._();
    return _instance!;
  }

  NoiseMeterHelper._();

  late NoiseMeter _noiseMeter = NoiseMeter((err) {});
  StreamSubscription? _noiseSubscription;

  void start({
    required Function(NoiseReading noiseReading) onData,
    required Function(Exception error) onError,
  }) {
    _noiseSubscription = _noiseMeter.noiseStream.listen((noiseReading) {
      onData.call(noiseReading);
    });
    _noiseSubscription?.onError((err) {
      onError.call(err);
    });
  }

  void stop() {
    _noiseSubscription?.cancel();
    _noiseSubscription = null;
  }
}
