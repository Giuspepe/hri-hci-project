import 'package:app/services/emotion_detection_interface.dart';
import 'package:app/services/emotion_detection_service.dart';
import 'package:app/services/name_detection_interface.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

class NamePredictionInformation extends StatelessWidget {
  final List<NameDetectionResult> predictions;

  NamePredictionInformation({required this.predictions});

  @override
  Widget build(BuildContext context) {
    if (predictions.isEmpty) {
      return Text('No names detected', style: TextStyle(color: Colors.black));
    }

    final colorMap = generateColorMap(predictions.length);
    return Container(
        color: Colors.black54,
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Names:',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            ...predictions.mapIndexed<Widget>((index, predictedName) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  '${predictedName.name} (${(predictedName.probability * 100).toStringAsFixed(2)}%)',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.white,
                    fontSize: 16,
                  ),
                )))
          ],
        ));
  }
}

List<Color> generateColorMap(int numColors) {
  List<Color> colors = [];
  double hueStep = 360.0 / numColors;

  for (int i = 0; i < numColors; i++) {
    double hue = (i * hueStep) % 360;
    colors.add(HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor());
  }

  return colors;
}
