import 'dart:io';

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
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final themeValue = context.watch<MyAppState>().selectedValue;

    // 항상 3개 아이템 반환, 선택 아이콘만 currentIndex에 따라 변경
    List<BottomNavigationBarItem> _getBottomNavItems() {
      return [
        BottomNavigationBarItem(
          icon: Image.asset(
            themeValue == 2
              ? (currentIndex == 0
                ? 'assets/momo_assets/icon_folder_on_reverse.png'
                : 'assets/momo_assets/icon_folder.png')
              : (currentIndex == 0
                ? 'assets/momo_assets/icon_folder_on.png'
                : 'assets/momo_assets/icon_folder.png'),
            width: 25,
            height: 25,
          ),
          label: '히스토리',
        ),
        BottomNavigationBarItem(
          icon: Image.asset(
            themeValue == 2
              ? (currentIndex == 1
                ? 'assets/momo_assets/icon_momosearch_on_reverse.png'
                : 'assets/momo_assets/icon_momosearch.png')
              : (currentIndex == 1
                ? 'assets/momo_assets/icon_momosearch_on.png'
                : 'assets/momo_assets/icon_momosearch.png'),
            width: 30,
            height: 30,
          ),
          label: '음악검색',
        ),
        BottomNavigationBarItem(
          icon: Image.asset(
            themeValue == 2
              ? (currentIndex == 2
                ? 'assets/momo_assets/icon_chart_on_reverse.png'
                : 'assets/momo_assets/icon_chart.png')
              : (currentIndex == 2
                ? 'assets/momo_assets/icon_chart_on.png'
                : 'assets/momo_assets/icon_chart.png'),
            width: 25,
            height: 25,
          ),
          label: '검색차트',
        ),
      ];
    }

    // currentIndex 안전 처리
    final safeIndex = currentIndex.clamp(0, 2);

    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: Platform.isAndroid,
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: themeValue == 2 ? Colors.black : Colors.white,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedItemColor: themeValue == 2 ? Colors.white : Colors.black,
          unselectedItemColor:
          themeValue == 2 ? Colors.white54 : Colors.black54,
          items: _getBottomNavItems(),
          currentIndex: safeIndex,
          onTap: onTabChange,
        ),
      ),
    );



  }
}
