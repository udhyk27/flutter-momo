import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/main.dart';

class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // UI 갱신을 위해 watch 사용
    final appState = context.watch<MyAppState>();
    int themeValue = appState.selectedValue;

    return Scaffold(
      body: Container(
        margin: EdgeInsets.symmetric(horizontal: 10),
        height: 160,
        padding: EdgeInsets.only(left: 20, right: 20),
        decoration: BoxDecoration(
            color: themeValue == 2 ? Color.fromRGBO(90, 90, 90, 1.0) : Colors.white,
            borderRadius: BorderRadius.circular(30)
        ),
        child: ListView(
          padding: EdgeInsets.fromLTRB(MediaQuery.of(context).size.width * 0.05, 10, 10, 10),
          children: [
            Row(
              children: [
                Container(
                  child: Text('스트로베리'),
                ),
                Container(
                  child: Radio(
                    activeColor: Colors.blue,
                    value: 0,
                    groupValue: appState.selectedValue,
                    onChanged: ((value) {
                      appState.setTheme(value as int);
                    }),
                  ),
                )
              ],
            ),

            Row(
              children: [
                Container(
                  child: Text('오션블루'),
                ),
                Container(
                  child: Radio(
                    activeColor: Colors.blue,
                    value: 1,
                    groupValue: appState.selectedValue,
                    onChanged: ((value) {
                      appState.setTheme(value as int);
                    }),
                  ),
                )
              ],
            ),

            Row(
              children: [
                Container(
                  child: Text('다크모드'),
                ),
                Container(
                  child: Radio(
                    activeColor: Colors.blue,
                    value: 2,
                    groupValue: appState.selectedValue,
                    onChanged: ((value) {
                    appState.setTheme(value as int);
                    }),
                  )
                )
              ],
            ),

          ],
        ),
      )
    );
  }
}
