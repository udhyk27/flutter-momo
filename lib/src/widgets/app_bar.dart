import 'package:flutter/material.dart';
import '../../main.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
// 상단 바
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int currentIndex;

  const CustomAppBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    String appBarTitle;

    // currentIndex에 따라 title 설정
    switch (currentIndex) {
      case 0:
        appBarTitle = '히스토리';
        break;
      case 1:
        appBarTitle = '';
        break;
      case 2: // 차트 화면
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
      title: Text(
        appBarTitle,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,

      leading: IconButton(
          onPressed: () {
            if (currentIndex == 4 || currentIndex == 5) {
              // context.read<MyAppState>().setPageIdx(3);
              Navigator.pop(context);
            } else {
              context.read<MyAppState>().setPageIdx(1);
            }
          },
          icon: Icon(
              (currentIndex == 4 || currentIndex == 5) ? Icons.close : Icons.arrow_back
          )
      ),

      actions: [
        if (currentIndex != 3 && currentIndex != 4 && currentIndex != 5 && currentIndex != 6) // 설정 파일이 아닐 때만 아이콘 렌더링
        IconButton(
          onPressed: () {
            context.read<MyAppState>().setPageIdx(3);
          },
          icon: ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.grey, // 이미지 색상
              BlendMode.srcIn, // 이미지 색상을 변경
            ),
            child: Image.asset(
              'assets/settings.png', // 설정 아이콘
              width: 25,
              height: 25,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
