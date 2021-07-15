import 'dart:async';
import 'dart:io';
import 'dart:ui' show lerpDouble;

import 'package:camera/camera.dart';
import 'package:google_ml_vision/google_ml_vision.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voice_and_face_detecting/constants/app_colors.dart';
import 'package:voice_and_face_detecting/features/google_ml_vision/models/rectangle.dart';
import 'package:voice_and_face_detecting/features/google_ml_vision/models/rectangle_tween.dart';
import 'package:voice_and_face_detecting/features/google_ml_vision/widgets/rectangle_outline_painter.dart';
import 'package:voice_and_face_detecting/features/google_ml_vision/widgets/rectangle_trace_painter.dart';
import 'package:voice_and_face_detecting/features/google_ml_vision/widgets/window_painter.dart';

import '../scanner_utils.dart';

enum AnimationState { search, barcodeNear, barcodeFound, endSearch }

class MaterialBarcodeScanner extends StatefulWidget {
  const MaterialBarcodeScanner({
    Key? key,
    this.validRectangle = const Rectangle(width: 320, height: 144),
    this.frameColor = kShrineScrim,
    this.traceMultiplier = 1.2,
  }) : super(key: key);

  final Rectangle validRectangle;
  final Color frameColor;
  final double traceMultiplier;

  @override
  _MaterialBarcodeScannerState createState() => _MaterialBarcodeScannerState();
}

class _MaterialBarcodeScannerState extends State<MaterialBarcodeScanner>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  late AnimationController _animationController;
  String? _scannerHint;
  bool _closeWindow = false;
  XFile? _barcodePictureFile;
  Size? _previewSize;
  AnimationState _currentState = AnimationState.search;
  CustomPainter? _animationPainter;
  int _animationStart = DateTime.now().millisecondsSinceEpoch;
  final BarcodeDetector _barcodeDetector =
      GoogleVision.instance.barcodeDetector();

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIOverlays(<SystemUiOverlay>[]);
    SystemChrome.setPreferredOrientations(
      <DeviceOrientation>[DeviceOrientation.portraitUp],
    );
    _initCameraAndScanner();
    _switchAnimationState(AnimationState.search);
  }

  void _initCameraAndScanner() {
    ScannerUtils.getCamera(CameraLensDirection.back).then(
      (CameraDescription camera) async {
        await _openCamera(camera);
        await _startStreamingImagesToScanner(camera.sensorOrientation);
      },
    );
  }

  void _initAnimation(Duration duration) {
    setState(() {
      _animationPainter = null;
    });

    _animationController.dispose();
    _animationController = AnimationController(duration: duration, vsync: this);
  }

  void _switchAnimationState(AnimationState newState) {
    if (newState == AnimationState.search) {
      _initAnimation(const Duration(milliseconds: 750));

      _animationPainter = RectangleOutlinePainter(
        animation: RectangleTween(
          Rectangle(
            width: widget.validRectangle.width,
            height: widget.validRectangle.height,
            color: Colors.white,
          ),
          Rectangle(
            width: widget.validRectangle.width! * widget.traceMultiplier,
            height: widget.validRectangle.height! * widget.traceMultiplier,
            color: Colors.transparent,
          ),
        ).animate(_animationController),
      );

      _animationController.addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          Future<void>.delayed(const Duration(milliseconds: 1600), () {
            if (_currentState == AnimationState.search) {
              _animationController.forward(from: 0);
            }
          });
        }
      });
    } else if (newState == AnimationState.barcodeNear ||
        newState == AnimationState.barcodeFound ||
        newState == AnimationState.endSearch) {
      double? begin;
      if (_currentState == AnimationState.barcodeNear) {
        begin = lerpDouble(0.0, 0.5, _animationController.value);
      } else if (_currentState == AnimationState.search) {
        _initAnimation(const Duration(milliseconds: 500));
        begin = 0.0;
      }

      _animationPainter = RectangleTracePainter(
        rectangle: Rectangle(
          width: widget.validRectangle.width,
          height: widget.validRectangle.height,
          color: newState == AnimationState.endSearch
              ? Colors.transparent
              : Colors.white,
        ),
        animation: Tween<double>(
          begin: begin,
          end: newState == AnimationState.barcodeNear ? 0.5 : 1.0,
        ).animate(_animationController),
      );

      if (newState == AnimationState.barcodeFound) {
        _animationController.addStatusListener((AnimationStatus status) {
          if (status == AnimationStatus.completed) {
            Future<void>.delayed(const Duration(milliseconds: 300), () {
              if (_currentState != AnimationState.endSearch) {
                _switchAnimationState(AnimationState.endSearch);
                setState(() {});
                _showBottomSheet();
              }
            });
          }
        });
      }
    }

    _currentState = newState;
    if (newState != AnimationState.endSearch) {
      _animationController.forward(from: 0);
      _animationStart = DateTime.now().millisecondsSinceEpoch;
    }
  }

  Future<void> _openCamera(CameraDescription camera) async {
    final ResolutionPreset preset =
        defaultTargetPlatform == TargetPlatform.android
            ? ResolutionPreset.medium
            : ResolutionPreset.low;

    _cameraController = CameraController(camera, preset, enableAudio: false);
    await _cameraController?.initialize();
    _previewSize = _cameraController?.value.previewSize;
    setState(() {});
  }

  Future<void> _startStreamingImagesToScanner(int sensorOrientation) async {
    bool isDetecting = false;
    final MediaQueryData data = MediaQuery.of(context);

    await _cameraController?.startImageStream((CameraImage image) {
      if (isDetecting) {
        return;
      }

      isDetecting = true;

      ScannerUtils.detect(
        image: image,
        detectInImage: _barcodeDetector.detectInImage,
        imageRotation: sensorOrientation,
      ).then(
        (dynamic result) {
          _handleResult(
            barcodes: result,
            data: data,
            imageSize: Size(image.width.toDouble(), image.height.toDouble()),
          );
        },
      ).whenComplete(() => isDetecting = false);
    });
  }

  bool get _barcodeNearAnimationInProgress {
    return _currentState == AnimationState.barcodeNear &&
        DateTime.now().millisecondsSinceEpoch - _animationStart < 2500;
  }

  void _handleResult({
    required List<Barcode> barcodes,
    required MediaQueryData data,
    required Size imageSize,
  }) {
    if (_cameraController == null) {
      return;
    }

    if (!_cameraController!.value.isStreamingImages) {
      return;
    }

    final EdgeInsets padding = data.padding;
    final double maxLogicalHeight =
        data.size.height - padding.top - padding.bottom;

    // Width & height are flipped from CameraController.previewSize on iOS
    final double imageHeight = defaultTargetPlatform == TargetPlatform.iOS
        ? imageSize.height
        : imageSize.width;

    final double imageScale = imageHeight / maxLogicalHeight;
    final double halfWidth = imageScale * widget.validRectangle.width! / 2;
    final double halfHeight = imageScale * widget.validRectangle.height! / 2;

    final Offset center = imageSize.center(Offset.zero);
    final Rect validRect = Rect.fromLTRB(
      center.dx - halfWidth,
      center.dy - halfHeight,
      center.dx + halfWidth,
      center.dy + halfHeight,
    );

    for (final Barcode barcode in barcodes) {
      if (barcode.boundingBox != null) {
        final Rect intersection = validRect.intersect(barcode.boundingBox!);

        final bool doesContain = intersection == barcode.boundingBox;

        if (doesContain) {
          _cameraController?.stopImageStream().then((_) => _takePicture());

          if (_currentState != AnimationState.barcodeFound) {
            _closeWindow = true;
            _scannerHint = 'Loading Information...';
            _switchAnimationState(AnimationState.barcodeFound);
            setState(() {});
          }
          return;
        } else if (barcode.boundingBox!.overlaps(validRect)) {
          if (_currentState != AnimationState.barcodeNear) {
            _scannerHint = 'Move closer to the barcode';
            _switchAnimationState(AnimationState.barcodeNear);
            setState(() {});
          }
          return;
        }
      }
    }

    if (_barcodeNearAnimationInProgress) {
      return;
    }

    if (_currentState != AnimationState.search) {
      _scannerHint = null;
      _switchAnimationState(AnimationState.search);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _currentState = AnimationState.endSearch;
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _animationController?.dispose();
    _barcodeDetector.close();

    SystemChrome.setPreferredOrientations(<DeviceOrientation>[]);
    SystemChrome.setEnabledSystemUIOverlays(<SystemUiOverlay>[
      SystemUiOverlay.top,
      SystemUiOverlay.bottom,
    ]);

    super.dispose();
  }

  Future<void> _takePicture() async {
    final Directory extDir = await getApplicationDocumentsDirectory();

    final String dirPath = '${extDir.path}/Pictures/barcodePics';
    await Directory(dirPath).create(recursive: true);

    XFile? pictureFile;
    try {
      pictureFile = await _cameraController?.takePicture();
    } on CameraException catch (e) {
      print(e);
    }

    await _cameraController?.dispose();
    _cameraController = null;

    setState(() {
      _barcodePictureFile = pictureFile;
    });
  }

  Widget _buildCameraPreview() {
    return Container(
      color: Colors.black,
      child: Transform.scale(
        scale: _getImageZoom(MediaQuery.of(context)),
        child: Center(
          child: AspectRatio(
            aspectRatio: _cameraController?.value.aspectRatio ?? 0.0,
            child: CameraPreview(_cameraController!),
          ),
        ),
      ),
    );
  }

  double _getImageZoom(MediaQueryData data) {
    final double logicalWidth = data.size.width;
    final double logicalHeight = _previewSize!.aspectRatio * logicalWidth;

    final EdgeInsets padding = data.padding;
    final double maxLogicalHeight =
        data.size.height - padding.top - padding.bottom;

    return maxLogicalHeight / logicalHeight;
  }

  void _showBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          width: double.infinity,
          height: 368,
          child: Column(
            children: <Widget>[
              Container(
                height: 56,
                alignment: Alignment.centerLeft,
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '1 result found',
                    // TODO(bmparr): Switch body2 -> bodyText1 once https://github.com/flutter/flutter/pull/48547 makes it to stable.
                    // ignore: deprecated_member_use
                    style: Theme.of(context).textTheme.body2,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Image.asset(
                            'assets/span_book.jpg',
                            fit: BoxFit.cover,
                            width: 96,
                            height: 96,
                          ),
                          Container(
                            height: 96,
                            margin: const EdgeInsets.only(left: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    'SPAN Reader',
                                    // TODO(bmparr): Switch body2 -> bodyText1 once https://github.com/flutter/flutter/pull/48547 makes it to stable.
                                    // ignore: deprecated_member_use
                                    style: Theme.of(context).textTheme.body2,
                                  ),
                                ),
                                Text(
                                  'Vol. 2',
                                  // TODO(bmparr): Switch body2 -> bodyText1 once https://github.com/flutter/flutter/pull/48547 makes it to stable.
                                  // ignore: deprecated_member_use
                                  style: Theme.of(context).textTheme.body2,
                                ),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 3),
                                        child: const Text('Material Design'),
                                      ),
                                      const Text('120 pages'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 30),
                        child: const Text(
                          'A Japanese & English accompaniment to the 2016 SPAN '
                          'conference.',
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.only(bottom: 4),
                          alignment: Alignment.bottomCenter,
                          child: ButtonTheme(
                            minWidth: 312,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                primary: kShrinePink100,
                                elevation: 8,
                                shape: const BeveledRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(7),
                                  ),
                                ),
                              ),
                              label: const Text(r'ADD TO CART - $12.99'),
                              icon: const Icon(Icons.add_shopping_cart),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) => _reset());
  }

  void _reset() {
    _initCameraAndScanner();
    setState(() {
      _closeWindow = false;
      _barcodePictureFile = null;
      _scannerHint = null;
      _switchAnimationState(AnimationState.search);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget background;
    if (_barcodePictureFile != null) {
      background = Container(
        color: Colors.black,
        child: Transform.scale(
          scale: _getImageZoom(MediaQuery.of(context)),
          child: Center(
            child: Image.file(
              File(_barcodePictureFile!.path),
              fit: BoxFit.fitWidth,
            ),
          ),
        ),
      );
    } else if (_cameraController != null &&
        _cameraController!.value.isInitialized) {
      background = _buildCameraPreview();
    } else {
      background = Container(
        color: Colors.black,
      );
    }

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            background,
            Container(
              constraints: const BoxConstraints.expand(),
              child: CustomPaint(
                painter: WindowPainter(
                  windowSize: Size(
                    widget.validRectangle.width!,
                    widget.validRectangle.height!,
                  ),
                  outerFrameColor: widget.frameColor,
                  closeWindow: _closeWindow,
                  innerFrameColor: _currentState == AnimationState.endSearch
                      ? Colors.transparent
                      : kShrineFrameBrown,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Container(
                height: 56,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Colors.black87, Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              right: 0,
              height: 56,
              child: Container(
                color: kShrinePink50,
                child: Center(
                  child: Text(
                    _scannerHint ?? 'Point your camera at a barcode',
                    style: Theme.of(context).textTheme.button,
                  ),
                ),
              ),
            ),
            Container(
              constraints: const BoxConstraints.expand(),
              child: CustomPaint(
                painter: _animationPainter,
              ),
            ),
            AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: <Widget>[
                IconButton(
                  icon: const Icon(
                    Icons.flash_off,
                    color: Colors.white,
                  ),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(
                    Icons.help_outline,
                    color: Colors.white,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
