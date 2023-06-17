import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Utils {
  static Future<String?> pickOneImage(
    BuildContext context, {
    ImageSource source = ImageSource.gallery,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    final picker = ImagePicker();
    try {
      XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        preferredCameraDevice: preferredCameraDevice,
        imageQuality: imageQuality,
      );
      return pickedFile?.path;
    } catch (e) {
      return null;
    }
  }
}
