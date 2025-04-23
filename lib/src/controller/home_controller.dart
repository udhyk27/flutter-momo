import 'package:flutter/services.dart';
import 'package:get/get.dart';
// 홈 화면 상태관리
class HomeController extends GetxController {
  var stateVal = 1.obs; // 0: 검색 화면, 1: 기본 화면, 2: 실패 화면

  void changeState(int value) {
    stateVal.value = value;
    if (value == 2) {
      HapticFeedback.lightImpact();
    }
  }
}
