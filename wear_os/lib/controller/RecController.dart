import 'package:get/get.dart';

class RecController extends GetxController {
  var isRecognizing = false.obs;

  void setRec(bool value) {
    isRecognizing.value = value;
  }
}
