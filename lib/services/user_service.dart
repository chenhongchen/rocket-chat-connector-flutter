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

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return User.fromMap(jsonDecode(response.body));
      } else {
        return User();
      }
    }
    throw RocketChatException(response.body);
  }

  Future<User> updateUser(
      String userId, UserNew userNew, Authentication authentication) async {
    http.Response response = await _httpService.post(
      '/api/v1/users.update',
      jsonEncode({'userId': userId, 'data': userNew.toMap()}),
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return User.fromMap(jsonDecode(response.body));
      } else {
        return User();
      }
    }
    throw RocketChatException(response.body);
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

    if (response.statusCode == 200) {
      return response.body;
    }
    throw RocketChatException(response.body);
  }

  Future<String> getAvatarWithUid(
      String userId, Authentication authentication) async {
    http.Response response = await _httpService.getWithParams(
      '/api/v1/users.getAvatar',
      {'userId': userId},
      authentication,
    );

    if (response.statusCode == 200) {
      return response.body;
    }
    throw RocketChatException(response.body);
  }

  Future<String> getAvatarWithUsername(
      String username, Authentication authentication) async {
    http.Response response = await _httpService.getWithParams(
      '/api/v1/users.getAvatar',
      {'username': username},
      authentication,
    );

    if (response.statusCode == 200) {
      return response.body;
    }
    throw RocketChatException(response.body);
  }
}
