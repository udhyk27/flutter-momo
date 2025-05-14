import 'package:get/get.dart';

class RecController extends GetxController {
  var isRecognizing = false.obs; // 녹음 중 여부
  var canStart = false.obs;

  void setRec(bool value) {
    isRecognizing.value = value;
  }

  void setStart(bool value) {
    canStart.value = value;
  }
}
