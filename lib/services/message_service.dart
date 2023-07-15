import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:rocket_chat_connector_flutter/exceptions/exception.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/new/message_new.dart';
import 'package:rocket_chat_connector_flutter/models/response/message_new_response.dart';
import 'package:rocket_chat_connector_flutter/services/http_service.dart';

class MessageService {
  HttpService _httpService;

  MessageService(this._httpService);

  Future<MessageNewResponse> postMessage(
      MessageNew message, Authentication authentication) async {
    http.Response response = await _httpService.post(
      '/api/v1/chat.postMessage',
      jsonEncode(message.toMap()),
      authentication,
    );

    String body = response.body;
    // utf8手动转，避免自动转中文乱码
    if (response.bodyBytes.isNotEmpty == true) {
      body = Utf8Decoder().convert(response.bodyBytes);
    }

    if (response.statusCode == 200) {
      return MessageNewResponse.fromMap(jsonDecode(body));
    }
    throw RocketChatException(body);
  }

  Future<MessageNewResponse?> getMessage(
      String msgId, Authentication authentication) async {
    http.Response response = await _httpService.getWithParams(
      '/api/v1/chat.getMessage',
      {'msgId': msgId},
      authentication,
    );

    String body = response.body;
    // utf8手动转，避免自动转中文乱码
    if (response.bodyBytes.isNotEmpty == true) {
      body = Utf8Decoder().convert(response.bodyBytes);
    }

    if (response.statusCode == 200) {
      return MessageNewResponse.fromMap(jsonDecode(body));
    }
    throw RocketChatException(body);
  }

  Future<Uint8List> getFile(
      String fileUri, Authentication authentication) async {
    final response = await _httpService.get(
      fileUri,
      authentication,
    );

    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      return bytes;
    } else {
      throw Exception('Failed to load image: ${response.statusCode}');
    }
  }

  getFileWithProgress(
    String fileUri,
    Authentication authentication, {
    Function(double progress)? onProgress,
  }) async {
    http.StreamedResponse response = await _httpService.downloadFile(
      fileUri,
      authentication,
      onProgress: onProgress,
    );

    if (response.statusCode == 200) {
      Uint8List bytes = await response.stream.toBytes();
      return bytes;
    }
    throw RocketChatException('${response.statusCode}');
  }

  /// 删除私聊
  Future<String> delete(String roomId, Authentication authentication) async {
    final response = await _httpService.post(
      '/api/v1/im.delete',
      jsonEncode({'roomId': roomId}),
      authentication,
    );

    String body = response.body;
    // utf8手动转，避免自动转中文乱码
    if (response.bodyBytes.isNotEmpty == true) {
      body = Utf8Decoder().convert(response.bodyBytes);
    }

    if (response.statusCode == 200) {
      return body;
    }
    throw RocketChatException(body);
  }
}
