import 'package:get/get.dart';

class RecController extends GetxController {
  var isRecognizing = false.obs; // 녹음 중 여부
  var networkType = 'none'.obs;
  var showImage = false.obs;

  void setRec(bool value) {
    isRecognizing.value = value;
    if (value) {
      // 2초 후 이미지 보여주기
      Future.delayed(const Duration(seconds: 2), () {
        showImage.value = true;
      });
    } else {
      showImage.value = false;
    }
  }


  void setNetworkType(String type) {
    networkType.value = type;
  }
}
