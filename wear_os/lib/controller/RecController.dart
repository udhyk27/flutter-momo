import 'dart:convert';

import 'package:get/get.dart';

import '../main.dart';
import '../song_info.dart';

class RecController extends GetxController {
  var isRecognizing = false.obs; // 녹음 중 여부
  var networkType = 'none'.obs;

  void setRec(bool value) {
    isRecognizing.value = value;
  }

  void setNetworkType(String type) {
    networkType.value = type;
  }

  void initBluetoothReceiver() {
    vmidc.bluetoothReceiver((receivedData) async {
      print("수신된 곡 정보: $receivedData");
      var song = jsonDecode(receivedData);

      if (song['data'] != '' && song.containsKey('data')) {
        var result = await Get.to(() => SongInfo(song: song['data']));
        if (result) {
          await vmidc.stop();
        }
      }
    });
  }
}
