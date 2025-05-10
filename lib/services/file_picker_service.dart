import 'package:image_picker/image_picker.dart';

class FilePickerService {
  static final ImagePicker _picker = ImagePicker();

  /// 选择单张图片
  static Future<XFile?> pickImage() async {
    try {
      return await _picker.pickImage(source: ImageSource.gallery);
    } catch (e) {
      throw '图片选择失败: $e';
    }
  }

  /// 选择多张图片
  static Future<List<XFile>> pickMultiImage() async {
    try {
      return await _picker.pickMultiImage() ?? [];
    } catch (e) {
      throw '多图选择失败: $e';
    }
  }

  /// 选择视频
  static Future<XFile?> pickVideo() async {
    try {
      return await _picker.pickVideo(source: ImageSource.gallery);
    } catch (e) {
      throw '视频选择失败: $e';
    }
  }
}
