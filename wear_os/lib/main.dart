import 'dart:convert';
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

import 'controller/RecController.dart';
import 'history.dart';

VMIDC vmidc = VMIDC();
final platform = MethodChannel('com.example.watch/connection'); // Kotlin

void main() async {

  Get.put(RecController());

  WidgetsFlutterBinding.ensureInitialized();


  try {
    // final networkType = await platform.invokeMethod('getNetworkType');
    final networkType = 'bluetooth'; // test
    // print('연결된 네트워크: $networkType');

    if (networkType != "none") {
      Get.find<RecController>().setNetworkType(networkType);
    }

    // if (networkType == 'bluetooth') {
    //   vmidc.bluetoothReceiver((receivedData) async { // 폰에서 블루투스로 보내는 데이터 리시버
    //     // 받은 데이터 처리
    //     print("수신된 곡 정보: $receivedData");
    //     var song = jsonDecode(receivedData);
    //
    //     if (song['data'] != '' && song.containsKey('data')) {
    //       var result = await Get.to(() => SongInfo(song: song['data']));
    //
    //       if (result) {
    //         await vmidc.stop();
    //       }
    //
    //     }
    //   });
    // }

    if (networkType == 'bluetooth') {
      Get.find<RecController>().setNetworkType(networkType);
      Get.find<RecController>().initBluetoothReceiver(); // 리시버 등록
    }


  } catch (e) {
    print('네트워크 확인 실패: $e');
  }

  runApp(const MyApp());

}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static String? uid = '';


  @override
  State<MyApp> createState() => _MyAppState();
}
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 앱 생명주기 변경을 감지
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('assets/loading2_blue.gif'), context,);
      precacheImage(const AssetImage('assets/blue_logo.png'), context);
    });
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

  final PageController pageController = PageController(initialPage: 0);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(200, 200), // 워치용
      minTextAdapt: true,
      splitScreenMode: true,
      child: GetMaterialApp(
        home: PageView(
          scrollDirection: Axis.vertical,
          controller: pageController,
          children: [
            HomePage(pageController: pageController),
            History(pageController: pageController)
          ],
        ),
      ),
    );
  }
}



class HomePage extends StatefulWidget {
  final PageController pageController;
  const HomePage({super.key, required this.pageController});

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

  @override // 페이지가 종료될 때에만 리소스 해제
  void dispose()  {
    _vmidc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    List<Color> gradientColors = [
      Color.fromRGBO(62, 195, 255, 1.0), // 위쪽 색
      Color.fromRGBO(194, 40, 222, 1.0), // 아래쪽 색
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors
          )
        ),
        child: Stack(
          children: [
            // 화면 중앙: 기존 콘텐츠
            Center(
              child: GestureDetector(
                onTap: () {
                  if (Get.find<RecController>().networkType.value == 'none') {
                    Fluttertoast.showToast(msg: "네트워크 연결을 확인해주세요.");
                    return;
                  }
                  _asyncTask = asyncFunction();
                  Get.find<RecController>().setRec(true);
                },
                child: Obx(() {
                  return Get.find<RecController>().isRecognizing.value
                      ?
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [

                      SizedBox(width: MediaQuery.of(context).size.width * 0.6, child: Image.asset('assets/loading2_blue.gif', fit: BoxFit.contain,)),

                      Text(
                        '음원 인식중입니다...',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'NotoSansKR-Regular',
                        ),
                      ),
                    ],
                  )
                      :
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.6,
                    child: Image.asset(
                      'assets/blue_logo.png',
                      fit: BoxFit.contain,
                    ),
                  );
                }),
              ),
            ),

            // 화면 하단: 아래 화살표 아이콘
            Obx(() {
              return Get.find<RecController>().isRecognizing.value
                  ? SizedBox.shrink() // 아무것도 안 보여줌
                  : Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: IconButton(
                    onPressed: () {
                      widget.pageController.animateToPage(
                        1,
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon:  Icon(
                      Icons.keyboard_double_arrow_down,
                      color: Colors.white70,
                      size: 36,
                    )
                  ),
                ),
              );
            }),
          ],
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
