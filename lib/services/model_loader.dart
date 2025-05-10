import 'package:flutter/foundation.dart'; // 添加kIsWeb支持
import 'package:kds_app_v2/utils/constants.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:io';

class ModelLoader {
  /// 预加载Web专用资源
  static Future<void> preloadWebAssets() async {
    if (kIsWeb) {
      debugPrint('Web平台轻量预加载');
      // 这里可以预加载Web需要的轻量资源
      await Future.delayed(const Duration(milliseconds: 100)); // 模拟加载
    }
  }

  /// 预加载移动端模型
  static Future<void> preloadModels() async {
    if (kIsWeb) return; // Web平台跳过

    debugPrint('开始预加载所有模型');
    try {
      await Future.wait([
        loadModel(CropType.rice),
        loadModel(CropType.wheat),
      ]);
    } catch (e) {
      debugPrint('预加载失败: $e');
      rethrow;
    }
  }

  /// 加载指定作物模型
  static Future<void> loadModel(CropType cropType) async {
    if (kIsWeb) {
      return _loadModelWeb(cropType);
    } else {
      return _loadModelMobile(cropType);
    }
  }

  /// ----------------------------
  /// 移动端实现
  /// ----------------------------
  static Future<void> _loadModelMobile(CropType cropType) async {
    try {
      final modelPath = _getModelPath(cropType);

      // 使用tflite_flutter加载模型
      await Interpreter.fromAsset(modelPath);
      debugPrint('模型加载成功: $modelPath');
    } catch (e) {
      throw '移动端模型加载异常: $e';
    }
  }

  /// ----------------------------
  /// Web平台实现
  /// ----------------------------
  static Future<void> _loadModelWeb(CropType cropType) async {
    debugPrint('Web平台模拟加载模型: ${cropType.name}');
    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// ----------------------------
  /// 共享工具方法
  /// ----------------------------
  static String _getModelPath(CropType cropType) {
    return cropType == CropType.rice
        ? 'assets/models/rice_model.tflite'
        : 'assets/models/wheat_model.tflite';
  }

  static String _getLabelPath(CropType cropType) {
    return cropType == CropType.rice
        ? 'assets/configs/rice_labels.txt'
        : 'assets/configs/wheat_labels.txt';
  }
}
