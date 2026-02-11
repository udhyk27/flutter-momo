import 'package:flutter/material.dart';

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
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: content == null
            ? null
            : Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actionsPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              cancelText,
              style: const TextStyle(
                color: Colors.grey, // 취소는 회색
                fontSize: 14,
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
                color: Colors.redAccent, // 확인은 빨간색
                fontSize: 14,
              ),
            ),
          ),
        ],
      );
    },
  );
}
