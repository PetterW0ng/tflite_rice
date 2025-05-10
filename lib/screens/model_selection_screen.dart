import 'package:flutter/material.dart';
import 'package:kds_app_v2/services/model_loader.dart';
import 'package:kds_app_v2/screens/home_screen.dart';
import 'package:kds_app_v2/utils/constants.dart'; // 确保从这里导入
import 'package:kds_app_v2/global.dart';

class ModelSelectionScreen extends StatelessWidget {
  const ModelSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 设置全局上下文，确保其他服务可以访问
    Global.context = context;

    return Scaffold(
      appBar: AppBar(title: const Text('选择作物模型')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 水稻模型选择按钮
            ElevatedButton.icon(
              icon: const Icon(Icons.grass, size: 30),
              label: const Text('水稻病害识别', style: TextStyle(fontSize: 18)),
              onPressed: () => _loadModelAndNavigate(context, CropType.rice),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
            const SizedBox(height: 20),
            // 小麦模型选择按钮
            ElevatedButton.icon(
              icon: const Icon(Icons.eco, size: 30),
              label: const Text('小麦病害识别', style: TextStyle(fontSize: 18)),
              onPressed: () => _loadModelAndNavigate(context, CropType.wheat),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 加载模型并跳转到主界面
  Future<void> _loadModelAndNavigate(
      BuildContext context, CropType cropType) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await ModelLoader.loadModel(cropType); // 加载模型
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(cropType: cropType)),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('模型加载失败: $e')),
      );
    }
  }
}

// 作物类型枚举（在 lib/utils/constants.dart 中定义）
