import 'dart:convert';
import 'dart:io';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:http/http.dart' as http;

class ApiService {

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // 인스턴스 변수
  String historyUrl = '';
  String recommendUrl = '';
  String programsUrl = '';
  String mmchartUrl = '';
  String airchartUrl = '';
  String shareUrl = '';
  String share_msgUrl = '';
  String privacyUrl = '';
  String termsUrl = '';
  String serverUrl = '';
  String detailUrl = '';
  int sv_timeOut = 5;
  int rc_timeOut = 20;

  // remote config
  String appVersion = '';
  String storeUrl = '';
  Map<String, String> config = {};

  Future<void> getRemoteConfig() async {
    try {
      final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.fetchAndActivate(); // remote config 실행
      config['mainURL'] = remoteConfig.getString('mainURL');

      if (Platform.isAndroid) {
        appVersion = remoteConfig.getString('appVersion_AOS');
        storeUrl = remoteConfig.getString('storeUrl_AOS');
      } else {
        appVersion = remoteConfig.getString('appVersion_IOS');
        storeUrl = remoteConfig.getString('storeUrl_IOS');
      }
    } catch (e) {
      print('REMOTE CONFIG ERROR: $e');
    }
  }

  // ===============================================================================
  // 데이터 받아오기
  Future<void> getApiData() async {

    try {
      await getRemoteConfig(); // Remote Config에서 mainURL 가져오기

      final mainURL = config['mainURL'];
      if (mainURL == null || mainURL.trim().isEmpty) throw Exception('mainURL is null or empty');

      final uri = Uri.tryParse(mainURL);
      if (uri == null || uri.host.isEmpty) throw Exception('Invalid mainURL: $mainURL');

      final response = await http.get(uri);
      if (response.statusCode != 200) throw Exception('HTTP ERROR STATUS : ${response.statusCode}');
      final apiData = jsonDecode(response.body);

      historyUrl = 'https://${apiData['history']}';
      recommendUrl = 'https://${apiData['recommend']}';
      programsUrl = 'https://${apiData['programs']}';
      mmchartUrl = 'https://${apiData['mmchart']}';
      airchartUrl = 'https://${apiData['airchart']}';
      shareUrl = 'https://${apiData['share']}';
      share_msgUrl = apiData['share_msg'];
      privacyUrl = 'https://${apiData['privacy']}';
      termsUrl = 'https://${apiData['terms']}';
      detailUrl = 'https://${apiData['detail']}';
      serverUrl = 'https://${apiData['server']}';
      sv_timeOut = apiData['sv_timeout'];
      rc_timeOut = apiData['rc_timeout'];
    } catch (e) {
      print('API DATA RESPONSE ERROR : $e');
      rethrow;
    }
  }
}
