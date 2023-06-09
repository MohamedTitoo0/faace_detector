import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image/image.dart' as im;
import 'package:learning_input_image/learning_input_image.dart';
import 'package:learning_face_detection/learning_face_detection.dart';
import 'package:provider/provider.dart';

class LearningFaceDetection extends StatefulWidget {
  @override
  _LearningFaceDetectionState createState() => _LearningFaceDetectionState();
}

class _LearningFaceDetectionState extends State<LearningFaceDetection> {
  LearningFaceDetectionState get state =>
      Provider.of<LearningFaceDetectionState>(context, listen: false);

  FaceDetector _detector = FaceDetector(
    mode: FaceDetectorMode.accurate,
    detectLandmark: true,
    detectContour: true,
    enableClassification: true,
    enableTracking: true,
  );

  @override
  void dispose() {
    _detector.dispose();
    super.dispose();
  }

  Future<void> _detectFaces(InputImage image) async {
    if (state.isNotProcessing) {
      state.startProcessing();
      state.image = image;
      state.data = await _detector.detect(image);

      // Extract RGB values from the detected face
      if (state.data.isNotEmpty) {
        final Face face = state.data[0];
        InputImageData imageData = image.metadata!;
        Uint8List bytes = image.bytes!;
         int bytesPerPixel = 0;
         int bytesPerRow = 0;
        final int x = face.boundingBox.left.toInt();
        final int y = face.boundingBox.top.toInt();
        final int width = face.boundingBox.width.toInt();
        final int height = face.boundingBox.height.toInt();

        final int redIndex = y * bytesPerRow + x * bytesPerPixel;
        final int greenIndex = redIndex + 1;
        final int blueIndex = redIndex + 2;

        final int red = bytes[redIndex];
        final int green = bytes[greenIndex];
        final int blue = bytes[blueIndex];

        // Update the state with the RGB values
        state.rgb = 'R: $red, G: $green, B: $blue';
        double gray = (0.2989 * red) + (0.5870 * green) + (0.1140 * blue);

        // Estimate heart rate based on changes in grayscale value over time
        // This is a very crude estimate and is not reliable
        double heartRate = gray / 10.0;
state.heartRate=heartRate.toString();
      } else {
        state.rgb = '';
      }

      state.stopProcessing();
    }
  }

  @override
  Widget build(BuildContext context) {
    return InputCameraView(
      title: 'Face Detection',
      onImage: _detectFaces,
      overlay: Consumer<LearningFaceDetectionState>(
        builder: (_, state, __) {
          if (state.isEmpty) {
            return Container();
          }

          Size originalSize = state.size!;
          Size size = MediaQuery.of(context).size;

          // if image source from gallery
          // image display size is scaled to 360x360 with retaining aspect ratio
          if (state.notFromLive) {
            if (originalSize.aspectRatio > 1) {
              size = Size(360.0, 360.0 / originalSize.aspectRatio);
            } else {
              size = Size(360.0 * originalSize.aspectRatio, 360.0);
            }
          }

          return Stack(
            children: [
              FaceOverlay(
                size: size,
                originalSize: originalSize,
                rotation: state.rotation,
                faces: state.data,
                contourColor: Colors.white.withOpacity(0.8),
                landmarkColor: Colors.lightBlue.withOpacity(0.8),
              ),
              if (state.rgb.isNotEmpty)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Text(
                    state.rgb,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              if (state.heartRate.isNotEmpty)
                Positioned(
                  top: 32,
                  left: 16,
                  child: Text(
                    state.heartRate,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class LearningFaceDetectionState extends ChangeNotifier {
  InputImage? _image;
  List<Face> _data = [];
  bool _isProcessing = false;
  String _rgb = '';
  String _heartRate = '';

  InputImage? get image => _image;
  List<Face> get data => _data;
  String get rgb => _rgb;
  String get heartRate => _heartRate;

  String? get type => _image?.type;
  InputImageRotation? get rotation => _image?.metadata?.rotation;
  Size? get size => _image?.metadata?.size;

  bool get isNotProcessing => !_isProcessing;
  bool get isEmpty => data.isEmpty;
  bool get isFromLive => type == 'bytes';
  bool get notFromLive => !isFromLive;

  void startProcessing() {
    _isProcessing = true;
    notifyListeners();
  }

  void stopProcessing() {
    _isProcessing = false;
    notifyListeners();
  }

  set image(InputImage? image) {
    _image = image;

    if (notFromLive) {
      _data = [];
    }
    notifyListeners();
  }

  set data(List<Face> data) {
    _data = data;
    notifyListeners();
  }

  set rgb(String rgb) {
    _rgb = rgb;
    notifyListeners();
  }

  set heartRate(String rate) {
    _heartRate = rate;
    notifyListeners();
  }
}