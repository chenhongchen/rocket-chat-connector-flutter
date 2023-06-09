import 'package:http/http.dart' as http;
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/filters/filter.dart';
import 'package:http_parser/http_parser.dart';

class HttpService {
  Uri? _apiUrl;

  HttpService(Uri apiUrl) {
    _apiUrl = apiUrl;
  }

  Future<http.Response> getWithFilter(
          String uri, Filter filter, Authentication authentication) async =>
      await http.get(
          Uri.parse(
              _apiUrl.toString() + uri + '?' + _urlEncode(filter.toMap())),
          headers: await (_getHeaders(authentication)));

  Future<http.Response> get(String uri, Authentication authentication) async =>
      await http.get(Uri.parse(_apiUrl.toString() + uri),
          headers: await (_getHeaders(authentication)));

  Future<http.Response> post(
          String uri, String body, Authentication? authentication) async =>
      await http.post(Uri.parse(_apiUrl.toString() + uri),
          headers: await (_getHeaders(authentication)), body: body);

  Future<http.Response> put(
          String uri, String body, Authentication authentication) async =>
      await http.put(Uri.parse(_apiUrl.toString() + uri),
          headers: await (_getHeaders(authentication)), body: body);

  Future<http.Response> delete(
          String uri, Authentication authentication) async =>
      await http.delete(Uri.parse(_apiUrl.toString() + uri),
          headers: await (_getHeaders(authentication)));

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
    var request =
        http.MultipartRequest('POST', Uri.parse(_apiUrl.toString() + uri));
    // 设置head
    Map<String, String>? head = await (_getHeaders(authentication));
    head['Content-Type'] = 'multipart/form-data';
    request.headers.addAll(head);
    // 设置参数
    if (fields != null) {
      request.fields.addAll(fields);
    }
    // 上传文件
    request.files.add(await http.MultipartFile.fromPath(field, filename,
        contentType: mediaType));
    final streamedRequest = await request.send();

    // 监听进度
    final totalBytes = streamedRequest.contentLength;
    if (totalBytes != null && totalBytes != 0) {
      int bytesUploaded = 0;
      streamedRequest.stream.listen(
        (chunk) {
          bytesUploaded += chunk.length;
          final progress = bytesUploaded / totalBytes;
          print('Upload progress: $progress');
          onProgress?.call(progress);
        },
        onDone: () {
          print('Upload complete');
          onDone?.call();
        },
        onError: (error) {
          print('Upload failed: $error');
          onError?.call();
        },
        cancelOnError: true,
      );
    }
    return streamedRequest;
  }

  Future<Map<String, String>> _getHeaders(
      Authentication? authentication) async {
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
