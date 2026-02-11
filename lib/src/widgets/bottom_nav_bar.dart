import 'package:flutter/material.dart';
import '../../main.dart';

import 'package:provider/provider.dart';

// bottom bar
class CustomBtAppBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabChange;

  const CustomBtAppBar({
    required this.currentIndex,
    required this.onTabChange,
    super.key
  });

  @override
  Widget build(BuildContext context) {

    final themeValue = context.watch<MyAppState>().selectedValue;
    List<BottomNavigationBarItem> _getBottomNavItems() { // 바텀바 가져오는 리스트 형식의 함수

      if(themeValue == 2) { // 다크모드
        switch(currentIndex) {
          case 0: // history page
            return [
              BottomNavigationBarItem(icon: Image.asset('assets/momo_assets/icon_folder_on_reverse.png', width: 25, height: 25,), label: '히스토리'),
              BottomNavigationBarItem(icon: Image.asset('assets/momo_assets/icon_momosearch.png', width: 30, height: 30,), label: '음악검색'),
              BottomNavigationBarItem(icon: Image.asset('assets/momo_assets/icon_chart.png', width: 25, height: 25,), label: '검색차트'),
            ];
          case 1: // search page
            return [
              BottomNavigationBarItem(icon: Image.asset('assets/momo_assets/icon_folder.png', width: 25, height: 25,), label: '히스토리'),
              BottomNavigationBarItem(icon: Image.asset('assets/momo_assets/icon_momosearch_on_reverse.png', width: 30, height: 30,), label: '음악검색'),
              BottomNavigationBarItem(icon: Image.asset('assets/momo_assets/icon_chart.png', width: 25, height: 25,), label: '검색차트'),
            ];
          case 2: // chart page
            return [
              BottomNavigationBarItem(icon: Image.asset('assets/momo_assets/icon_folder.png', width: 25, height: 25,), label: '히스토리'),
              BottomNavigationBarItem(icon: Image.asset('assets/momo_assets/icon_momosearch.png', width: 30, height: 30,), label: '음악검색'),
              BottomNavigationBarItem(icon: Image.asset('assets/momo_assets/icon_chart_on_reverse.png', width: 25, height: 25,), label: '검색차트'),
            ];
          default: // search page
            return [
              BottomNavigationBarItem(icon: Image.asset('assets/momo_assets/icon_folder.png', width: 25, height: 25,), label: '히스토리'),
              BottomNavigationBarItem(icon: Image.asset('assets/momo_assets/icon_momosearch_on_reverse.png', width: 30, height: 30,), label: '음악검색'),
              BottomNavigationBarItem(icon: Image.asset('assets/momo_assets/icon_chart.png', width: 25, height: 25,), label: '검색차트'),
            ];
        }
      } else {
        switch(currentIndex) {
          case 0: // history page
            return [
              BottomNavigationBarItem(icon: Image.asset('assets/momo_assets/icon_folder_on.png', width: 25, height: 25,), label: '히스토리'),
              BottomNavigationBarItem(icon: Image.asset('assets/momo_assets/icon_momosearch.png', width: 30, height: 30,), label: '음악검색'),
              BottomNavigationBarItem(icon: Image.asset('assets/momo_assets/icon_chart.png', width: 25, height: 25,), label: '검색차트'),
            ];
          case 1: // search page
            return [
              BottomNavigationBarItem(icon: Image.asset('assets/momo_assets/icon_folder.png', width: 25, height: 25,), label: '히스토리'),
              BottomNavigationBarItem(icon: Image.asset('assets/momo_assets/icon_momosearch_on.png', width: 30, height: 30,), label: '음악검색'),
              BottomNavigationBarItem(icon: Image.asset('assets/momo_assets/icon_chart.png', width: 25, height: 25,), label: '검색차트'),
            ];
          case 2: // chart page
            return [
              BottomNavigationBarItem(icon: Image.asset('assets/momo_assets/icon_folder.png', width: 25, height: 25,), label: '히스토리'),
              BottomNavigationBarItem(icon: Image.asset('assets/momo_assets/icon_momosearch.png', width: 30, height: 30,), label: '음악검색'),
              BottomNavigationBarItem(icon: Image.asset('assets/momo_assets/icon_chart_on.png', width: 25, height: 25,), label: '검색차트'),
            ];
          default: // search page
            return [
              BottomNavigationBarItem(icon: Image.asset('assets/momo_assets/icon_folder.png', width: 25, height: 25,), label: '히스토리'),
              BottomNavigationBarItem(icon: Image.asset('assets/momo_assets/icon_momosearch_on.png', width: 30, height: 30,), label: '음악검색'),
              BottomNavigationBarItem(icon: Image.asset('assets/momo_assets/icon_chart.png', width: 25, height: 25,), label: '검색차트'),
            ];
        }
      }
    }

    return SafeArea(
        child: Container(
          height: 65,
          child: currentIndex < 3 ?
          BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: themeValue == 2 ? Colors.black : Colors.white,

            selectedLabelStyle: TextStyle(fontSize: 12),
            unselectedLabelStyle: TextStyle(fontSize: 12),

            selectedItemColor: themeValue == 2 ? Colors.white : Colors.black,
            unselectedItemColor: themeValue == 2 ? Colors.white : Colors.black,

            items: _getBottomNavItems(),
            currentIndex: currentIndex,
            onTap: onTabChange,
          ): SizedBox.shrink(),
        )
    );
  }
}