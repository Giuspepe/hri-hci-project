import 'dart:convert';
import 'dart:io';

import 'package:app/services/api-keys.dart';
import 'package:app/services/emotion_detection_interface.dart';
import 'package:camera/src/camera_image.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;

class EmotionDetectionApi implements EmotionDetectionInterface {
  @override
  Future<List<EmotionDetectionResult>> predictFromCameraStream(
      CameraImage image) {
    // TODO: implement predictFromCameraStream
    throw UnimplementedError();
  }

  @override
  Future<List<EmotionDetectionResult>> predictFromImage(File imageFile) async {
    var uri = Uri.parse('https://api.luxand.cloud/photo/emotions');
    var request = http.MultipartRequest('POST', uri);

    // Add file to request
    var file = await http.MultipartFile.fromPath(
      'photo', // Replace with the field name expected by the server
      imageFile.path,
      filename: path.basename(imageFile.path),
    );
    request.files.add(file);

    request.headers.addAll({'token': faceKey});
    final response = await request.send();

    var responseBytes = await response.stream.toBytes();
    var responseString = String.fromCharCodes(responseBytes);
    final data = jsonDecode(responseString) as Map;

    final result = data['faces'].cast<Map<String, dynamic>>()
        .map(EmotionDetectionResult.fromJson)
        .toList().cast<EmotionDetectionResult>();

    return result;
  }
}
