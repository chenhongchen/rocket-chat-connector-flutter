import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/filters/room_counters_filter.dart';
import 'package:rocket_chat_connector_flutter/models/filters/room_filter.dart';
import 'package:rocket_chat_connector_flutter/models/filters/room_history_filter.dart';
import 'package:rocket_chat_connector_flutter/models/new/channel_new.dart';
import 'package:rocket_chat_connector_flutter/models/response/response.dart';
import 'package:rocket_chat_connector_flutter/models/response/room_new_response.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart';
import 'package:rocket_chat_connector_flutter/models/room_counters.dart';
import 'package:rocket_chat_connector_flutter/models/room_messages.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:rocket_chat_connector_flutter/services/channel_service.dart';
import 'package:rocket_chat_connector_flutter/services/http_service.dart';

import '../scenarios/data/new/channel_new_data.dart';
import '../scenarios/data/response/room_new_response_data.dart';
import '../scenarios/data/room_counters_data.dart';
import '../scenarios/data/room_data.dart';
import '../scenarios/data/room_messages_data.dart';
import '../scenarios/data/user_data.dart';
import 'channel_service_test.mocks.dart';

@GenerateMocks([HttpService])
void main() {
  HttpService? httpServiceMock;
  late ChannelService channelService;
  Authentication authenticationMock = new Authentication();

  ChannelNew channelNew = ChannelNewData.getById(1);

  setUp(() async {
    httpServiceMock = MockHttpService();
    channelService = ChannelService(httpServiceMock!);
  });

  test('create channel', () async {
    http.Response response =
        http.Response(jsonEncode(RoomNewResponseData.getMapById(1)), 200);
    when(httpServiceMock!.post(
      "/api/v1/channels.create",
      jsonEncode(channelNew.toMap()),
      authenticationMock,
    )).thenAnswer((_) => Future(() => response));

    RoomNewResponse channelNewResponse =
        await channelService.create(channelNew, authenticationMock);
    expect(channelNewResponse.success, true);
  });

  test('channel messages', () async {
    Room room = RoomData.getById("ByehQjC44FwMeiLbX");
    RoomFilter filter = RoomFilter(room);

    http.Response response =
        http.Response(jsonEncode(RoomMessagesData.getMapById(1)), 200);
    when(httpServiceMock!.getWithFilter(
      "/api/v1/channels.messages",
      filter,
      authenticationMock,
    )).thenAnswer((_) => Future(() => response));

    RoomMessages channelMessages =
        await channelService.messages(room, authenticationMock);
    expect(channelMessages.success, true);
  });

  test('channel markAsRead', () async {
    Room room = RoomData.getById("ByehQjC44FwMeiLbX");
    Map<String, String?> body = {"rid": room.id};

    http.Response response =
        http.Response(jsonEncode(Response(success: true).toMap()), 200);
    when(httpServiceMock!.post(
      "/api/v1/subscriptions.read",
      jsonEncode(body),
      authenticationMock,
    )).thenAnswer((_) => Future(() => response));

    bool success = await channelService.markAsRead(room, authenticationMock);
    expect(success, true);
  });

  test('channel counters without user', () async {
    Room room = RoomData.getById("ByehQjC44FwMeiLbX");
    RoomCountersFilter filter = RoomCountersFilter(room);

    http.Response response =
        http.Response(jsonEncode(RoomCountersData.getMapById(1)), 200);
    when(httpServiceMock!.getWithFilter(
      "/api/v1/channels.counters",
      filter,
      authenticationMock,
    )).thenAnswer((_) => Future(() => response));

    RoomCounters channelCounters =
        await channelService.counters(filter, authenticationMock);
    expect(channelCounters.success, true);
  });

  test('channel counters with user', () async {
    User user = UserData.getById("aobEdbYhXfu5hkeqG");
    Room room = RoomData.getById("ByehQjC44FwMeiLbX");
    RoomCountersFilter filter = RoomCountersFilter(room, user: user);

    http.Response response =
        http.Response(jsonEncode(RoomCountersData.getMapById(1)), 200);
    when(httpServiceMock!.getWithFilter(
      "/api/v1/channels.counters",
      filter,
      authenticationMock,
    )).thenAnswer((_) => Future(() => response));

    RoomCounters channelCounters =
        await channelService.counters(filter, authenticationMock);
    expect(channelCounters.success, true);
  });

  test('channel history', () async {
    Room room = RoomData.getById("ByehQjC44FwMeiLbX");
    RoomHistoryFilter filter = RoomHistoryFilter(room);

    http.Response response =
        http.Response(jsonEncode(RoomCountersData.getMapById(1)), 200);
    when(httpServiceMock!.getWithFilter(
      "/api/v1/channels.history",
      filter,
      authenticationMock,
    )).thenAnswer((_) => Future(() => response));

    RoomMessages channelMessages =
        await channelService.history(filter, authenticationMock);
    expect(channelMessages.success, true);
  });

  test('channel history with date', () async {
    Room room = RoomData.getById("ByehQjC44FwMeiLbX");
    RoomHistoryFilter filter = RoomHistoryFilter(room, latest: DateTime.now());

    http.Response response =
        http.Response(jsonEncode(RoomCountersData.getMapById(1)), 200);
    when(httpServiceMock!.getWithFilter(
      "/api/v1/channels.history",
      filter,
      authenticationMock,
    )).thenAnswer((_) => Future(() => response));

    RoomMessages channelMessages =
        await channelService.history(filter, authenticationMock);
    expect(channelMessages.success, true);
  });
}
