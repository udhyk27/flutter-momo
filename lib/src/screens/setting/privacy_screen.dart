import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';

import '/main.dart';

// 이용약관
class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  _PrivacyScreenState createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  String termsContent = "로딩 중...";
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadTerms();
  }

  Future<void> _loadTerms() async {
    try {
      // assets/terms.txt 파일 읽기
      String loadedContent = await rootBundle.loadString('assets/privacy.txt');
      setState(() {
        termsContent = loadedContent;
      });
    } catch (e) {
      setState(() {
        termsContent = "개인정보 처리방침을 불러오는 데 실패했습니다.";
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 10),
        padding: EdgeInsets.only(left: 20, right: 20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            )
        ),
        child: Container(
          padding: EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            border: Border(
                top: BorderSide(
                    color: Color.fromRGBO(245, 245, 245, 1.0), width: 2.0
                ),
                left: BorderSide(
                    color: Color.fromRGBO(245, 245, 245, 1.0), width: 2.0
                ),
                right: BorderSide(
                    color: Color.fromRGBO(245, 245, 245, 1.0), width: 2.0
                )
            ),
          ),
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: false,
            thickness: 5.0, // 스크롤바 두께 설정
            radius: Radius.circular(10), // 스크롤바 모서리 둥글게
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Text(
                termsContent,
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: GestureDetector(
        onTap: () {
          context.read<MyAppState>().setPageIdx(3);
        },
        child: Container(
          height: 70,
          decoration: BoxDecoration(
              color: Color.fromRGBO(245, 245, 245, 1.0),
              border: Border.all(width: 2.0, color: Colors.grey),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              )
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/momo_assets/icon_check.png',
                width: 35,
                height: 35,
              ),
              SizedBox(width: 20),
              Text('확인', style: TextStyle(fontWeight: FontWeight.w700),),
            ],
          ),
        ),
      ),
    );

  }
}
