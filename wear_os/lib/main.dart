import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:wear_os/song_info.dart';
import 'package:wear_os/widgets/vmidc.dart';
import 'package:http/http.dart' as http;

import 'history.dart';
void main() {
  runApp(const MyApp());
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static String? uid = '';


  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(200, 200), // 워치용
      minTextAdapt: true,
      splitScreenMode: true,
      child: ChangeNotifierProvider(
        create: (_) => RecognitionState(),
        child: MaterialApp(
          home: PageView(
            controller: PageController(initialPage: 0),
            children: [
              HomePage(),
              History()
            ],
          ),
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



  // Future<void> sendData() async { // test
  //   final arr = {
  //     'uid': MyApp.uid,
  //     'req_times': 1,
  //     'dna_data': 'ZGOOwxe/1f9dpeFRP3jpy1/+0+EefLXJH2ax1D1c6csXxvVkPXKY3xfH8ewddK3JD8fxbDx26eVP53Fsfrra58bHYWR+dKlOZ0dxyT/y2M2nx3NsffKaSe7Fcew+fNFNs5VxHjV16Uv30HEePdShSbdhYR41dK3bJ4LyXDF2i1s3ZvQfUeTsw7dBs7ZVJq1Ht0Y0R8G0hFN3FLrt1Tb2WzMB8aZnNs/NPwUitnNoV0u3YHLtW6TlS7Nk8+xWunFjd0Fg6tjQ0Nm/SGnKVnnL27cJMu3XUcNu92Bw6aNgU2fWyvP41rGzyWbgkPufWrPbzsQo0IdM81mDzOTQ3tz601eB4ptsW1O9ORwPHn7AB3i2J8uZY9pjuPszUc0DdItZ0iabmTvH65yeK1mZB+WqdPNtM5ljm7OQfgGangdnODFyy2Yz50mWlL5JmpgT8xgW0qeZmWNO0rg3Q1vdob04EnIfOjNn2pKs/xgf+YN6PB9VH253ZrNSlP8YmdwBOzg22iabmWPL3Ji/2F+YCT88W25PmDtnXbucX9gamYmeJT1zHy57ZtJjnD/IllkFOyQd9iaynUvaW5h/7Bn5AB0se3cLszlnym24r2QblTPTnBB3LTA5I8pymD9sSvUgk4wQNyaamWPKwog/zUCdIZucFCfbOlrmStKYXwxKkwjdrBRnN7nRZMuSuDdPGzM024wUZDKeVmnGk5ifxRmZhUecMmYzuku6yJaYP2cZkTjXLRF2tixPJkvDmA9vIbNt1y0zNRqZjUlaM/gPLyOl2XesVssaVl0q02I4J48xAlVWjirLOj2MKVsylD/PVRUPXbMyzGpmy0o3m5Yv32AcjzYzdshzCOlF01OZrz8loFU3Jmwwsim1avjJmJ/vZBKnXOY4KqqZMU55dra/z1EUDda7ci/OSDkvyz2UL68UpoBfWzYekkBrBOvxmi9rpuiF3aA3komIMYbD55R/OCj2qNOqJJLJmDkH2ciw/3RI6UgMqyWYcbK7xFeDsx9mafkQtIg'
  //   };
  //
  //   final body = jsonEncode(arr);
  //   final headers = {'Content-Type': 'application/json'};
  //
  //   try {
  //     final response = await http.post(
  //       Uri.parse('http://www.mo-mo.co.kr/api/getdnasong'), // URL 업데이트
  //       headers: headers,
  //       body: body,
  //     ).timeout(
  //       Duration(seconds: 5),
  //       onTimeout: () => http.Response(jsonEncode({'err_msg': 'TIME OUT'}), 408),
  //     );
  //
  //     print('Response: ${jsonDecode(response.body)}');
  //   } catch (e) {
  //     print('Error: $e');
  //   }
  // }





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
    }
  }

  void cancelAsyncTask() async {
    if (_asyncTask != null) {
      await _vmidc.stop(); // 녹음 중지
    }

    // X 또는 아이콘 누르면 실패 화면
  }

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
            // sendData(); // TEST 용
            _asyncTask = asyncFunction();

            context.read<RecognitionState>().setRec(true);

            Future.delayed(const Duration(seconds: 1), () {
              context.read<RecognitionState>().setRec(false);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SongInfo()),
              );
            });

          },
          child: Consumer<RecognitionState>(
            builder: (context, state, child) {
              return state._isRecognizing
                ? // 녹음 켜지면
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 20),
                  Text(
                    '음원 인식중입니다...',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'NotoSansKR-Regular'
                    ),
                  ),
                ],
              )
                : // 녹음종료 임시용
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

class RecognitionState extends ChangeNotifier {

  bool _isRecognizing = false;

  void setRec(bool value) {
    _isRecognizing = value;
    notifyListeners();
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
