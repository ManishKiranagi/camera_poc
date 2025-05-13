import 'dart:io';

import 'package:camera_poc/camera_page.dart';
import 'package:camera_poc/video_preview.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) {
                          return const CameraPage(
                            savedVideoFileName: 'my_video_file.mp4',
                          );
                        },
                      ));
                    },
                    child: const Text('Shoot video'),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) {
                          return const VideoPreviewScreen(
                            asset: 'my_video_file.mp4',
                          );
                        },
                      ));
                    },
                    child: const Text('Show video'),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await deleteSavedVideo('my_video_file.mp4');
                    },
                    child: const Text('Delete video'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> deleteSavedVideo(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/$fileName';
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
