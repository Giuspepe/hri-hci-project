import 'package:app/services/api_keys.dart';
import 'package:dart_openai/dart_openai.dart';

class AiClient {
  AiClient() {
    OpenAI.apiKey = openAIKey;
  }

  Future<OpenAIChatCompletionChoiceMessageModel> sendMessage(
      List<OpenAIChatCompletionChoiceMessageModel> messages) async {
    try {
      final response = await OpenAI.instance.chat.create(
        model: 'gpt-3.5-turbo',
        messages: messages
            .where((it) => it.role != OpenAIChatMessageRole.system)
            .toList(),
      );
      final first = response.choices.first;
      return first.message;
    } catch (e) {
      return OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.system,
        content: [OpenAIChatCompletionChoiceMessageContentItemModel.text('$e')]
      );
    }
  }
}
