import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../widgets/vmidc.dart';

class BluetoothReceiver {
  static const MethodChannel _channel = MethodChannel('com.example.clone_momo_app/bluetooth');

  static Future<void> init(Function(Map<String, dynamic>) onDataReceived) async {
    try {
      _channel.setMethodCallHandler((MethodCall call) async {
        if (call.method == "onBluetoothData") {
          String receivedData = call.arguments;
          print("폰 Flutter 수신된 데이터: $receivedData");

          final headers = {'Content-Type': 'application/json'};
          final response = await http.post(
            Uri.parse("https://www.mo-mo.co.kr/api/getdnasong"),
            headers: headers,
            body: receivedData,
          ).timeout(
            Duration(seconds: 5),
            onTimeout: () => http.Response(jsonEncode({'err_msg': 'TIME OUT'}), 408),
          );

          final result = jsonDecode(response.body);
          print("서버와 통신한 값 :: $result");

          onDataReceived(result); // 여기서 데이터를 외부로 전달함
        }
      });
    } catch (e) {
      onDataReceived({'success': false, 'error': '예상치 못한 에러: $e'});
    }
  }
}