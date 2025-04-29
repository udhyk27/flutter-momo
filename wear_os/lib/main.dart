import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:wear_os/song_info.dart';
import 'package:wear_os/widgets/vmidc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});



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
          home: const HomePage(),
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
    // _vmidc.init();
    super.initState();
  }

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
      print('vmidc start');
      // await _vmidc.start(); // 녹음 시작
    } catch (e) {
      print('녹음 실패! ################## $e');
    }
  }

  void cancelAsyncTask() async {
    if (_asyncTask != null) {
      // await _vmidc.stop(); // 녹음 중지
    }

    // X 또는 아이콘 누르면 실패 화면
  }

  @override // 페이지가 종료될 때에만 리소스 해제
  void dispose()  {
    // _vmidc.dispose();
    super.dispose();
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(255, 195, 200, 1.0),
      body: Center(
        child: GestureDetector(
          onTap: () {
            // _asyncTask = asyncFunction();

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
                    style: TextStyle(color: Colors.white),
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
