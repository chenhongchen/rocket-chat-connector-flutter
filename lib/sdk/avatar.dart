import 'dart:typed_data';

class Avatar {
  String? svg; // 默认头像
  Uint8List? image; // 上传的头像

  Avatar({this.svg, this.image});
}
