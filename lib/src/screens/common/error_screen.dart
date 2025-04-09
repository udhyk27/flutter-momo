import 'package:flutter/material.dart';

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Error',
          style: TextStyle(
              color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w900
          ),
        ),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Text(
          '잘못된 페이지 접근입니다.',
          style: TextStyle(fontSize: 18, color: Colors.red),
        ),
      ),
    );
  }
}
