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

  final Pointer<Uint8> _pcm = malloc.allocate<Uint8>(fftN * 2);

  final _ctrl = StreamController<Map>();
  Stream<Map> get stream => _ctrl.stream;
  bool get isRunning => _recorder.isRecording;
  Map _cur = {};

  bool isOpened = false;
  var num = 1;

  Future<bool> init() async {
    _wbuf.clear();
    _dna.clear();

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
          print('song_cnts :::: ${m['song_cnts']}');

          if (m['err_msg'] != '') {
            print('error msg O');
            stop();
          } else {
            print('error msg X');
          }





          if (m['data'] != '') {
            print('곡 인식 성공 !!');

            final song = ApiSearch.fromJson(m['data']);

            _ctrl.sink.add(m);
            _cur = m;

            Get.to(() => SongInfoScreen(song: song));

          }

          _dna.pop(qLen);
        }
      }
    });
    return true;
  }

  // HTTP 요청 함수
  Future<Map<String, dynamic>> sendDnaToServer(List<int> dna) async {
    final String serverUrl = 'http://mo-mo.co.kr/api/getdnasong';
    // final String serverUrl = 'http://10.84.255.9:8080';

    if (num == 6) { // 요청횟수 초과하면 녹음 종료
      await _recorder.stopRecorder();

      _wbuf.clear();
      _dna.clear();
      controller.changeState(2);
      print('요청횟수 초과 !!');
    }

    final arr = {
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
        Uri.parse(serverUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        num ++;
        return jsonDecode(response.body);
      } else {
        print('서버 요청 실패: ${response.statusCode}');
        controller.changeState(2);
        return {'error': '서버 오류'};
      }
    } catch (e) {
      print('HTTP 요청 중 오류 발생: $e');
      return {'error': '요청 실패'};
    }
  }


  // 녹음 시작
  Future<void> start() async {
    num = 1; // 몇 번째 녹음 데이터 전송인지

    controller.changeState(0);

    if (_recorder.isRecording) {
      print('녹음중이기 때문에 녹음 종료 #031');
      return;
    }

    print('vmidc.start()  @@@@ 녹음 시작 @@@@@@@@@@@@@@@@@@@@@@@');

    try {

      if (!isOpened) {
        print('첫 실행이므로 오디오 세션 열기 @@');
        await _recorder.openRecorder();
        isOpened = true;
      } else {
        print('재실행이므로 오디오 세션 유지한것 그대로 사용');
      }

      await _recorder.startRecorder(
        toStream: recCtrl,
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: srate,
      );

      print('녹음이 정상적으로 시작됨!');

      Future.delayed(Duration(seconds: 15), () async {
        if (_recorder.isRecording) {
          print('15초 경과 - 녹음 중이므로 자동 종료합니다.');
          await stop();
        } else {
          print('15초 경과 - 이미 녹음이 종료됨.');
        }
      });

    } catch (e) {
      print('녹음 중 예외 발생 $e');
      stop();
    }
  }

  Future<bool> stop() async {
    num = 1;

    if (!_recorder.isRecording) return false;
    print('vmid.stop()');

    await _recorder.stopRecorder();

    _wbuf.clear();
    _dna.clear();
    controller.changeState(1);

    return true;
  }

  Future<void> dispose() async {
    if (_recorder.isRecording) {
      print('녹음중이면 stop');
      await stop();
    }

    await _audioStream.cancel();
    await _recorder.closeRecorder();
    recCtrl.close();
    malloc.free(_pcm);
  }
}
