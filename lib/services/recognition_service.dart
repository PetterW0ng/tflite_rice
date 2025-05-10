import 'package:flutter/material.dart';
import 'package:kds_app_v2/utils/constants.dart';
import 'package:kds_app_v2/global.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class RecognitionService {
  static Interpreter? _interpreter;
  static List<String>? _labels;

  /// 初始化模型
  static Future<void> initModel(CropType cropType) async {
    try {
      final modelPath = _getModelPath(cropType);
      final labelPath = _getLabelPath(cropType);

      // 验证资源文件是否存在
      final manifest = await DefaultAssetBundle.of(Global.context!)
          .loadString('AssetManifest.json');
      if (!manifest.contains(modelPath)) throw '模型文件不存在';
      if (!manifest.contains(labelPath)) throw '标签文件不存在';

      // 加载模型
      _interpreter = await Interpreter.fromAsset(modelPath);

      // 加载标签
      final labelsData =
          await DefaultAssetBundle.of(Global.context!).loadString(labelPath);
      _labels = labelsData.split('\n');

      debugPrint('模型加载成功: $_interpreter');
    } catch (e) {
      debugPrint('❌ 模型初始化错误: $e');
      rethrow;
    }
  }

  /// 处理静态图片
  static Future<List<Map<String, dynamic>>> processImage(
      String imagePath) async {
    try {
      if (_interpreter == null) throw '模型未初始化';

      // 加载图片并处理为模型输入格式
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) throw '无法解码图片';

      // 调整图片大小为模型所需尺寸
      final resizedImage = img.copyResize(image, width: 224, height: 224);

      // 准备输入张量
      var input = _imageToByteList(resizedImage);
      var output = List.filled(1000, 0.0).reshape([1, 1000]); // 调整为您模型的输出尺寸

      // 运行推理
      _interpreter!.run(input, output);

      // 处理结果
      var results = <Map<String, dynamic>>[];
      List<double> outputList = output[0] as List<double>;

      // 获取前5个最高概率
      var indexed = <MapEntry<int, double>>[];
      for (var i = 0; i < outputList.length; i++) {
        indexed.add(MapEntry(i, outputList[i]));
      }
      indexed.sort((a, b) => b.value.compareTo(a.value));

      for (var i = 0; i < 5 && i < indexed.length; i++) {
        var labelIndex = indexed[i].key;
        var confidence = indexed[i].value;
        results.add({
          'index': labelIndex,
          'label': labelIndex < (_labels?.length ?? 0)
              ? _labels![labelIndex]
              : 'Unknown',
          'confidence': confidence,
        });
      }

      return results;
    } catch (e) {
      debugPrint('❌ 图片识别错误: $e');
      rethrow;
    }
  }

  /// 处理摄像头帧
  static Future<List<Map<String, dynamic>>> processFrame(
      CameraImage image) async {
    try {
      if (_interpreter == null) throw '模型未初始化';

      // 处理CameraImage为模型所需格式
      // 注意：这里的实现取决于您的相机图像格式和模型需求
      // 这是一个简化示例
      var convertedImage = _convertCameraImage(image);
      var output = List.filled(1000, 0.0).reshape([1, 1000]); // 调整为您模型的输出尺寸

      // 运行推理
      _interpreter!.run(convertedImage, output);

      // 处理结果
      var results = <Map<String, dynamic>>[];
      List<double> outputList = output[0] as List<double>;

      // 获取前5个最高概率
      var indexed = <MapEntry<int, double>>[];
      for (var i = 0; i < outputList.length; i++) {
        indexed.add(MapEntry(i, outputList[i]));
      }
      indexed.sort((a, b) => b.value.compareTo(a.value));

      for (var i = 0; i < 5 && i < indexed.length; i++) {
        var labelIndex = indexed[i].key;
        var confidence = indexed[i].value;
        results.add({
          'index': labelIndex,
          'label': labelIndex < (_labels?.length ?? 0)
              ? _labels![labelIndex]
              : 'Unknown',
          'confidence': confidence,
        });
      }

      return results;
    } catch (e) {
      debugPrint('❌ 实时识别错误: $e');
      rethrow;
    }
  }

  /// 释放模型资源
  static Future<void> dispose() async {
    try {
      _interpreter?.close();
      _interpreter = null;
    } catch (e) {
      debugPrint('❌ 模型释放错误: $e');
    }
  }

  // --- 私有方法 ---
  static String _getModelPath(CropType cropType) {
    return cropType == CropType.rice
        ? "assets/models/rice_model.tflite"
        : "assets/models/wheat_model.tflite";
  }

  static String _getLabelPath(CropType cropType) {
    return cropType == CropType.rice
        ? "assets/configs/rice_labels.txt"
        : "assets/configs/wheat_labels.txt";
  }

  // 将图片转换为模型输入格式
  static List<List<List<List<double>>>> _imageToByteList(img.Image image) {
    var convertedBytes = List.generate(
      1,
      (i) => List.generate(
        224,
        (y) => List.generate(
          224,
          (x) => List.generate(
            3,
            (c) {
              // 获取像素值并正确处理颜色通道
              final pixel = image.getPixel(x, y);
              // 根据通道索引(c)选择R、G或B分量
              final value = c == 0
                  ? pixel.r.toDouble()
                  : (c == 1 ? pixel.g.toDouble() : pixel.b.toDouble());
              // 归一化到[-1,1]区间
              return value / 127.5 - 1.0;
            },
          ),
        ),
      ),
    );
    return convertedBytes;
  }

  // 转换相机图像为模型输入格式
  static List<List<List<List<double>>>> _convertCameraImage(
      CameraImage cameraImage) {
    // 将YUV格式转换为RGB格式
    // 注意：这个实现假设摄像头使用YUV_420格式，如果不是，需要相应调整
    if (cameraImage.format.group != ImageFormatGroup.yuv420) {
      debugPrint('警告：不支持的相机图像格式: ${cameraImage.format.group}');
    }

    try {
      // 创建临时图像以用于处理
      final img.Image image = _convertYUV420ToImage(cameraImage);
      // 调整大小至模型所需尺寸
      final resizedImage = img.copyResize(image, width: 224, height: 224);

      // 采用与静态图像相同的方法处理
      var convertedBytes = List.generate(
        1,
        (i) => List.generate(
          224,
          (y) => List.generate(
            224,
            (x) => List.generate(
              3,
              (c) {
                final pixel = resizedImage.getPixel(x, y);
                final value = c == 0
                    ? pixel.r.toDouble()
                    : (c == 1 ? pixel.g.toDouble() : pixel.b.toDouble());
                return value / 127.5 - 1.0;
              },
            ),
          ),
        ),
      );
      return convertedBytes;
    } catch (e) {
      debugPrint('相机帧转换失败: $e');
      // 返回一个空白数据，避免崩溃
      return List.generate(
        1,
        (i) => List.generate(
          224,
          (y) => List.generate(
            224,
            (x) => List.generate(
              3,
              (c) => 0.0,
            ),
          ),
        ),
      );
    }
  }

  // 将YUV420格式的相机图像转换为RGB图像
  static img.Image _convertYUV420ToImage(CameraImage cameraImage) {
    // 创建一个新图像
    final image =
        img.Image(width: cameraImage.width, height: cameraImage.height);

    // YUV420格式的转换，这是一个简化实现
    // 实际代码可能需要更复杂的处理
    final yPlane = cameraImage.planes[0].bytes;
    final uPlane = cameraImage.planes[1].bytes;
    final vPlane = cameraImage.planes[2].bytes;

    final yRowStride = cameraImage.planes[0].bytesPerRow;
    final uvRowStride = cameraImage.planes[1].bytesPerRow;
    final uvPixelStride = cameraImage.planes[1].bytesPerPixel ?? 1;

    for (int y = 0; y < cameraImage.height; y++) {
      for (int x = 0; x < cameraImage.width; x++) {
        final yIndex = y * yRowStride + x;
        // UV像素可能是采样的，所以除以2
        final uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

        // YUV转RGB基本公式（简化版）
        int yValue = yPlane[yIndex];
        final uValue = uPlane[uvIndex];
        final vValue = vPlane[uvIndex];

        // YUV到RGB转换
        int r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
        int g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
            .round()
            .clamp(0, 255);
        int b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);

        // 设置像素
        image.setPixelRgba(x, y, r, g, b, 255);
      }
    }

    return image;
  }
}
