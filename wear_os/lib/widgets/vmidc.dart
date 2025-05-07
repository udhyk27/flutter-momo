// ignore_for_file: prefer_const_constructors, avoid_print, curly_braces_in_flow_control_structures, avoid_single_cascade_in_expression_statements
import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;

import '../main.dart';
import 'dnabuf.dart';
import 'wavbuf.dart';

const srate = 16000;
const fftN = 2048;
const fftHop = 1000;
const qLen = 32;

class VMIDC {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder(logLevel: Level.error);
  var recCtrl = StreamController<Uint8List>();

  // final HomeController controller = Get.find<HomeController>();
  late StreamSubscription _audioStream;
  final WaveBuf _wbuf = WaveBuf();
  final DnaBuf _dna = DnaBuf();
  Timer? _recordTimer;

  final Pointer<Uint8> _pcm = malloc.allocate<Uint8>(fftN * 2);

  final _ctrl = StreamController<Map>();
  Stream<Map> get stream => _ctrl.stream;
  bool get isRunning => _recorder.isRecording;
  Map _cur = {};

  var num = 1;

  Future<bool> init() async {
    print('vmidc init');
    await _recorder.openRecorder(); // 오디오 세션 오픈

    _wbuf.clear();
    _dna.clear();

    // 마이크 데이터를 수신할 스트림을 설정
    _audioStream = recCtrl.stream.listen((buffer) async {
      // print('data received at: ${DateTime.now()} - buffer size: ${buffer.length}');
      //  iOS일때 180ms에 한번씩 들어오는 데이터 청크 3개로 나누어 dna에 각각 담아서 버퍼에 쌓음

      // iOS는 큰 청크로 들어오므로 작은 청크로 나눔
      if (Platform.isIOS && buffer.length > fftHop * 2) {
        // 큰 버퍼를 작은 청크로 분할하여 처리
        int offset = 0;
        while (offset < buffer.length) {
          int chunkSize = min(fftHop * 2, buffer.length - offset);
          Uint8List chunk = buffer.sublist(offset, offset + chunkSize);

          _wbuf.push(chunk);
          _processBuffer(); // 버퍼 처리

          offset += chunkSize;
        }
      } else {
        // Android => 20ms에 한번씩 들어옴, dna에 각각 넣어 버퍼에 쌓음
        _wbuf.push(buffer);
        _processBuffer();
      }
    });

    return true;
  }

  // 버퍼 처리 로직을 별도 메서드로 분리
  void _processBuffer() {
    if (_wbuf.length >= fftN * 2) {
      _wbuf.read(fftN * 2, _pcm);
      _dna.push(_pcm);
      _wbuf.pop(fftHop * 2);

      // print('dna length :: ${_dna.length}');

      if (_dna.length == qLen) {
        print('32개의 DNA 쌓임, 서버로 전송 !!');
        _sendDnaToServerAndProcess();
      }
    }
  }

  // DNA 서버 전송 및 처리 로직
  Future<void> _sendDnaToServerAndProcess() async {
    print('DNA ${qLen}개 도달: ${DateTime.now()}');
    // 여기서 HTTP 요청 호출
    Map m = await sendDnaToServer(_dna.pack());
    // print('API 응답 시간: ${DateTime.now()}');
    print('돌아온 값 :: $m');
    // print('dna.length: ${_dna.length}, elapsed: ${DateTime.now()}');

    // 에러 메시지가 존재할 때
    if (m['err_msg'] != '') {
      print('error msg 1 / 음악 인식 STOP');
      await stop();
    }

    if (m['data'] != '' && m.containsKey('data')) {
      print('찾기까지 걸린 종료시간 :: ${DateTime.now()}');
      print('곡 인식 성공 !!');

      print('결과값 ::: ${m['data']}');

      print('녹음중 여부::${_recorder.isRecording}');
      HapticFeedback.lightImpact();

      _ctrl.sink.add(m);
      _cur = m;

      // final song = m['data']; => 모델 없이 이렇게 받아야 할 듯

      // final song = ApiSearch.fromJson(m['data']);
      // await Get.to(() => SongInfoScreen(song: song));
      // controller.changeState(1);
    }
    _dna.pop(qLen);
  }

  // HTTP 요청 함수
  Future<Map<String, dynamic>> sendDnaToServer(List<int> dna) async {

    final arr = { // 서버로 전송할 값
      'uid' : MyApp.uid,
      'req_times': num,
      'dna_data': base64Encode(Uint8List.fromList(dna))
    };

    final body = jsonEncode(arr);

    // 헤더
    final Map<String, String> headers = {
      'Content-Type': 'application/octet-stream',
    };

    try {
      final response = await http.post(
        Uri.parse('210.97.52.157'),
        headers: headers,
        body: body,
      ).timeout(Duration(seconds: 5), // 서버로부터 5초간 응답이 없을 시
          onTimeout: () {
            return http.Response(
                jsonEncode({'err_msg': 'TIME OUT'}), 408); // String, statusCode
          });
      num++;
      print('response ::::: ${jsonDecode(response.body)}');
      return jsonDecode(response.body);
    } catch (e) {
      print('HTTP 요청 중 오류 발생: $e');
      return {'err_msg': '요청 실패'};
    }
  }

  // 녹음 시작
  Future<void> start() async {
    print('찾기까지 걸린 시작시간 :: ${DateTime.now()}');
    num = 1; // 몇 번째 녹음 데이터 전송인지

    if (_recorder.isRecording) {
      print('start() 호출되었는데 녹음중');
      await stop();
    }
    // controller.changeState(0); // 검색 중

    try {
      // await _recorder.startRecorder(
      //   toStream: recCtrl,
      //   codec: Codec.pcm16,
      //   numChannels: 1,
      //   sampleRate: srate,
      // );

      print('녹음이 정상적으로 시작됨!');

      _recordTimer = Timer(Duration(seconds: 20), () async {
        // 곡 인식하거나 서버 연결 실패했는데 녹음만 되고있을 때 방지
        if (_recorder.isRecording) {
          print('15초 경과 - 녹음 중이므로 자동 종료합니다.');
          await stop();
        }
      });
    } catch (e) {
      print('녹음 중 예외 발생 $e');
    }
  }

  Future<void> stop() async {
    print('vmid.stop()');
    num = 1;

    if (!_recorder.isRecording) return;

    _recordTimer?.cancel();
    _recordTimer = null;

    await _recorder.stopRecorder();

    _wbuf.clear();
    _dna.clear();

    // if (controller.stateVal == 0) {
    //     controller.changeState(2);
    //   }
    // }
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

