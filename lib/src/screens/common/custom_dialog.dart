import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/main.dart';

/// 공용 확인 / 취소 다이얼로그 (글자색으로만 구분)
Future<void> showConfirmDialog(
    BuildContext context, {
      String title = '확인',
      String? content,
      String cancelText = '취소',
      String confirmText = '확인',
      VoidCallback? onConfirm,
      bool barrierDismissible = false,
    }) {
  return showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) {
      final int themeValue = context.watch<MyAppState>().selectedValue;
      final bool isDark = themeValue == 2;

      final Color bgColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
      final Color textColor = isDark ? Colors.white : const Color(0xFF222222);
      final Color subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

      return AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: -0.2,
          ),
        ),
        content: content == null
            ? null
            : Text(
          content,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.5,
            color: textColor.withOpacity(0.85),
          ),
        ),
        actionsPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              cancelText,
              style: TextStyle(
                color: subTextColor,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm?.call();
            },
            child: Text(
              confirmText,
              style: const TextStyle(
                color: Colors.deepOrange,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    },
  );
}