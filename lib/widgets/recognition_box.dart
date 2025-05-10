import 'package:flutter/material.dart';
import 'package:kds_app_v2/services/camera_service.dart';
import 'package:kds_app_v2/utils/constants.dart';

class RecognitionBox extends StatelessWidget {
  final CropType cropType;
  final CameraService cameraService;

  const RecognitionBox({
    super.key,
    required this.cropType,
    required this.cameraService,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildBackground(),
        cameraService.cameraPreview, // 使用getter
        // 识别结果展示层
        _buildResultsOverlay(),
      ],
    );
  }

  // 构建背景
  Widget _buildBackground() => Image.asset(
        cropType == CropType.rice
            ? AppConstants.riceBgPath
            : AppConstants.wheatBgPath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );

  // 构建识别结果展示层
  Widget _buildResultsOverlay() {
    return const Positioned(
      left: 10,
      bottom: 10,
      right: 10,
      child: Card(
        color: Colors.black54,
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            '等待识别结果...',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
