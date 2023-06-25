import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rocket_chat_connector_flutter/exceptions/exception.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/filters/room_counters_filter.dart';
import 'package:rocket_chat_connector_flutter/models/filters/room_filter.dart';
import 'package:rocket_chat_connector_flutter/models/filters/room_history_filter.dart';
import 'package:rocket_chat_connector_flutter/models/new/room_new.dart';
import 'package:rocket_chat_connector_flutter/models/response/room_new_response.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart';
import 'package:rocket_chat_connector_flutter/models/room_counters.dart';
import 'package:rocket_chat_connector_flutter/models/room_messages.dart';
import 'package:rocket_chat_connector_flutter/services/base_room_service.dart';
import 'package:rocket_chat_connector_flutter/services/http_service.dart';

class RoomService extends BaseRoomService {
  RoomService(HttpService httpService) : super(httpService);

  Future<RoomNewResponse> create(
    RoomNew roomNew,
    Authentication authentication,
  ) async {
    http.Response response = await httpService.post(
      '/api/v1/im.create',
      jsonEncode(roomNew.toMap()),
      authentication,
    );

    String body = response.body;
    // utf8手动转，避免自动转中文乱码
    if (response.bodyBytes.isNotEmpty == true) {
      body = Utf8Decoder().convert(response.bodyBytes);
    }

    if (response.statusCode == 200) {
      return RoomNewResponse.fromMap(jsonDecode(body));
    }
    throw RocketChatException(body);
  }

  @override
  Future<List<Room>> getRooms(Authentication authentication) async {
    http.Response response = await httpService.get(
      '/api/v1/rooms.get',
      authentication,
    );

    String body = response.body;
    // utf8手动转，避免自动转中文乱码
    if (response.bodyBytes.isNotEmpty == true) {
      body = Utf8Decoder().convert(response.bodyBytes);
    }

    if (response.statusCode == 200) {
      Map json = jsonDecode(body);
      List update = json['update'] ?? [];
      return update.map((e) => Room.fromMap(e)).toList();
    }
    throw RocketChatException(body);
  }

  @override
  Future<RoomMessages> messages(
      Room room, Authentication authentication) async {
    http.Response response = await httpService.getWithFilter(
      '/api/v1/im.messages',
      RoomFilter(room),
      authentication,
    );

    String body = response.body;
    // utf8手动转，避免自动转中文乱码
    if (response.bodyBytes.isNotEmpty == true) {
      body = Utf8Decoder().convert(response.bodyBytes);
    }

    if (response.statusCode == 200) {
      return RoomMessages.fromMap(jsonDecode(body));
    }
    throw RocketChatException(body);
  }

  @override
  Future<RoomMessages> history(
      RoomHistoryFilter filter, Authentication authentication) async {
    http.Response response = await httpService.getWithFilter(
      '/api/v1/im.history',
      filter,
      authentication,
    );

    String body = response.body;
    // utf8手动转，避免自动转中文乱码
    if (response.bodyBytes.isNotEmpty == true) {
      body = Utf8Decoder().convert(response.bodyBytes);
    }

    if (response.statusCode == 200) {
      return RoomMessages.fromMap(jsonDecode(body));
    }
    throw RocketChatException(body);
  }

  @override
  Future<RoomCounters> counters(
      RoomCountersFilter filter, Authentication authentication) async {
    http.Response response = await httpService.getWithFilter(
      '/api/v1/im.counters',
      filter,
      authentication,
    );

    String body = response.body;
    // utf8手动转，避免自动转中文乱码
    if (response.bodyBytes.isNotEmpty == true) {
      body = Utf8Decoder().convert(response.bodyBytes);
    }

    if (response.statusCode == 200) {
      return RoomCounters.fromMap(jsonDecode(body));
    }
    throw RocketChatException(body);
  }

  @override
  Future<String> leave(String roomId, Authentication authentication) async {
    http.Response response = await httpService.post(
      '/api/v1/rooms.leave',
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

  Future<String> cleanRoomHistory(
      RoomHistoryFilter filter, Authentication authentication) async {
    http.Response response = await httpService.post(
      '/api/v1/rooms.cleanHistory',
      jsonEncode(filter.toMap()),
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
