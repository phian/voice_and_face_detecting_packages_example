import 'package:flutter/material.dart';
import 'package:voice_and_face_detecting/constants/app_constants.dart';
import 'package:voice_and_face_detecting/features/google_ml_vision/views/camera_preview_scanner.dart';
import 'package:voice_and_face_detecting/features/google_ml_vision/views/material_barcode_scanner.dart';
import 'package:voice_and_face_detecting/features/google_ml_vision/views/picture_scanner.dart';

extension GoogleMLViewTypeExtensions on GoogleMLVisionViewType {
  Widget getGoogleMLVisionView() {
    switch(this) {
      case GoogleMLVisionViewType.barcodeScanner:
        return MaterialBarcodeScanner();
      case GoogleMLVisionViewType.cameraScanner:
        return CameraPreviewScanner();
      case GoogleMLVisionViewType.pictureScanner:
        return PictureScanner();
    }
  }

  String getGoogleMLVisionTypeText() {
    switch(this) {
      case GoogleMLVisionViewType.barcodeScanner:
        return AppConstants.googleMLVisionTypes[0];
      case GoogleMLVisionViewType.cameraScanner:
        return AppConstants.googleMLVisionTypes[1];
      case GoogleMLVisionViewType.pictureScanner:
        return AppConstants.googleMLVisionTypes[2];
    }
  }
}