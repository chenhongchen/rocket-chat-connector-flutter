import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:rocket_chat_connector_flutter/exceptions/exception.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/subscription.dart';
import 'package:rocket_chat_connector_flutter/services/http_service.dart';

class SubscriptionService {
  HttpService _httpService;

  SubscriptionService(this._httpService);

  Future<Subscription> getSubscriptions(Authentication authentication) async {
    http.Response response = await _httpService.get(
      '/api/v1/subscriptions.get',
      authentication,
    );

    String body = response.body;
    // utf8手动转，避免自动转中文乱码
    if (response.bodyBytes.isNotEmpty == true) {
      body = Utf8Decoder().convert(response.bodyBytes);
    }

    if (response.statusCode == 200) {
      return Subscription.fromMap(jsonDecode(body));
    }
    throw RocketChatException(body);
  }
}
