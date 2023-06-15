import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rocket_chat_connector_flutter/exceptions/exception.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/new/user_new.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:rocket_chat_connector_flutter/services/http_service.dart';

class UserService {
  HttpService _httpService;

  UserService(this._httpService);

  Future<User> create(UserNew userNew, Authentication authentication) async {
    http.Response response = await _httpService.post(
      '/api/v1/users.create',
      jsonEncode(userNew.toMap()),
      authentication,
    );

    String body = response.body;
    // utf8手动转，避免自动转中文乱码
    if (response.bodyBytes.isNotEmpty == true) {
      body = Utf8Decoder().convert(response.bodyBytes);
    }

    if (response.statusCode == 200) {
      return User.fromMap(jsonDecode(body));
    }
    throw RocketChatException(body);
  }

  Future<User> updateUser(
      String userId, UserNew userNew, Authentication authentication) async {
    http.Response response = await _httpService.post(
      '/api/v1/users.update',
      jsonEncode({'userId': userId, 'data': userNew.toMap()}),
      authentication,
    );

    String body = response.body;
    // utf8手动转，避免自动转中文乱码
    if (response.bodyBytes.isNotEmpty == true) {
      body = Utf8Decoder().convert(response.bodyBytes);
    }

    if (response.statusCode == 200) {
      return User.fromMap(jsonDecode(body));
    }
    throw RocketChatException(body);
  }

  Future<String> setAvatarWithImageFile(
      String imageFileName, Authentication authentication) async {
    http.StreamedResponse response = await _httpService.postFile(
      '/api/v1/users.setAvatar',
      imageFileName,
      authentication,
    );

    if (response.statusCode == 200) {
      String responseBody = await response.stream.bytesToString();
      print(responseBody);
      return responseBody;
    }
    throw RocketChatException('${response.statusCode}');
  }

  Future<String> setAvatarWithImageUrl(
      String imageUrl, Authentication authentication) async {
    http.Response response = await _httpService.post(
      '/api/v1/users.setAvatar',
      jsonEncode({'avatarUrl': imageUrl}),
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

  Future<String> getAvatarWithUid(
      String userId, Authentication authentication) async {
    http.Response response = await _httpService.getWithParams(
      '/api/v1/users.getAvatar',
      {'userId': userId},
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

  Future<String> getAvatarWithUsername(
      String username, Authentication authentication) async {
    http.Response response = await _httpService.getWithParams(
      '/api/v1/users.getAvatar',
      {'username': username},
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
