import 'package:get/get.dart';

class RecController extends GetxController {
  var isRecognizing = false.obs; // 녹음 중 여부
  // var canStart = false.obs; 블루투스 권한 허용되었는지
  var networkType = 'none'.obs;

  void setRec(bool value) {
    isRecognizing.value = value;
  }

  // void setStart(bool value) {
  //   canStart.value = value;
  // }

  void setNetworkType(String type) {
    networkType.value = type;
  }
}
