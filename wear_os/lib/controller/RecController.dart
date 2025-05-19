import 'dart:convert';

import 'package:get/get.dart';

import '../history.dart';
import '../main.dart';
import '../song_info.dart';

class RecController extends GetxController {
  var isRecognizing = false.obs; // 녹음 중 여부
  var networkType = 'none'.obs;
  var historyList = <Map<String, String>>[].obs;

  void setRec(bool value) {
    isRecognizing.value = value;
  }

  void setNetworkType(String type) {
    networkType.value = type;
  }

  void initBluetoothReceiver() {
    vmidc.bluetoothReceiver((receivedData) async {
      print("(RecController) 수신된 곡 정보: $receivedData");
      var song = jsonDecode(receivedData);

      if (song is Map) { // DNA 작업일 경우

        print('bluetooth 수신 데이터는 맵');

        if (song.containsKey('data') && song['data'] != '') { // 곡 찾기 성공
          await Get.to(() => SongInfo(song: song['data']));
        } else if (song.containsKey('err_msg') && song['err_msg'] != '') { // 곡 찾기 실패
          print('(RecController) 곡 정보 찾기 실패 !!');
        } else {
          print('DNA 작업 실패');
        }

      } else if (song is List) { // 히스토리 리스트 받아왔을 경우

        print('bluetooth 수신 데이터는 리스트');

        if (song.isEmpty) { // 히스토리 목록 없을 경우
          print('(RecController) history List 비어있습니다.');
          historyList.value = [];
        } else { // 히스토리 목록 받아왔을 경우
          historyList.value = song.map<Map<String, String>>((item) {
            return {
              'image': item['IMAGE']?.toString() ?? '',
              'title': item['TITLE']?.toString() ?? '',
              'artist': item['ARTIST']?.toString() ?? '',
              'album': item['ALBUM']?.toString() ?? '',
              'date': item['date']?.toString() ?? ''
            };
          }).toList();

          print(historyList);
        }

      } else { // history del 일 경우
        print(' HISTORY DELETE ');
      }


      // if (song is Map && song['data'] != '' && song.containsKey('data')) {
      //   await Get.to(() => SongInfo(song: song['data']));
      // } else if (song['err_msg'] != '' && song.containKey('err_msg')) {
      //   print('(RecController) 곡 정보 찾기 실패 !!');
      // } else if (song is List) {
      //   print('(RecController) history List 수신받음 @@');
      //
      //   if (song.isEmpty) {
      //     print('(RecController) history List 비어있습니다.');
      //     historyList.value = [];
      //   } else {
      //     historyList.value = song.map<Map<String, String>>((item) {
      //       return {
      //         'image': item['IMAGE']?.toString() ?? '',
      //         'title': item['TITLE']?.toString() ?? '',
      //         'artist': item['ARTIST']?.toString() ?? '',
      //         'album': item['ALBUM']?.toString() ?? '',
      //         'song_id': item['SONG_ID']?.toString() ?? '',
      //         'date': item['date']?.toString() ?? '',
      //         'genre': item['GENRE']?.toString() ?? '',
      //         'count': item['count']?.toString() ?? '',
      //       };
      //     }).toList();
      //   }
      //
      //   print('(RecController) history List ::::: $historyList');
      //
      //
      // }
    });
  }
}
