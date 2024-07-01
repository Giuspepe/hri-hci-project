const faceKey = String.fromEnvironment('FACE_KEY');
const openAIKey = String.fromEnvironment('OPENAI_KEY');


void checkKeys() {
  if (faceKey.isEmpty) {
    throw AssertionError('FACE_KEY is not set');
  }
  if(openAIKey.isEmpty) {
    throw AssertionError('OPENAI_KEY is not set');
  }
}
