import 'package:flutter/material.dart';
import 'package:kds_app_v2/services/camera_service.dart';
import 'package:kds_app_v2/services/file_picker_service.dart';
import 'package:kds_app_v2/services/recognition_service.dart';
import 'package:kds_app_v2/utils/constants.dart';
import 'package:kds_app_v2/widgets/recognition_box.dart';

class HomeScreen extends StatefulWidget {
  final CropType cropType;

  const HomeScreen({super.key, required this.cropType});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraService? _cameraService;
  bool _isLoading = true;
  bool _isRecognizing = false; // 新增：识别状态控制
  bool _initError = false; // Add error flag

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    setState(() {
      _isLoading = true;
      _initError = false;
    });

    try {
      // 初始化识别服务
      await RecognitionService.initModel(widget.cropType);

      // 初始化相机
      _cameraService = CameraService();
      await _cameraService!.initialize();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _initError = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('初始化失败: $e')),
        );
      }
    }
  }

  // 图片选择处理
  Future<void> _onImageSelect() async {
    try {
      final image = await FilePickerService.pickImage();
      if (image != null) {
        setState(() => _isRecognizing = true);
        final results = await RecognitionService.processImage(image.path);
        _showResults(results);
      }
    } catch (e) {
      _showError('图片选择失败: $e');
    } finally {
      setState(() => _isRecognizing = false);
    }
  }

  // 视频选择处理
  Future<void> _onVideoSelect() async {
    try {
      final video = await FilePickerService.pickVideo();
      if (video != null) {
        setState(() => _isRecognizing = true);
        // TODO: 实现视频识别逻辑
      }
    } catch (e) {
      _showError('视频选择失败: $e');
    } finally {
      setState(() => _isRecognizing = false);
    }
  }

  // 摄像头开关控制
  void _onCameraToggle() {
    if (_cameraService == null) return; // Check if camera exists

    setState(() {
      if (_cameraService!.isStreaming) {
        _cameraService!.stopImageStream();
      } else {
        _cameraService!.startImageStream((image) async {
          if (!_isRecognizing) {
            setState(() => _isRecognizing = true);
            try {
              final results = await RecognitionService.processFrame(image);
              _updateUI(results);
            } catch (e) {
              _showError('识别错误: $e');
            } finally {
              setState(() => _isRecognizing = false);
            }
          }
        });
      }
    });
  }

  // 显示识别结果
  void _showResults(List<dynamic> results) {
    // TODO: 实现结果展示逻辑
  }

  // 更新UI
  void _updateUI(dynamic data) {
    if (mounted) setState(() {});
  }

  // 显示错误
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _cameraService?.dispose(); // Use safe call operator
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cropType == CropType.rice ? '水稻病害识别' : '小麦病害识别'),
        actions: [
          // Add reload button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initError ? _initServices : null,
            tooltip: '重新初始化',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _initError
              ? _buildErrorView()
              : Stack(
                  children: [
                    Row(
                      children: [
                        _buildFunctionButtons(),
                        Expanded(
                          child: RecognitionBox(
                            cropType: widget.cropType,
                            cameraService: _cameraService!,
                          ),
                        ),
                      ],
                    ),
                    if (_isRecognizing)
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
    );
  }

  Widget _buildFunctionButtons() {
    final bool isCameraReady = _cameraService != null && !_initError;
    final bool isStreaming = isCameraReady && _cameraService!.isStreaming;

    return Container(
      width: 100,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIconButton(Icons.photo_library, '图片识别',
              (_isRecognizing || !isCameraReady) ? null : _onImageSelect),
          const SizedBox(height: 20),
          _buildIconButton(Icons.video_library, '视频识别',
              (_isRecognizing || !isCameraReady) ? null : _onVideoSelect),
          const SizedBox(height: 20),
          _buildIconButton(
            Icons.camera_alt,
            isStreaming ? '停止识别' : '实时识别',
            (_isRecognizing || !isCameraReady) ? null : _onCameraToggle,
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
      IconData icon, String label, VoidCallback? onPressed) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, size: 30),
          onPressed: onPressed,
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // Build error view
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          const Text('初始化失败', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
            onPressed: _initServices,
          ),
        ],
      ),
    );
  }
}
