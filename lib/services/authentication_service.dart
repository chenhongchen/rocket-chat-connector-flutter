import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rocket_chat_connector_flutter/exceptions/exception.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:rocket_chat_connector_flutter/services/http_service.dart';

class AuthenticationService {
  HttpService _httpService;

  AuthenticationService(this._httpService);

  Future<Authentication> login(String user, String password) async {
    Map<String, String> data = {'user': user, 'password': password};
    http.Response response = await _httpService.post(
      '/api/v1/login',
      jsonEncode(data),
      null,
    );

    String body = response.body;
    // utf8手动转，避免自动转中文乱码
    if (response.bodyBytes.isNotEmpty == true) {
      body = Utf8Decoder().convert(response.bodyBytes);
    }

    if (response.statusCode == 200) {
      return Authentication.fromMap(jsonDecode(body));
    }
    throw RocketChatException(body);
  }

  Future<User> me(Authentication authentication) async {
    http.Response response = await _httpService.get(
      '/api/v1/me',
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
}
