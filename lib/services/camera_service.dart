import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  late CameraDescription _backCamera;
  CameraController? _controller;
  ResolutionPreset? _chosenPreset;
  Size? _previewSize;

  bool get isInitialized => _controller?.value.isInitialized ?? false;
  CameraController? get controller => _controller;
  Size? get previewSize => _previewSize;
  ResolutionPreset? get preset => _chosenPreset;

  Future<void> initialize() async {
    if (isInitialized) return;

    final cameras = await availableCameras();
    _backCamera = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.back,
    );

    final prefs = await SharedPreferences.getInstance();
    final savedPresetStr = prefs.getString('cameraResolution');

    if (savedPresetStr != null) {
      final savedPreset = ResolutionPreset.values.firstWhere(
        (e) => e.toString() == 'ResolutionPreset.$savedPresetStr',
      );
      final tempController = CameraController(_backCamera, savedPreset, enableAudio: false);
      await tempController.initialize();
      final size = tempController.value.previewSize;

      _controller = tempController;
      _previewSize = size;
      _chosenPreset = savedPreset;
      return;
    }

    // Try to find best suitable preset and use the first valid controller
    await _initializeWithBestPreset(prefs);
  }

  Future<void> _initializeWithBestPreset(SharedPreferences prefs) async {
    final presets = [
      ResolutionPreset.veryHigh,
      ResolutionPreset.high,
      ResolutionPreset.medium,
    ];

    for (final preset in presets) {
      final testController = CameraController(_backCamera, preset, enableAudio: false);
      try {
        await testController.initialize();
        final size = testController.value.previewSize;

        if (size != null && _isFullHDOrLess(size)) {
          // ✅ Use this controller
          _controller = testController;
          _previewSize = size;
          _chosenPreset = preset;

          // Store preset
          await prefs.setString('cameraResolution', preset.toString().split('.').last);
          return;
        } else {
          await testController.dispose(); // too large
        }
      } catch (_) {
        await testController.dispose(); // failed to init
      }
    }

    throw Exception('No suitable resolution ≤ 1080p found.');
  }

  bool _isFullHDOrLess(Size size) {
    final w = size.width;
    final h = size.height;
    return (w <= 1920 && h <= 1080) || (w <= 1080 && h <= 1920); // account for orientation
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    _previewSize = null;
    _chosenPreset = null;
  }
}
