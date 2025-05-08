import 'package:flutter/services.dart';

class BluetoothReceiver {
  static const MethodChannel _channel = MethodChannel('com.example.watch/connection');

  static void init() {
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == "onDataReceived") {
        String receivedData = call.arguments;
        print('폰 Flutter에서 수신 !!');
        print("수신된 데이터: $receivedData");
        // 여기서 받은 데이터를 처리하면 됩니다.
      }
    });
  }
}
