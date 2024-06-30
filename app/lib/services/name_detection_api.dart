import 'dart:convert';
import 'dart:io';

import 'package:app/services/api-keys.dart';
import 'package:app/services/emotion_detection_interface.dart';
import 'package:camera/src/camera_image.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import 'package:app/services/name_detection_interface.dart';

class NameDetectionApi implements NameDetectionInterface {
  @override
  Future<List<NameDetectionResult>> predictFromCameraStream(
      CameraImage image) async {
    // TODO: implement predictFromCameraStream
    throw UnimplementedError();
  }

  @override
  Future<List<NameDetectionResult>> predictFromImage(File imageFile) async {
    var uri = Uri.parse('https://api.luxand.cloud/photo/search/v2');
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
    final data = jsonDecode(responseString) as List;

    final result = data
        .cast<Map<String, dynamic>>()
        .map(NameDetectionResult.fromJson)
        .toList()
        .cast<NameDetectionResult>();

    return result;
  }

  @override
  Future<void> registerPerson(String name, File imageFile) async {
    var uri = Uri.parse('https://api.luxand.cloud/v2/person');
    var request = http.MultipartRequest('POST', uri);

    // Add file to request
    var file = await http.MultipartFile.fromPath(
      'photos', // Replace with the field name expected by the server
      imageFile.path,
      filename: path.basename(imageFile.path),
    );
    request.files.add(file);
    request.fields.addAll({'name': name});

    request.headers.addAll({'token': faceKey});
    await request.send();

    return;
  }
}
