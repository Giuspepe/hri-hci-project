import 'dart:async';

import 'package:app/providers/emotion_detection_result_provider.dart';
import 'package:app/providers/name_detection_result_provider.dart';
import 'package:app/screens/live_chat_screen.dart';
import 'package:app/services/chatbot_service.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intersperse/intersperse.dart';

class ChatBot extends ConsumerStatefulWidget {
  @override
  _ChatBotState createState() => _ChatBotState();
}

class _ChatBotState extends ConsumerState<ChatBot> {
  final TextEditingController _controller = TextEditingController();
  final List<OpenAIChatCompletionChoiceMessageModel> _messages = [];
  final List<Duration> _responseTimes = [];

  final AiClient _aiClient = AiClient();

  bool _isPending = false;

  late final _scrollController = ref.watch(chatScrollControllerProvider);

  Future<void> _sendMessage() async {
    final prompt = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(_controller.text)
      ],
      role: OpenAIChatMessageRole.user,
    );
    setState(() {
      _messages.add(prompt);
      _controller.clear();
      _isPending = true;
    });
    _scrollController.animateTo(0,
        duration: Duration(milliseconds: 200), curve: Curves.easeInOutCubic);

    final emotions = ref.read(emotionDetectionResultProvider).valueOrNull;
    final names = ref.read(nameDetectionResultProvider).valueOrNull;

    final systemPromptMessage = '''
You, ChatGPT, will act as a therapist. You're given a conversation between a user and you, the therapist. 
You should provide a thoughtful and empathetic response to the user's messages.

Furthermore, you have the following information about the user:
- Name - ${names?.firstOrNull?.name ?? 'Unknown'} 
- Current emotions estimate - ${emotions?.first.emotion.mapEntries((e) => '${e.key}: ${e.value.toStringAsFixed(2)}').join(', ')}

If the name is unknown, do not ask the user for it! Only if it is known, refer to them by name.

The conversation between user and therapist (you) is as follows:
''';
    final systemPrompt = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
            systemPromptMessage)
      ],
      role: OpenAIChatMessageRole.user,
    );

    final watch = Stopwatch()..start();

    final response = await _aiClient.sendMessage([systemPrompt, ..._messages]);
    watch.stop();
    _responseTimes.add(watch.elapsed);
    final elapsedTimeMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
            'Response took ${watch.elapsedMilliseconds} ms')
      ],
      role: OpenAIChatMessageRole.system,
    );
    setState(() {
      _messages.add(elapsedTimeMessage);
      _messages.add(response);
      _isPending = false;
    });

    _scrollController.animateTo(0,
        duration: Duration(milliseconds: 200), curve: Curves.easeInOutCubic);
    _speak(response.content!.first.text!);
  }

  Duration get _averageResponseTime {
    if (_responseTimes.isEmpty) return Duration.zero;
    final avg = _responseTimes.averageBy((element) => element.inMilliseconds);
    return Duration(milliseconds: avg.round());
  }

  Future<void> _speak(String text) async {
    final _flutterTts = FlutterTts();
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.52);
    await _flutterTts.setVolume(0.2);
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Card(
            color: Colors.black12.withOpacity(0.8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            elevation: 5,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 24.0),
                Row(
                  children: [
                    Flexible(
                      child: Center(
                        child: Text(
                          'GPT Chatbot',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '~ ${_averageResponseTime.inMilliseconds} ms',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24.0),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                        verticalDirection: VerticalDirection.up,
                        children: [
                          ..._messages.reversed.mapIndexed(
                            (index, messageModel) {
                              final message =
                                  messageModel.content?.first.text ?? '';
                              final isAi = messageModel.role !=
                                  OpenAIChatMessageRole.user;
                              final avatar = CircleAvatar(
                                radius: 20,
                                backgroundColor:
                                    Theme.of(context).colorScheme.tertiary,
                                foregroundColor: Colors.white,
                                child: !isAi
                                    ? Icon(Icons.person)
                                    : Icon(Icons.chat),
                              );
                              return Align(
                                alignment: isAi
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: isAi
                                        ? Theme.of(context)
                                            .colorScheme
                                            .secondary
                                        : Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isAi) avatar,
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 5.0, horizontal: 10.0),
                                          child: ConstrainedBox(
                                            constraints:
                                                BoxConstraints(maxWidth: 200),
                                            child: Text(
                                              messageModel.content!.first.text!,
                                              textAlign: isAi
                                                  ? TextAlign.start
                                                  : TextAlign.end,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (!isAi) avatar,
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (_isPending)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                '...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                ),
                              ),
                            )
                        ].intersperse(SizedBox(height: 12)).toList()),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Row(
            children: [
              Flexible(
                child: TextField(
                  controller: _controller,
                  style: TextStyle(color: Colors.white),
                  onSubmitted: (prompt) async {
                    _sendMessage();
                  },
                  decoration: InputDecoration(
                    hintText: 'Type your message',
                    hintStyle: TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Colors.black12.withOpacity(0.8),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.secondary,
                        width: 2.0,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: () {
                  _sendMessage();
                },
                color: Theme.of(context).colorScheme.secondary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
