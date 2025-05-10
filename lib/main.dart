import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // 添加kIsWeb支持
import 'package:kds_app_v2/screens/model_selection_screen.dart';
import 'package:kds_app_v2/services/model_loader.dart';

void main() async {
  // 关键初始化流程
  WidgetsFlutterBinding.ensureInitialized();

  // Web平台特殊配置
  if (kIsWeb) {
    await _initWeb();
  } else {
    await _initMobile();
  }

  runApp(const MyApp());
}

// Web专用初始化
Future<void> _initWeb() async {
  // 1. 设置Web渲染器（可选）
  // debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;

  // 2. 轻量级预加载（不加载大模型）
  await ModelLoader.preloadWebAssets();
}

// 移动端初始化
Future<void> _initMobile() async {
  // 移动端完整预加载
  await ModelLoader.preloadModels();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '农作物病害识别',
      debugShowCheckedModeBanner: false,
      theme: _buildThemeData(),
      home: const ModelSelectionScreen(),
      // Web专用路由配置
      navigatorObservers: kIsWeb ? [_webRouteObserver()] : [],
    );
  }

  ThemeData _buildThemeData() {
    return ThemeData(
      primarySwatch: Colors.green,
      fontFamily: 'MyFont',
      visualDensity: VisualDensity.adaptivePlatformDensity,
      // Web平台需要显式设置字体
      fontFamilyFallback: kIsWeb ? ['Roboto', 'Arial'] : null,
    );
  }

  // Web路由观察器（用于处理浏览器前进/后退）
  static NavigatorObserver _webRouteObserver() {
    return NavigatorObserver();
  }
}
