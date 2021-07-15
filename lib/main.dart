import 'package:flutter/material.dart';
import 'package:voice_and_face_detecting/features/google_ml_vision/google_ml_vision_view.dart';
import 'package:voice_and_face_detecting/features/home_view.dart';
import 'package:voice_and_face_detecting/features/noise_meter_view.dart';
import 'package:voice_and_face_detecting/features/speech_to_text_view.dart';

void main() {
  runApp(
    MaterialApp(
      home: HomeView(),
      debugShowCheckedModeBanner: false,
    ),
  );
}
