import 'package:http/http.dart';

class RocketChatException implements Exception {
  String message;

  RocketChatException(this.message);

  RocketChatException.fromResponse(BaseResponse response)
      : message = '${response.statusCode} ${response.reasonPhrase}';

  String toString() {
    return "RocketChatException: $message";
  }
}
