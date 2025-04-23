import '/src/widgets/app_bar.dart';
import '/src/widgets/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home_screen.dart';
import 'history_screen.dart';
import 'chart_screen.dart';
import 'setting/setting_screen.dart';
import 'setting/theme_screen.dart';
import 'common/error_screen.dart';
import '/main.dart';  // MyAppState (상태 관리 클래스)

/**
 * 들어온 값에 따라 보여줄 페이지 지정
 * 상단, 하단바를 붙여 화면에 출력
 */

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {

  @override
  Widget build(BuildContext context) {

    final appState = context.watch<MyAppState>();

    int pageIdx = appState.pageIdx;
    int themeValue = appState.selectedValue;
    Widget page;
    ThemeData pageTheme;

    // 인덱스에 맞는 페이지 설정
    switch (pageIdx) {
      case 0:
        page = HistoryScreen();

        if (themeValue == 2) {
          pageTheme = ThemeData.dark().copyWith(
              scaffoldBackgroundColor: Colors.black,
              appBarTheme: AppBarTheme(backgroundColor: Colors.black)
          );
        } else {
          pageTheme = ThemeData.light().copyWith(
            scaffoldBackgroundColor: Color.fromRGBO(245, 245, 245, 1.0),
            appBarTheme: AppBarTheme(backgroundColor: Color.fromRGBO(245, 245, 245, 1.0))
          );
        }
      break;

      case 1:
        page = HomeScreen();

        // theme
        if(themeValue == 0) {
          pageTheme = ThemeData.light().copyWith(
            scaffoldBackgroundColor: Color.fromRGBO(255, 64, 129, 100),
          );
        } else if (themeValue == 1) { // ocean blue
          pageTheme = ThemeData.light().copyWith(
            scaffoldBackgroundColor: Color.fromRGBO(33, 177, 243, 100),
            // scaffoldBackgroundColor: Colors.blue,
          );
        } else { // dark mode
          pageTheme = ThemeData.dark().copyWith(
            scaffoldBackgroundColor: Color.fromRGBO(0, 0, 0, 1),
          );
        }
      break;


      case 2:
        page = ChartScreen();

        if (themeValue == 2) { // dark mode
          pageTheme = ThemeData.dark().copyWith(
              scaffoldBackgroundColor: Colors.black,
              appBarTheme: AppBarTheme(backgroundColor: Colors.black)
          );
        } else {
          pageTheme = ThemeData.light().copyWith(
              scaffoldBackgroundColor: Color.fromRGBO(245, 245, 245, 1.0),
              appBarTheme: AppBarTheme(backgroundColor: Color.fromRGBO(245, 245, 245, 1.0))
          );
        }
      break;

      case 3: // 설정
        page = SettingScreen();

        if(themeValue == 2) { // dark mode
          pageTheme = ThemeData.dark().copyWith(
              scaffoldBackgroundColor: Colors.black,
              appBarTheme: AppBarTheme(backgroundColor: Colors.black)
          );
        } else {
          pageTheme = ThemeData.light().copyWith(
            scaffoldBackgroundColor: Color.fromRGBO(245, 245, 245, 1.0),
            appBarTheme: AppBarTheme(backgroundColor: Color.fromRGBO(245, 245, 245, 1.0))
          );
        }
      break;

      // case 4: // 이용약관
      //   page = TermsScreen();
      //   pageTheme = ThemeData.light().copyWith(
      //       scaffoldBackgroundColor: Color.fromRGBO(245, 245, 245, 1.0),
      //       appBarTheme: AppBarTheme(backgroundColor: Color.fromRGBO(245, 245, 245, 1.0))
      //   );
      //   break;
      // case 5: // 개인정보 방침
      //   page = PrivacyScreen();
      //   pageTheme = ThemeData.light().copyWith(
      //       scaffoldBackgroundColor: Color.fromRGBO(245, 245, 245, 1.0),
      //       appBarTheme: AppBarTheme(backgroundColor: Color.fromRGBO(245, 245, 245, 1.0))
      //   );
      // break;

      case 6: // 화면 스타일

        page = ThemeScreen();

        if(themeValue == 2) { // dark mode
          pageTheme = ThemeData.dark().copyWith(
              scaffoldBackgroundColor: Colors.black,
              appBarTheme: AppBarTheme(backgroundColor: Colors.black)
          );
        } else {
          pageTheme = ThemeData.light().copyWith(
            scaffoldBackgroundColor: Color.fromRGBO(245, 245, 245, 1.0),
            appBarTheme: AppBarTheme(backgroundColor: Color.fromRGBO(245, 245, 245, 1.0))
          );

        }
      break;

      default:
        page = ErrorScreen();
        pageTheme = ThemeData.light().copyWith(
          primaryColor: Colors.red,
          appBarTheme: AppBarTheme(backgroundColor: Color.fromRGBO(241, 241, 241, 1.0)),
        );
    }

    return Theme(
      data: pageTheme,
      child: Scaffold(
        appBar: (pageIdx == 1) ? null : CustomAppBar(currentIndex: pageIdx),

        body: page,  // 현재 선택된 페이지

        bottomNavigationBar: (pageIdx == 3) || (pageIdx == 4) || (pageIdx == 5) ? null
            :
        CustomBtAppBar(
          currentIndex: pageIdx,
          onTabChange: (index) {
            context.read<MyAppState>().setPageIdx(index);
          },
        ),

        resizeToAvoidBottomInset: false,
      ),
    ) ;
  }
}
