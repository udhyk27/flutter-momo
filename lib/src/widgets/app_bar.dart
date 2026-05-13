import 'package:flutter/material.dart';
import '../../main.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../screens/home_screen.dart';

// 상단 바
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int currentIndex;

  const CustomAppBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    int themeValue = context.watch<MyAppState>().selectedValue;
    final bool isDark = themeValue == 2;

    final Color bgColor = isDark ? Colors.black : const Color(0xFFF5F5F5);
    final Color textColor = isDark ? Colors.white : const Color(0xFF222222);
    final Color iconColor = isDark ? Colors.grey[300]! : Colors.grey[700]!;

    String appBarTitle;

    switch (currentIndex) {
      case 0:
        appBarTitle = '히스토리';
        break;
      case 1:
        appBarTitle = '';
        break;
      case 2:
        appBarTitle = '검색차트';
        break;
      case 3:
        appBarTitle = '설정';
        break;
      case 4:
        appBarTitle = '이용약관';
        break;
      case 5:
        appBarTitle = '개인정보 처리방침';
        break;
      case 6:
        appBarTitle = '테마';
        break;
      default:
        appBarTitle = 'no widget for $currentIndex';
    }

    return AppBar(
      backgroundColor: bgColor,
      elevation: 0,
      scrolledUnderElevation: 0.0,
      title: Text(
        appBarTitle,
        style: TextStyle(
          fontSize: 17,
          fontFamily: 'NotoSansKR-Medium',
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: -0.2,
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        onPressed: () {
          if (currentIndex == 4 || currentIndex == 5) {
            context.read<MyAppState>().setPageIdx(3);
          } else {
            context.read<MyAppState>().setPageIdx(1);
          }
        },
        icon: Icon(
          (currentIndex == 4 || currentIndex == 5)
              ? Icons.close
              : Icons.arrow_back,
          size: 22,
          color: textColor,
        ),
      ),
      actions: [
        if (currentIndex != 3 &&
            currentIndex != 4 &&
            currentIndex != 5 &&
            currentIndex != 6)
          IconButton(
            onPressed: () {
              context.read<MyAppState>().setPageIdx(3);
            },
            icon: ColorFiltered(
              colorFilter: ColorFilter.mode(
                iconColor,
                BlendMode.srcIn,
              ),
              child: Image.asset(
                'assets/settings.png',
                width: 22,
                height: 22,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}