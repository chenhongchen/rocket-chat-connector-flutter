import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:rocket_chat_connector_flutter/models/message_attachment_field.dart';

class MessageAttachment {
  DateTime? ts;
  String? title; // 文件名
  String? titleLink; //  文件链接
  bool? titleLinkDownload;
  Size? imageDimensions; // 图片尺寸
  String? imageUrl; // 图片链接
  String? imageType; // image/png
  int? imageSize; // 图片大小
  String? videoUrl; // 视频地址
  String? videoType; // video/mp4
  int? videoSize; // 视频大小
  String? audioUrl; // 音频地址
  String? audioType; // 音频类型
  int? audioSize; // 音频大小
  String? type; // file
  int? size;
  String? description; //
  String? format; // TXT // 文件格式(图片和视频没有这个字段)
  List<MessageAttachmentField>? fields;
  Uint8List? thumbnail;

  MessageAttachment({
    this.ts,
    this.title,
    this.titleLink,
    this.titleLinkDownload,
    this.imageDimensions,
    String? imagePreview, // 图片预览图 base64 数据
    this.imageUrl,
    this.imageType,
    this.imageSize,
    this.videoUrl,
    this.videoType,
    this.videoSize,
    this.audioUrl,
    this.audioSize,
    this.type,
    this.description,
    this.format,
    this.fields,
  }) : thumbnail = imagePreview == null ? null : base64Decode(imagePreview);

  MessageAttachment.fromMap(Map<String, dynamic>? json) {
    if (json != null) {
      ts = DateTime.parse(json['ts']);
      title = json['title'];
      titleLink = json['title_link'];
      titleLinkDownload = json['title_link_download'];
      imageDimensions = json['image_dimensions'] != null
          ? Size(double.parse('${json['image_dimensions']['width']}'),
              double.parse('${json['image_dimensions']['height']}'))
          : null;
      String? imagePreview = json['image_preview'];
      thumbnail = imagePreview == null ? null : base64Decode(imagePreview);
      imageUrl = json['image_url'];
      imageType = json['image_type'];
      imageSize = json['image_size'];
      videoUrl = json['video_url'];
      videoType = json['video_type'];
      videoSize = json['video_size'];
      audioUrl = json['audio_url'];
      audioType = json['audio_type'];
      audioSize = json['audio_size'];
      type = json['type'];
      size = json['size'];
      description = json['description'];
      format = json['format'];
      fields = (json['fields'] as List?)
          ?.map((e) => MessageAttachmentField.fromMap(e))
          .toList();
    }
  }

  Map<String, dynamic> toMap() => {
        'ts': ts != null ? ts!.toIso8601String() : null,
        'title': title,
        'title_link': titleLink,
        'title_link_download': titleLinkDownload,
        'image_dimensions': imageDimensions != null
            ? {
                'width': imageDimensions!.width,
                'height': imageDimensions!.height
              }
            : null,
        'image_preview': thumbnail == null ? null : base64UrlEncode(thumbnail!),
        'image_url': imageUrl,
        'image_type': imageType,
        'image_size': imageSize,
        'video_url': videoUrl,
        'video_type': videoType,
        'video_size': videoSize,
        'type': type,
        'description': description,
        'format': format,
        'fields': fields?.map((e) => e.toMap()).toList(),
      };

  @override
  String toString() {
    return 'MessageAttachment{ts: $ts, title: $title, title_link: $titleLink, title_link_download: $titleLinkDownload, image_dimensions: $imageDimensions, thumbnail: $thumbnail, image_url: $imageUrl, image_type: $imageType, image_size: $imageSize, video_url: $videoUrl, video_type: $videoType, video_size: $videoSize, type: $type, description: $description, format: $format, fields: $fields}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageAttachment &&
          runtimeType == other.runtimeType &&
          ts == other.ts &&
          title == other.title &&
          titleLink == other.titleLink &&
          titleLinkDownload == other.titleLinkDownload &&
          imageDimensions == other.imageDimensions &&
          thumbnail == other.thumbnail &&
          imageUrl == other.imageUrl &&
          imageType == other.imageType &&
          imageSize == other.imageSize &&
          videoUrl == other.videoUrl &&
          videoType == other.videoType &&
          videoSize == other.videoSize &&
          type == other.type &&
          description == other.description &&
          format == other.format &&
          fields == other.fields;

  @override
  int get hashCode =>
      ts.hashCode ^
      title.hashCode ^
      titleLink.hashCode ^
      titleLinkDownload.hashCode ^
      imageDimensions.hashCode ^
      thumbnail.hashCode ^
      imageUrl.hashCode ^
      imageType.hashCode ^
      imageSize.hashCode ^
      videoUrl.hashCode ^
      videoType.hashCode ^
      videoSize.hashCode ^
      type.hashCode ^
      description.hashCode ^
      format.hashCode ^
      fields.hashCode;
}
