import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraService {
  late CameraController _controller;
  bool _isInitialized = false;
  bool _isStreaming = false;

  // Getter方法（完整实现）
  Widget get cameraPreview {
    return _isInitialized
        ? CameraPreview(_controller)
        : const Center(child: CircularProgressIndicator());
  }

  // 状态获取
  bool get isInitialized => _isInitialized;
  bool get isStreaming => _isStreaming;

  // 初始化摄像头
  Future<void> initialize() async {
    try {
      final cameras = await availableCameras();
      _controller = CameraController(
        cameras.first,
        ResolutionPreset.veryHigh,
        enableAudio: false,
      );
      await _controller.initialize();
      _isInitialized = true;
    } on CameraException catch (e) {
      throw '摄像头初始化失败: ${e.description}';
    }
  }

  // 启动视频流
  void startImageStream(Function(CameraImage) onFrame) {
    if (_isInitialized && !_isStreaming) {
      _controller.startImageStream(onFrame);
      _isStreaming = true;
    }
  }

  // 停止视频流
  void stopImageStream() {
    if (_isStreaming) {
      _controller.stopImageStream();
      _isStreaming = false;
    }
  }

  // 释放资源
  void dispose() {
    _controller.dispose();
  }
}
