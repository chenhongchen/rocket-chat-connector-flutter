import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:rocket_chat_connector_flutter/exceptions/exception.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/filters/filter.dart';
import 'package:http_parser/http_parser.dart';

class HttpService {
  Uri? _apiUrl;

  HttpService(Uri apiUrl) {
    _apiUrl = apiUrl;
  }

  Future<http.Response> getWithParams(
          String uri, Map params, Authentication authentication) async =>
      await http.get(
          Uri.parse(_apiUrl.toString() + uri + '?' + _urlEncode(params)),
          headers: _getHeaders(authentication));

  Future<http.Response> getWithFilter(
          String uri, Filter filter, Authentication authentication) async =>
      await http.get(
          Uri.parse(
              _apiUrl.toString() + uri + '?' + _urlEncode(filter.toMap())),
          headers: _getHeaders(authentication));

  Future<http.Response> get(String uri, Authentication authentication) async =>
      await http.get(Uri.parse(_apiUrl.toString() + uri),
          headers: _getHeaders(authentication));

  Future<http.Response> post(
          String uri, String body, Authentication? authentication) async =>
      await http.post(Uri.parse(_apiUrl.toString() + uri),
          headers: _getHeaders(authentication), body: body);

  Future<http.Response> put(
          String uri, String body, Authentication authentication) async =>
      await http.put(Uri.parse(_apiUrl.toString() + uri),
          headers: _getHeaders(authentication), body: body);

  Future<http.Response> delete(
          String uri, Authentication authentication) async =>
      await http.delete(Uri.parse(_apiUrl.toString() + uri),
          headers: _getHeaders(authentication));

  Future<http.StreamedResponse> postFile(
    String uri,
    // A file name to upload
    String filename,
    Authentication authentication, {
    String field = 'file',
    MediaType? mediaType,
    Map<String, String>? fields,
    Function(double progress)? onProgress,
    Function? onError,
    void onDone()?,
  }) async {
    var request = MultipartRequest('POST', Uri.parse(_apiUrl.toString() + uri),
        onProgress: (int bytes, int total) {
      final progress = bytes / total;
      onProgress?.call(progress);
    });
    // 设置head
    Map<String, String> head = _getHeaders(authentication);
    head['Content-Type'] = 'multipart/form-data';
    request.headers.addAll(head);
    // 设置参数
    if (fields != null) {
      request.fields.addAll(fields);
    }
    if (mediaType == null) {
      var name =
          filename.substring(filename.lastIndexOf('/') + 1, filename.length);
      // 获取文件扩展名
      List<String> fileNameSegments = name.split('.');
      String fileExt = fileNameSegments.last.toLowerCase();
      // 手动指定上传文件的contentType
      if (fileExt == 'gif' ||
          fileExt == 'jpg' ||
          fileExt == 'jpeg' ||
          fileExt == 'bmp' ||
          fileExt == 'png') {
        mediaType = MediaType('image', fileExt);
      } else if (fileExt == 'mp4') {
        mediaType = MediaType("video", fileExt);
      } else if (fileExt == 'amr' ||
          fileExt == 'mp3' ||
          fileExt == 'wav' ||
          fileExt == 'm4a') {
        mediaType = MediaType("audio", fileExt);
      } else {
        mediaType = MediaType("application", "octet-stream");
      }
    }
    // 上传文件
    request.files.add(await http.MultipartFile.fromPath(field, filename,
        contentType: mediaType));
    final streamedResponse = await request.send();
    return streamedResponse;
  }

  Future<Uint8List?> downloadFile(
    String uri,
    Authentication authentication, {
    Function(int receivedBytes, int total)? onProgress,
  }) async {
    final request = http.Request('GET', Uri.parse(_apiUrl.toString() + uri));
    // 设置head
    Map<String, String> head = _getHeaders(authentication);
    request.headers.addAll(head);
    final response = await http.Client().send(request);

    if (response.statusCode == 200) {
      final contentLength = response.contentLength;
      var receivedBytes = 0;
      Completer<Uint8List?> completer = Completer<Uint8List?>();
      List<int> bytes = <int>[];
      response.stream.listen(
        (data) {
          receivedBytes += data.length;
          bytes += data;
          onProgress?.call(receivedBytes, contentLength ?? -1);
        },
        onDone: () async {
          // 下载完成
          // 你可以在这里进行其他操作，如保存文件到本地等
          completer.complete(Uint8List.fromList(bytes));
        },
        onError: (error) {
          // 下载过程中发生错误
          completer.complete(null);
        },
      );
      return completer.future;
    }

    throw RocketChatException('${response.statusCode}');
  }

  Map<String, String> _getHeaders(Authentication? authentication) {
    Map<String, String> header = {
      'Content-type': 'application/json',
    };

    if (authentication?.status == "success") {
      header['X-Auth-Token'] = authentication?.data?.authToken ?? '';
      header['X-User-Id'] = authentication?.data?.userId ?? '';
    }

    return header;
  }
}

String _urlEncode(Map object) {
  int index = 0;
  String url = object.keys.map((key) {
    if (object[key]?.toString().isNotEmpty == true) {
      String value = "";
      if (index != 0) {
        value = "&";
      }
      index++;
      return "$value${Uri.encodeComponent(key)}=${Uri.encodeComponent(object[key].toString())}";
    }
    return "";
  }).join();
  return url;
}

class MultipartRequest extends http.MultipartRequest {
  /// Creates a new [MultipartRequest].
  MultipartRequest(
    String method,
    Uri url, {
    this.onProgress,
  }) : super(method, url);

  final void Function(int bytes, int totalBytes)? onProgress;

  /// Freezes all mutable fields and returns a single-subscription [ByteStream]
  /// that will emit the request body.
  http.ByteStream finalize() {
    final byteStream = super.finalize();
    if (onProgress == null) return byteStream;

    final total = this.contentLength;
    int bytes = 0;

    final t = StreamTransformer.fromHandlers(
      handleData: (List<int> data, EventSink<List<int>> sink) {
        bytes += data.length;
        onProgress?.call(bytes, total);
        if (total >= bytes) {
          sink.add(data);
        }
      },
    );
    final stream = byteStream.transform(t);
    return http.ByteStream(stream);
  }
}
