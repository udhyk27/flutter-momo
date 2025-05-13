import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wear_os/song_info.dart';
import 'package:wear_os/widgets/vmidc.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/services.dart';

import 'controller/RecController.dart';
import 'history.dart';

VMIDC vmidc = VMIDC();

void main() {

  Get.put(RecController());

  WidgetsFlutterBinding.ensureInitialized();

  vmidc.bluetoothReceiver((receivedData) async {
    // 받은 데이터 처리
    print("수신된 곡 정보: $receivedData");

    var song = jsonDecode(receivedData);

    await Get.to(() => SongInfo(song: song));
    Get.find<RecController>().setRec(false);
  });


  runApp(const MyApp());



}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static String? uid = '';


  @override
  State<MyApp> createState() => _MyAppState();
}
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {

  static const platform = MethodChannel('com.example.watch/connection');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 앱 생명주기 변경을 감지
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Observer 제거
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.detached) {
      // 앱이 종료될 때 호출되는 부분
      await vmidc.stop();
      print("앱 종료됨");
      try {
        await platform.invokeMethod('endSession'); // 블루투스 연결 및 소켓 닫기 // # 수정 예정
      } catch (e) {
        print("블루투스 세션 닫기 에러 :: $e");
      }
    }
  }

  final PageController _pageController = PageController(initialPage: 0);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(200, 200), // 워치용
      minTextAdapt: true,
      splitScreenMode: true,
      child: GetMaterialApp(
        home: PageView(
          scrollDirection: Axis.vertical,
          controller: _pageController,
          children: [
            HomePage(),
            History(pageController: _pageController)
          ],
        ),
      ),
    );
  }
}



class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final VMIDC _vmidc = VMIDC();

  Future<void>? _asyncTask;

  @override
  void initState() {
    _vmidc.init();
    getDeviceId();
    super.initState();
  }

  Future<void> getDeviceId() async { // emulator TWR7.230913.001.E7
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    MyApp.uid = androidInfo.id;

    print('WATCH UID : ${MyApp.uid}');
    print('WATCH MODEL : ${androidInfo.model}');
  }

  static const platform = MethodChannel('com.example.watch/connection');

  // 자바 파일 실행 함수
  Future<bool> checkConnection() async {
    try {
      final bool isConnected = await platform.invokeMethod('checkConnection');
      return isConnected;
    } on PlatformException catch (e) {
      print("Failed to get connection status: '${e.message}'.");
      return false;
    }
  }



  Future<void> asyncFunction() async {

    final connectivityResult = await Connectivity().checkConnectivity();
    print('connectivityResult: $connectivityResult');

    // 마이크 권한 요청
    PermissionStatus status = await Permission.microphone.status;
    if (status == PermissionStatus.permanentlyDenied) { // 마이크 권한 영구적으로 거부된 경우
      PermissionToast();
      await Permission.microphone.request();
      return;
    } else if (status == PermissionStatus.denied) { // 사용자가 마이크 권한 거부한 경우
      requestMicPermission(context);
      Permission.microphone.request();
      return;
    }

    try {
      if (!mounted) return;
      await _vmidc.start(); // 녹음 시작
    } catch (e) {
      print('녹음 실패! ################## $e');
    }
  }

  // void cancelAsyncTask() async {
  //   if (_asyncTask != null) {
  //     await _vmidc.stop(); // 녹음 중지
  //   }

    // X 또는 아이콘 누르면 실패 화면
  // }

  @override // 페이지가 종료될 때에만 리소스 해제
  void dispose()  {
    _vmidc.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(255, 195, 200, 1.0),
      body: Center(
        child: GestureDetector(
          onTap: () {

            if (!Get.find<RecController>().canStart.value) {
              Fluttertoast.showToast(msg: "네트워크 연결을 확인해주세요.");
              return;
            }

            _asyncTask = asyncFunction();
            Get.find<RecController>().setRec(true);
          },
          child: Obx(
                () {
              return Get.find<RecController>().isRecognizing.value
                  ? // 녹음 켜지면
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 20),
                  Text(
                    '음원 인식중입니다...',
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'NotoSansKR-Regular'),
                  ),
                ],
              )
                  : // 녹음 종료 임시용
              Container(
                width: MediaQuery.of(context).size.width * 0.6,
                child: Image.asset(
                  'assets/berry_logo.png',
                  fit: BoxFit.contain,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// 마이크 권한이 영구적으로 거부된 경우
void PermissionToast() {
  print('마이크 권한 영구적 거부');
  Fluttertoast.showToast(
      msg: '마이크 권한을 허용해주세요.',
      backgroundColor: Colors.grey,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER
  );
}

// 마이크 권한이 거부된 경우
Future<bool> requestMicPermission(BuildContext context) async {
  PermissionStatus status = await Permission.microphone.request();
  if (!status.isGranted) {  // 마이크 승인상태가 아닐시
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return _showDialog(context);
        });
    return false;
  }
  return true;
}

_showDialog(BuildContext context) {
  return AlertDialog(
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10))
    ),
    content: Builder(
      builder: (context) {
        var width = MediaQuery.of(context).size.width;
        var height = MediaQuery.of(context).size.height;
        return Container(
          width: width * 0.7,
          height: height * 0.2,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              RichText(
                  text: TextSpan(
                      children: [
                        TextSpan(
                            text: '음악 인식을 위해 마이크 권한을 ',
                            style: TextStyle(
                                fontSize: 17
                            )
                        ),
                        TextSpan(
                            text: '허용',
                            style: TextStyle(
                                fontSize: 17
                            )
                        ),
                        TextSpan(
                            text: ' 해주세요',
                            style: TextStyle(
                                fontSize: 17
                            )
                        )
                      ]
                  )
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    child: TextButton(
                      onPressed: () {
                        openAppSettings();
                      },
                      child: const Text('권한 설정',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        );
      },
    ),
  );
}
