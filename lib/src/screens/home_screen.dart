import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/main.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../controller/home_controller.dart';
import '../widgets/vmidc.dart';
import '../services/api_service.dart';

/**
 * stateVal
 * 0 => 노래 분석 중
 * 1 => 기본 화면
 * 2 => 분석 실패 화면
 */

// 홈 화면
bool firstRecord = true;


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final HomeController controller = Get.put(HomeController());
  final VMIDC _vmidc = VMIDC();

  Future<void>? _asyncTask; // 비동기 작업을 추적하기 위한 변수 (null 허용)

  @override
  void initState() {
    _vmidc.init();
    super.initState();
  }


  // 음성 인식 시작
  Future<void> asyncFunction() async {

    // 네트워크 연결 확인
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      return;
    }

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
      controller.changeState(2);
    }
  }

  // 비동기 작업 취소 함수
  // 검색중일 때 X 누르면 실행되는 함수
  void cancelAsyncTask() async {
    if (_asyncTask != null) {
      await _vmidc.stop(); // 녹음 중지
    }

    // X 또는 아이콘 누르면 실패 화면
    controller.changeState(2);
  }

  @override // 페이지가 종료될 때에만 리소스 해제
  void dispose()  {
    _vmidc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeValue = context.watch<MyAppState>().selectedValue;
    final isChecked = context.watch<MyAppState>().isChecked;
    final hasStarted = context.watch<MyAppState>().hasStarted;

    // 앱 실행하자마자 검색
    if (isChecked && !hasStarted) {

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        Future.delayed(const Duration(milliseconds: 500), () async {
          _asyncTask = asyncFunction(); // 비동기 작업 실행
        });
        await _asyncTask; // 비동기 작업 완료 기다리기
        context.read<MyAppState>().setHasStarted(true); // 상태 변경
      });
    }

    List<Color> gradientColors;

    if(themeValue == 1) { // ocean blue
      gradientColors = [
        Color.fromRGBO(62, 195, 255, 1.0), // 위쪽 색
        Color.fromRGBO(194, 40, 222, 1.0), // 아래쪽 색
      ];
    } else if (themeValue == 2) { // dark mode
      gradientColors = [
        Color.fromRGBO(0, 0, 0, 1.0), // 위쪽 색
        Color.fromRGBO(158, 158, 158, 1.0), // 아래쪽 색
      ];
    } else {
      gradientColors = [
        Color.fromRGBO(255, 143, 187, 1.0),
        Color.fromRGBO(255, 232, 240, 1.0),
      ];
    }

    return GetX<HomeController>(  // GetX로 전체 Scaffold 감싸기
      builder: (controller) => Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientColors,
            ),
          ),
          child: Column(
            children: [
              // 상태에 따라 왼쪽 상단 또는 오른쪽 상단에 아이콘 배치
              Align(
                alignment: controller.stateVal.value == 1 ? Alignment.topRight : Alignment.topLeft,
                child: Padding(
                  padding: controller.stateVal.value == 1
                      ? EdgeInsets.only(top: 50.0, right: 10)
                      : EdgeInsets.only(top: 50.0, left: 10),
                  child: controller.stateVal.value == 1
                      ?
                  IconButton(
                    onPressed: () {
                      context.read<MyAppState>().setPageIdx(3); // 설정 페이지 이동
                    },
                    icon: ColorFiltered(
                      colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      child: Image.asset('assets/settings.png', width: 25, height: 25),
                    ),
                  )
                      :
                  IconButton(
                      onPressed: () {
                        controller.stateVal.value == 0
                            ? cancelAsyncTask()
                            : controller.changeState(1);
                      }, // X 버튼 클릭 시 비동기 작업 X , 함수참조
                      icon: Icon(
                        Icons.close,
                        size: 25,
                        color: themeValue == 2 ? Colors.white : Colors.black,
                      )
                  ),
                ),
              ),

              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // 세로 중앙 정렬
                    children: [
                      controller.stateVal.value == 0
                          ? Text(
                        '노래 분석 중',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color:  themeValue == 0 ? Colors.black : Colors.white
                        ), // 텍스트 스타일
                      )
                          : controller.stateVal.value == 1 // 기본 화면
                          ? Text(
                        '지금 이 곡을 찾으려면 모모를 눌러주세요',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: themeValue == 0 ? Colors.black : Colors.white
                        ), // 텍스트 스타일
                      )
                          : Text(
                        '노래를 인식할 수 없습니다.',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color:  themeValue == 0 ? Colors.black : Colors.white
                        ), // 텍스트 스타일
                      ),

                      const SizedBox(height: 30), // 버튼과 텍스트 사이 간격

                      GestureDetector( // 터치 동작 처리
                        onTap: () async {
                          // 비동기 작업 호출
                          controller.stateVal.value == 0
                              ? cancelAsyncTask()
                              : _asyncTask = asyncFunction(); // 함수 호출
                        },
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: controller.stateVal.value == 0
                                  ? themeValue == 1 ? AssetImage('assets/loading1_blue2.gif') : AssetImage('assets/loading1_pink2.gif')
                                  : controller.stateVal.value == 1
                                  ? AssetImage( // 기본 화면
                                  themeValue == 1
                                      ? 'assets/momo_assets/blue_logo.png'
                                      : 'assets/momo_assets/berry_logo.png'
                              )
                                  : AssetImage( // 노래 인식 X 화면
                                  themeValue == 1
                                      ? 'assets/momo_assets/blue_logo.png'
                                      : 'assets/momo_assets/berry_logo.png'
                              ),
                              fit: BoxFit.cover, // 이미지를 버튼 크기에 맞게 꽉 채움
                            ),
                            borderRadius: BorderRadius.circular(110), // 원 모양을 유지
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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

_showDialog(BuildContext context) { // 휴대폰 권한설정으로 이동
  final themeValue = context.watch<MyAppState>().selectedValue;
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
                                color: themeValue == 2 ? Colors.white : Colors.black,
                                fontSize: 17
                            )
                        ),
                        TextSpan(
                            text: '허용',
                            style: TextStyle(
                                color: themeValue == 2 ? Colors.white : Colors.black,
                                fontSize: 17
                            )
                        ),
                        TextSpan(
                            text: ' 해주세요',
                            style: TextStyle(
                                color: themeValue == 2 ? Colors.white : Colors.black,
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