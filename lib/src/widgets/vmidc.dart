
// ignore_for_file: avoid_print, prefer_const_constructors, curly_braces_in_flow_control_structures, avoid_single_cascade_in_expression_statements, slash_for_doc_comments

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../controller/home_controller.dart';
import '../screens/song_info_screen.dart';
import 'wavbuf.dart';

import 'package:logger/logger.dart';


// minsdk 안드로이드 10 기준인 29로 잡아야함
// vmidc, wavbuf Class stop부분의 조건, 타이머 외에 자세한건 유정수부장님께

final HomeController controller = Get.find<HomeController>(); // 이미 존재하는 컨트롤러 참조

final DynamicLibrary nativeLibAnd = DynamicLibrary.open('libnative.so');
final DynamicLibrary nativeLibIos = DynamicLibrary.process();

final bool platform = Platform.isAndroid;

// PCM 데이터를 DNA 형식으로 변환
int Function(Pointer<Int16>, int, Pointer<Uint8>) pcm_to_dna = platform
  ? nativeLibAnd.lookup<NativeFunction<Int32 Function(Pointer<Int16>, Int32, Pointer<Uint8>)>>("pcm_to_dna").asFunction() // Android
  : nativeLibIos.lookup<NativeFunction<Int32 Function(Pointer<Int16>, Int32, Pointer<Uint8>)>>("pcm_to_dna").asFunction(); // iOS

const srate=22050; // 음원 디지털화 수치
const pcmLen=54968; //2.5sec qLen=37  (37-1)*fftHop+fftN
const pcmHop=22050; //1sec

bool isProcessing = false;

class VMIDC {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder(logLevel: Level.info);

  var recCtrl = StreamController<Uint8List>();

  late StreamSubscription _audioStream; // stream 구독
  late StreamSink<List> toStream; // stream 데이터 추가

  final WaveBuf _wbuf= WaveBuf();

  final Pointer<Uint8> _pcm= malloc.allocate<Uint8>(pcmLen * 2);
  final Pointer<Uint8> _dna= malloc.allocate<Uint8>(1024);

  late Socket _sock;

  String? _id;
  int? _score;

  Future<bool> init({required String ip, required int port, required StreamSink<List> sink}) async {

    toStream = sink;
    //////////////////// 소켓 연결 ////////////////////
    if (await _connect(ip, port) == false) {
      print('socket server false');
      return false;
    }

    // 소켓 listen
    // 메시지 수신
    _sock.listen((Uint8List msg) async {
      print('socket MSG ::::::::::::::::::: $msg');

      if (msg[0] == 1) { // search
        if (msg[1] != 1) { // 검색 실패
          toStream.add(['error']);
        }
        else {
          int n = msg[2];

          if (n == 1) {
            int score= msg[3];
            _score = score;
            _id = String.fromCharCodes(msg, 4, msg.length);
            print('id : $_id, score : $score');
            toStream.add([_id!, score]);
          }
        }
      }

      // print("# 5 #");

      if (msg[0] == 4) { // 종료 메시지
        // print("# 6 #");
        await _sock.close(); // 소켓 닫기
        _sock.destroy();
      }
    },
      onError: (e) => print('err: ${e.toString()}'),
      onDone: () => print('VMIDC onDone - 소켓 종료')
    );


    // stream listen
    // 오디오 데이터 수신
    try {
      await _recorder.openRecorder(); // 오디오 세션 오픈

      _audioStream = recCtrl.stream.listen((buffer) async {

        // print('녹음된 데이터 수신 @@@@@@@@@@@ 데이터 크기 ::::::::::::${buffer.data?.length}');
        _wbuf.push(buffer);

        if (_wbuf.length >= pcmLen * 2) {
          if (isProcessing) return;

          print('버퍼 충분 , DNA 변환 시작 @@@@@@@@@@@@@@@@@@@@@');
          _wbuf.read(pcmLen * 2, _pcm);

          isProcessing = true;  // 변환 중임을 표시

          if (_id == null) {
            // isProcessing = true; // 처리 시작
            int len = pcm_to_dna(_pcm.cast<Int16>(), pcmLen, _dna.cast<Uint8>());
            print('DNA 변환 완료 , 길이 :::::::::::::::::::::: $len');

            try {
              _sendQuery(len);
            } catch(Exception){
              print('_sendQuery 실행 도중 오류 발생 ########################');
            }
            _wbuf.pop(pcmHop * 2);

            isProcessing = false; // 처리 완료
          }
        }
      });

    } catch (e) {
      print('stream listen 실패 ################## $e');
      controller.changeState(2);
    }
    return true;
  }

  // 녹음 시작
  Future<void> start() async {
    // 녹음중이면 return
    if (_recorder.isRecording) {print('녹음중이기 때문에 녹음 종료 #031'); return;}

    _id = null;
    _score = null;
    print('vmidc.start()  녹음 시작 @@@@@@@@@@@@@@@@@@@@@@@');
    try {
      // 녹음 시작
      await _recorder.startRecorder(
        toStream: recCtrl,
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: srate,
      );

      print('녹음이 정상적으로 시작됨!');

    } catch (e) {
      print('녹음 중 예외 발생 $e');
      controller.changeState(2);
    }

  }

  Future<bool> stop() async {

    // // 화면 변경
    // print('stop() 호출됨 @@@@');
    if (!_recorder.isRecording) return false;

    // if (_id != null && _score! >= int.parse(ApiService.rateUrl)) { // 현재 50
    if (_id != null && _score! >= 40) { // 40 점 이상
      print('음악 인식 성공');
      print('id : $_id');
      print('score : $_score');

      controller.changeState(1); // 기본 화면
      // 화면 호출
      Get.to(() => SongInfoScreen(songId: _id!));

    } else {
      // print('음악인식 실패 또는 중단됨 ###########');
      HapticFeedback.vibrate(); // 진동
      controller.changeState(2); // 인식 실패 화면
    }

    if (!_recorder.isRecording) return false;

    await _recorder.stopRecorder();

    _wbuf.clear();
    isProcessing = false;

    return true;
  }

  Future<void> dispose() async {
    // print('vmidc.dispose() 호출');

    _sock.add([4]); //finish

    if (_recorder.isRecording) {
      print('녹음중이면 stop');
      await stop();
    }

    // 세션 닫음
    await _audioStream.cancel(); // 스트림 구독 취소
    _recorder.closeRecorder();
    recCtrl.close(); // StreamController 종료

    // 메모리 해제
    malloc.free(_pcm);
    malloc.free(_dna);
  }

  /*******************************************************************************/

  Future<bool> _connect(String ip, int port) async {
    try {
      _sock = await Socket.connect(ip, port, timeout: Duration(seconds: 5));
      // print('소켓 연결 성공 @@@@@@');

    } on Exception catch (e) {
      print('소켓연결 오류 발생 ########### ${e.toString()}');
      return false;
    }
    _sock.add(Uint8List.fromList('vmid333'.codeUnits));
    return true;
  }

  /*******************************************************************************/

  void _sendQuery(int len) {

    var msg= Uint8List(1+1+4+len);
    msg[0] = 1; //search
    msg[1] = 1; //rank
    msg.buffer.asByteData()..setInt32(2, len, Endian.little);
    for (int i = 0; i < len; i++)
      msg[6 + i] = _dna[i];
    _sock.add(msg);
    // print("sendQuery");

    // Timer(const Duration(seconds: 30), () { // 검색 30 초 후 중지
    //   if (!_recorder.isRecording) return;

      // if (controller.stateVal == 0) {
      //   stop();
      //   controller.changeState(2); // 실패 화면
      // }
      // print('30초 경과');
      // print('녹음 상태 :::::::::::: ${_recorder.isRecording}');

    // });
  }
}