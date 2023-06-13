import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rocket_chat_connector_flutter/exceptions/exception.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/filters/room_counters_filter.dart';
import 'package:rocket_chat_connector_flutter/models/filters/room_filter.dart';
import 'package:rocket_chat_connector_flutter/models/filters/room_history_filter.dart';
import 'package:rocket_chat_connector_flutter/models/new/channel_new.dart';
import 'package:rocket_chat_connector_flutter/models/response/room_new_response.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart';
import 'package:rocket_chat_connector_flutter/models/room_counters.dart';
import 'package:rocket_chat_connector_flutter/models/room_messages.dart';
import 'package:rocket_chat_connector_flutter/services/base_room_service.dart';
import 'package:rocket_chat_connector_flutter/services/http_service.dart';

class ChannelService extends BaseRoomService {
  ChannelService(HttpService httpService) : super(httpService);

  Future<RoomNewResponse> create(
      ChannelNew channelNew, Authentication authentication) async {
    http.Response response = await httpService.post(
      '/api/v1/channels.create',
      jsonEncode(channelNew.toMap()),
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return RoomNewResponse.fromMap(jsonDecode(response.body));
      } else {
        return RoomNewResponse();
      }
    }
    throw RocketChatException(response.body);
  }

  @override
  Future<List<Room>> getRooms(Authentication authentication) async {
    http.Response response = await httpService.get(
      '/api/v1/channels.list.joined',
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        Map json = jsonDecode(response.body);
        List rooms = json['channels'] ?? [];
        return rooms.map((e) => Room.fromMap(e)).toList();
      } else {
        return [];
      }
    }
    throw RocketChatException(response.body);
  }

  @override
  Future<RoomMessages> messages(
      Room room, Authentication authentication) async {
    http.Response response = await httpService.getWithFilter(
      '/api/v1/channels.messages',
      RoomFilter(room),
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return RoomMessages.fromMap(jsonDecode(response.body));
      } else {
        return RoomMessages();
      }
    }
    throw RocketChatException(response.body);
  }

  @override
  Future<RoomMessages> history(
      RoomHistoryFilter filter, Authentication authentication) async {
    http.Response response = await httpService.getWithFilter(
      '/api/v1/channels.history',
      filter,
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return RoomMessages.fromMap(jsonDecode(response.body));
      } else {
        return RoomMessages();
      }
    }
    throw RocketChatException(response.body);
  }

  @override
  Future<RoomCounters> counters(
    RoomCountersFilter filter,
    Authentication authentication,
  ) async {
    http.Response response = await httpService.getWithFilter(
      '/api/v1/channels.counters',
      filter,
      authentication,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty == true) {
        return RoomCounters.fromMap(jsonDecode(response.body));
      } else {
        return RoomCounters();
      }
    }
    throw RocketChatException(response.body);
  }
}
