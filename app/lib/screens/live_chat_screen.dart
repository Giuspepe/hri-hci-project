import 'package:app/providers/emotion_detection_result_provider.dart';
import 'package:app/providers/name_detection_result_provider.dart';
import 'package:app/widgets/chatbot.dart';
import 'package:app/widgets/name_prediction_information.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/model_provider.dart';
import '../widgets/emotion_prediction_information.dart';

final chatScrollControllerProvider = Provider<ScrollController>((ref) {
  final controller = ScrollController();
  ref.onDispose(controller.dispose);
  return controller;
});

class LiveChatScreen extends ConsumerWidget {
  const LiveChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Name & Emotion Detection'),
        actions: [
          IconButton(
            icon: Icon(Icons.switch_camera),
            onPressed: () =>
                ref.read(_cameraControllerProvider.notifier).switchCamera(),
          ),
        ],
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Flexible(child: VideoFeed()),
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Consumer(builder: (context, ref, _) {
                      final detectedNames =
                          ref.watch(nameDetectionResultProvider);
                      return Center(
                        child: NamePredictionInformation(
                            predictions: detectedNames.valueOrNull ?? []),
                      );
                    }),
                    Consumer(builder: (context, ref, _) {
                      final predictions =
                          ref.watch(emotionDetectionResultProvider);
                      return Center(
                        child: EmotionPredictionInformation(
                            predictions: predictions.valueOrNull ?? []),
                      );
                    }),
                  ],
                ),
              )
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: ref.watch(chatScrollControllerProvider),
              child: ChatBot(),
            ),
          ),
        ],
      ),
    );
  }
}

class VideoFeed extends ConsumerStatefulWidget {
  @override
  _VideoFeedState createState() => _VideoFeedState();
}

class _VideoFeedState extends ConsumerState<VideoFeed> {
  @override
  Widget build(BuildContext context) {
    final _controller = ref.watch(_cameraControllerProvider).value;
    return (_controller?.value.isInitialized ?? false)
        ? CameraPreview(_controller!)
        : const Center(child: CircularProgressIndicator());
  }
}

final _cameraControllerProvider = AsyncNotifierProvider.autoDispose<
    _CameraControllerNotifier, CameraController?>(
  () => _CameraControllerNotifier(),
);

class _CameraControllerNotifier
    extends AutoDisposeAsyncNotifier<CameraController?> {
  List<CameraDescription> _cameras = [];
  CameraDescription? _selectedCamera;

  @override
  Future<CameraController?> build() async {
    _cameras = await availableCameras();
    print('Warning: There are no cameras available');
    if (_cameras.isEmpty) return null;

    _selectedCamera = _cameras.first;
    final controller =
        CameraController(_selectedCamera!, ResolutionPreset.high);
    await controller.initialize();
    await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
    if (!controller.value.isStreamingImages) {
      controller.startImageStream((CameraImage image) {
        ref
            .read(nameDetectionResultProvider.notifier)
            .predictCameraStream(image);
        ref
            .read(emotionDetectionResultProvider.notifier)
            .predictCameraStream(image);
      });
    }

    ref.onDispose(controller.dispose);

    return controller;
  }

  Future<void> switchCamera() async {
    if (_cameras.isNotEmpty) {
      state = const AsyncValue.loading();
      _selectedCamera =
          (_selectedCamera == _cameras.first) ? _cameras.last : _cameras.first;
      final controller =
          CameraController(_selectedCamera!, ResolutionPreset.high);
      await controller.initialize();
      if (!controller.value.isStreamingImages) {
        controller.startImageStream((CameraImage image)  {
                      ref
            .read(nameDetectionResultProvider.notifier)
            .predictCameraStream(image);
           ref
              .read(emotionDetectionResultProvider.notifier)
              .predictCameraStream(image);

        });
      }

      ref.onDispose(controller.dispose);
      state = AsyncValue.data(controller);
    }
  }
}
