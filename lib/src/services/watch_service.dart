import 'dart:typed_data';
import 'package:flutter/services.dart';

class WatchService {
  static final WatchService _instance = WatchService._internal();
  factory WatchService() => _instance;
  WatchService._internal();

  final EventChannel _eventChannel = const EventChannel('watch_channel');

  void Function()? onWatchMessageReceived;
  void Function(Uint8List audioData)? onAudioDataReceived; // 🎤 오디오 데이터 콜백 추가

  void init() {
    _eventChannel.receiveBroadcastStream().listen((event) {
      if (event is String && event == "watchRec") {
        print("iOS에서 'watchRec' 신호 받음!");
        onWatchMessageReceived?.call();
      } else if (event is Uint8List) {
        print("iOS에서 오디오 데이터 수신 완료!");
        onAudioDataReceived?.call(event);
      }
    }, onError: (error) {
      print("워치 이벤트 오류: $error");
    });
  }
}
