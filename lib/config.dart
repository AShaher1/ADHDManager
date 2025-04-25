import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class Config {
  static Future<String?> getOpenAiKey() async {
    if (kIsWeb) {
      final remoteConfig = FirebaseRemoteConfig.instance;
      return remoteConfig.getString('openai_api_key');
    } else {
      return dotenv.env['OPENAI_API_KEY'];
    }
  }
}
