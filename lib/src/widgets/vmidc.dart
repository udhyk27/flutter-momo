// ignore_for_file: prefer_const_constructors, avoid_print, curly_braces_in_flow_control_structures, avoid_single_cascade_in_expression_statements
import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:ffi/ffi.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'package:momo_final/src/screens/song_info_screen.dart';
import 'package:path_provider/path_provider.dart';

import '../../main.dart';
import '../controller/home_controller.dart';
import '../model/api_search.dart';
import '../services/api_service.dart';
import 'dnabuf.dart';
import 'wavbuf.dart';

const srate = 16000;
const fftN = 2048;
const fftHop = 1000;
const qLen = 32;

class VMIDC {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder(logLevel: Level.error);
  var recCtrl = StreamController<Uint8List>();

  final HomeController controller = Get.find<HomeController>();
  late StreamSubscription _audioStream;
  final WaveBuf _wbuf = WaveBuf();
  final DnaBuf _dna = DnaBuf();

  Timer? _recordTimer;

  final Pointer<Uint8> _pcm = malloc.allocate<Uint8>(fftN * 2);

  final _ctrl = StreamController<Map>();
  Stream<Map> get stream => _ctrl.stream;
  bool get isRunning => _recorder.isRecording;
  Map _cur = {};

  // bool isOpened = false;
  // bool isNavigated = false; // 인식 성공해서 결과 화면으로 넘어갔는지 여부
  var num = 1;

  Future<bool> init() async {
    print('vmidc init');
    await _recorder.openRecorder(); // 오디오 세션 오픈

    _wbuf.clear();
    _dna.clear();

    // 마이크 데이터를 수신할 스트림을 설정
    _audioStream = recCtrl.stream.listen((buffer) async {

      _wbuf.push(buffer);

      if (_wbuf.length >= fftN * 2) {
        _wbuf.read(fftN * 2, _pcm);
        _dna.push(_pcm);
        _wbuf.pop(fftHop * 2);

        if (_dna.length == qLen) {

          // 여기서 HTTP 요청 호출
          Map m = await sendDnaToServer(_dna.pack());
          print('돌아온 값 :: $m');

          // 에러 메시지가 존재할 때
          if (m['err_msg'] != '') {
            print('error msg 1 / 음악 인식 STOP');
            await stop();
          }

          if (m['data'] != '' && m.containsKey('data')) {
            print('곡 인식 성공 !!');

            _ctrl.sink.add(m);
            _cur = m;

            final song = ApiSearch.fromJson(m['data']);
            await Get.to(() => SongInfoScreen(song: song));
            controller.changeState(1);
          }

          _dna.pop(qLen);
        }
      }
    });
    return true;
  }

  // HTTP 요청 함수
  Future<Map<String, dynamic>> sendDnaToServer(List<int> dna) async {

    final arr = { // 서버로 전송할 값
      'uid' : MyApp.uid,
      'req_times' : num,
      'max_req_times' : 5,
      'dna_data' : base64Encode(Uint8List.fromList(dna))
    };

    final body = jsonEncode(arr);

    // 헤더
    final Map<String, String> headers = {
      'Content-Type': 'application/octet-stream',
    };

    try {
      final response = await http.post(
        Uri.parse(ApiService.serverUrl),
        headers: headers,
        body: body,
      );

      // if (response.statusCode == 200) {
      //   num ++;
      //   return jsonDecode(response.body);
      // } else {
      //   return {'error': '서버 오류'};
      // }

      num ++;
      return jsonDecode(response.body);

    } catch (e) {
      print('HTTP 요청 중 오류 발생: $e');
      // await stop();
      return {'err_msg': '요청 실패'};
    }
  }


  // 녹음 시작
  Future<void> start() async {
    num = 1; // 몇 번째 녹음 데이터 전송인지

    controller.changeState(0); // 검색 중

    if (_recorder.isRecording) {
      print('start() 호출되었는데 녹음중이어서 Return');
      // await _recorder.stopRecorder();
      // await stop();
      return;
    }

    print('vmidc.start()  @@@@ 녹음 시작 @@@@@@@@@@@@@@@@@@@@@@@');

    try {

      // if (!isOpened) {
      //   print('첫 실행이므로 오디오 세션 열기 @@');
      //   // await _recorder.openRecorder();
      //   isOpened = true;
      // } else {
      //   print('재실행이므로 오디오 세션 유지한것 그대로 사용');
      // }

      await _recorder.startRecorder(
        toStream: recCtrl,
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: srate,
      );

      print('녹음이 정상적으로 시작됨!');

      _recordTimer = Timer(Duration(seconds: 15), () async {
        // 곡 인식하거나 서버 연결 실패했는데 녹음만 되고있을 때 방지
        if (_recorder.isRecording) {
          controller.changeState(2);
          // isNavigated = false;
          print('15초 경과 - 녹음 중이므로 자동 종료합니다.');
          await stop();
        }
      });

    } catch (e) {
      print('녹음 중 예외 발생 $e');
      controller.changeState(2);
      stop();
    }
  }

  Future<bool> stop() async {
    print('vmid.stop()');
    num = 1;

    if (!_recorder.isRecording) return false;

    await _recorder.stopRecorder();

    _recordTimer?.cancel();
    _recordTimer = null;

    _wbuf.clear();
    _dna.clear();

    if (controller.stateVal == 0) {
        controller.changeState(2);
    }

    return true;
  }



  Future<void> dispose() async {
    print('vmidc dispose');

    if (_recorder.isRecording) {
      print('녹음중이면 stop');
      await stop();
    }

    await _audioStream.cancel(); // 스트림 구독 리스닝 해제
    await _recorder.closeRecorder(); // 오디오 세션 닫기
    recCtrl.close(); // 스트림 컨트롤러 닫기
    malloc.free(_pcm); // 메모리 해제
  }
}
