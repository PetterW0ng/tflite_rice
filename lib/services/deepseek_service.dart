import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kds_app_v2/utils/api_config.dart'; // 新建配置文件

class DeepSeekService {
  static Future<String> getDiseaseAdvice(String diseaseName) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.deepSeekUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.apiKey}',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'user',
              'content': '请用中文简要说明${diseaseName}的防治方法（限100字内）',
            }
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['choices'][0]['message']['content'];
      }
      return 'API错误: ${response.statusCode}';
    } catch (e) {
      return '请求失败: $e';
    }
  }
}
