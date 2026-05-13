import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/main.dart';

class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key});

  static const Color accentColor = Colors.deepOrange;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    int themeValue = appState.selectedValue;
    final bool isDark = themeValue == 2;

    final Color cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF222222);

    final List<Map<String, dynamic>> themes = [
      {'value': 0, 'label': '스트로베리'},
      {'value': 1, 'label': '오션블루'},
      {'value': 2, 'label': '다크모드'},
    ];

    return Scaffold(
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: themes.map((theme) {
            return InkWell(
              onTap: () => appState.setTheme(theme['value'] as int),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Radio<int>(
                      activeColor: accentColor,
                      value: theme['value'] as int,
                      groupValue: appState.selectedValue,
                      onChanged: (value) {
                        if (value != null) appState.setTheme(value);
                      },
                    ),
                    const SizedBox(width: 4),
                    Text(
                      theme['label'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'NotoSansKR-Regular',
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}