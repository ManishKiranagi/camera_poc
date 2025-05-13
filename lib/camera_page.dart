import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:camera_poc/services/camera_service.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

import 'package:photo_manager/photo_manager.dart';

class CameraPage extends StatefulWidget {
  final String? savedVideoFileName;
  const CameraPage({super.key, this.savedVideoFileName});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? cameraController;
  final int _recordDuration = 7;
  double _progress = 0.0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _setUpCameraController();
  }

  @override
  Widget build(BuildContext context) {
    if (cameraController == null || (cameraController?.value.isInitialized == false)) {
      return const Center(child: CircularProgressIndicator());
    } else {
      return Stack(children: [
        CameraPreview(cameraController!),
        Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 8,
            backgroundColor: Colors.black26,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
          ),
        ),
      ]);
    }
  }

  Future<void> _setUpCameraController() async {
    final cameraService = CameraService();

    try {
      await cameraService.initialize();
      if (!mounted) return;

      cameraController = cameraService.controller;
      setState(() {});
      _startRecordingWithProgress();
    } catch (e) {
      // Handle init errors (e.g. show message to user)
      debugPrint('Camera initialization failed: $e');
    }
  }

  void _startRecordingWithProgress() async {
    await cameraController!.startVideoRecording();

    int ticks = 0;
    const interval = Duration(milliseconds: 100);
    int totalTicks = _recordDuration * 10;

    _progressTimer = Timer.periodic(interval, (timer) async {
      setState(() {
        _progress = ++ticks / totalTicks;
      });

      if (ticks >= totalTicks) {
        timer.cancel();
        final videoFile = await cameraController!.stopVideoRecording();
        final renamedFile = await _renameRecordedVideo(
            videoFile, widget.savedVideoFileName ?? 'camera_poc_${DateTime.now().toIso8601String()}');
        //await Gal.putVideo(renamedFile.path);

        //store in app directory
        // delete temp files
        //store file name in shared pref

        //Delete the temp file to clear cache
        // final file = File(videoFile.path);
        // if (await file.exists()) {
        //   await file.delete();
        // }

        // if (await renamedFile.exists()) {
        //   await renamedFile.delete();
        // }
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    cameraController?.dispose();
    super.dispose();
  }

  Future<File> _renameRecordedVideo(XFile originalVideo, String newFileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final newPath = '${directory.path}/$newFileName';

    // Copy with new name
    final renamedFile = await File(originalVideo.path).copy(newPath);

    // Delete original temp file
    await File(originalVideo.path).delete();

    return renamedFile;
  }

  Future<AssetEntity?> findSavedVideoByName(String fileName) async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) return null;

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.video,
      filterOption: FilterOptionGroup(
        orders: [OrderOption(type: OrderOptionType.createDate, asc: false)],
      ),
    );

    for (final album in albums) {
      final assets = await album.getAssetListPaged(page: 0, size: 100);
      for (final asset in assets) {
        final file = await asset.file;
        if (file != null && file.path.endsWith(fileName)) {
          return asset; // 🎯 Found the video
        }
      }
    }
    return null; // Not found
  }

  Future<File> persistRecordedVideo(XFile recordedVideo, String fileName) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final newPath = '${appDocDir.path}/$fileName';

    final newFile = await File(recordedVideo.path).copy(newPath);
    await File(recordedVideo.path).delete(); // clean up cache

    return newFile;
  }
}
