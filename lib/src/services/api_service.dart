import 'dart:convert';
import 'dart:io';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // api data
  static String historyUrl = '';
  static String recommendUrl = '';
  static String programsUrl = '';
  static String mmchartUrl = '';
  static String airchartUrl = '';
  static String shareUrl = '';
  static String share_msgUrl = '';
  static String privacyUrl = '';
  static String termsUrl = '';
  static String serverUrl = '';
  static String detailUrl = '';
  static int sv_timeOut = 5;
  static int rc_timeOut = 20;

  // remote config
  static String appVersion = '';
  static String storeUrl = '';

  Map<String, String> config = {};

  Future<void> getRemoteConfig() async {
    try {
      final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

      await remoteConfig.fetchAndActivate(); // remote config 실행

      config['mainURL'] = remoteConfig.getString('mainURL');

      if (Platform.isAndroid) {
        ApiService.appVersion = remoteConfig.getString('appVersion_AOS');
        ApiService.storeUrl = remoteConfig.getString('storeUrl_AOS');
      } else {
        ApiService.appVersion = remoteConfig.getString('appVersion_IOS');
        ApiService.storeUrl = remoteConfig.getString('storeUrl_IOS');
      }

      // print("RemoteConfig mainURL : ${config['mainURL']}");

    } catch (e) {
      print('REMOTE CONFIG ERROR: $e');
    }
  }

  // ===============================================================================
  // 데이터 받아오기
  Future<void> getApiData() async {

    try {
      await getRemoteConfig(); // Remote Config에서 mainURL 가져오기

      http.Response response = await http.get(Uri.parse(config['mainURL'] ?? '')); // API DATA 받아오기
      final apiData = jsonDecode(response.body); // json 형태로 가공

      // print('API DATA :::::: $apiData');

      ApiService.historyUrl = 'https://${apiData['history']}';
      ApiService.recommendUrl = 'https://${apiData['recommend']}';
      ApiService.programsUrl = 'https://${apiData['programs']}';
      ApiService.mmchartUrl = 'https://${apiData['mmchart']}';
      ApiService.airchartUrl = 'https://${apiData['airchart']}';
      ApiService.shareUrl = 'https://${apiData['share']}';
      ApiService.share_msgUrl = apiData['share_msg'];
      ApiService.privacyUrl = 'https://${apiData['privacy']}';
      ApiService.termsUrl = 'https://${apiData['terms']}';
      ApiService.detailUrl = 'https://${apiData['detail']}';
      ApiService.serverUrl = 'https://${apiData['server']}';
      ApiService.sv_timeOut = apiData['sv_timeout'];
      ApiService.rc_timeOut = apiData['rc_timeout'];

    } catch (e) {
      print('API DATA RESPONSE ERROR : $e');
      rethrow;
    }
  }
}
