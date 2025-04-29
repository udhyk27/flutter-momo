import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:momo_final/src/services/watch_service.dart';

import 'src/controller/home_controller.dart';
import 'src/screens/main_page.dart';
import 'package:get/get.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'src/services/api_service.dart';

/**
 * 스토어 기준 소스
 *
 * 앱 시작 시
 * API 데이터 요청
 */

void main() async {

  WidgetsFlutterBinding.ensureInitialized(); // 플러그인 사용

  await Firebase.initializeApp();  // Firebase 초기화

  ApiService apiService = ApiService();
  await apiService.getApiData();

  Get.put(HomeController());

  WatchService watchService = WatchService();

  // 워치
  watchService.onAudioDataReceived = (audioData) {
    print("오디오 데이터 수신 완료! 데이터 길이: ${audioData.length}");

    // watchService.analyzeAudio(audioData);
  };

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static String? uid = '';

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: Consumer<MyAppState>(
        builder: (context, appState, child) {
          return GetMaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Momo',
            theme: appState.themeData,
            home: MainPage(),
          );
        },
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  int _pageIdx = 1;
  int get pageIdx => _pageIdx;

  bool _isChecked = false; // 토글
  bool get isChecked => _isChecked;

  String _theme = '스트로베리';
  String get theme => _theme;

  ThemeData _themeData = ThemeData(primarySwatch: Colors.pink);
  ThemeData get themeData => _themeData;

  int _selectedValue = 0;
  int get selectedValue => _selectedValue;

  bool _hasStarted = false; // 앱 최초 실행시 에만 음악 검색
  bool get hasStarted => _hasStarted;

  SharedPreferences? _prefs; // SharedPreferences 인스턴스 저장용

  MyAppState() {
    _init();
  }

  // SharedPreferences 한 번만 호출하고 재사용
  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadThemeValue(); // 테마 값
    _loadToggleChecked(); // 바로 음악 검색 할지
    getDeviceId();
  }

  // DEVICE ID 가져오기
  Future<void> getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      MyApp.uid = androidInfo.id;
      print('androidInfo : ${MyApp.uid}');
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      MyApp.uid = iosInfo.identifierForVendor;
      print('iosInfo : ${MyApp.uid}');
    }
  }

  // 앱 종료시까지 유지되는 값들 (Provider로 상태 관리)
  void setPageIdx(int idx) {
    _pageIdx = idx;
    notifyListeners();
  }

  void setHasStarted(bool value) {
    _hasStarted = value;
    notifyListeners();
  }

  // --------------------------------------------  앱 실행하면 바로 검색 --------------------------------------------
  void toggleChecked(bool value) async {
    _isChecked = value;
    // 값 저장
    await _prefs?.setBool('isChecked', _isChecked);
    notifyListeners();
  }

  // 값 불러오기
  void _loadToggleChecked() {
    _isChecked = _prefs?.getBool('isChecked') ?? false;
    notifyListeners();
  }
  // -------------------------------------------- 테마 --------------------------------------------
  void _loadThemeValue() {
    _selectedValue = _prefs?.getInt('selectedValue') ?? 0;
    _updateTheme(_selectedValue);
    notifyListeners(); // 값을 불러온 후 UI 갱신
  }

  void setTheme(int value) {
    _selectedValue = value;
    _updateTheme(_selectedValue); // 테마 설정
    _saveSelectedValue(_selectedValue); // 값 저장
    notifyListeners();
  }

  void _updateTheme(int value) {
    switch (value) {
      case 1:
        _theme = "오션블루";
        _themeData = ThemeData(primarySwatch: Colors.blue);
        break;
      case 2:
        _theme = "다크모드";
        _themeData = ThemeData.dark();
        break;
      default:
        _theme = "스트로베리";
        _themeData = ThemeData(primarySwatch: Colors.pink);
        break;
    }
  }

  void _saveSelectedValue(int value) async {
    await _prefs?.setInt('selectedValue', value);
  }
}
