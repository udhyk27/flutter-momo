import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../main.dart';
import '../../services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_html/flutter_html.dart';

class TermsScreen extends StatefulWidget {
  final int gubun;
  const TermsScreen({super.key, required this.gubun});

  @override
  _TermsScreenState createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  String content = "로딩 중...";
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadTerms();
  }

  Future<void> _loadTerms() async {
    try {
      http.Response response = await http.get(Uri.parse(
        widget.gubun == 4 ? ApiService().termsUrl : ApiService().privacyUrl
      ));

      setState(() {
        content = response.body;
      });
    } catch (e) {
      print('통신 실패');
      setState(() {
        content = '데이터를 불러오지 못했습니다.';
      });
    }
  }

  @override
  void dispose() { // 해제 (유사 unset)
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget mainContent = Scaffold(
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
          ),
        ),
        child: Container(
          padding: EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                  color: Color.fromRGBO(245, 245, 245, 1.0), width: 2.0),
              left: BorderSide(
                  color: Color.fromRGBO(245, 245, 245, 1.0), width: 2.0),
              right: BorderSide(
                  color: Color.fromRGBO(245, 245, 245, 1.0), width: 2.0),
            ),
          ),
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: false,
            thickness: 5.0, // 스크롤바 두께 설정
            radius: Radius.circular(10), // 스크롤바 모서리 둥글게
            child: SingleChildScrollView(
              controller: _scrollController,
              child:
              // Text(
              //   termsContent,
              //   style: TextStyle(fontSize: 12),
                Html(data: content,
                  style: {
                    "body": Style(
                      fontSize: FontSize(13.0),  // 기본 글자 크기 설정
                    ),
                    "h3": Style(
                      fontSize: FontSize(14.0),  // h1 태그의 글자 크기
                    ),
                  },
                )
              // ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: GestureDetector(
        onTap: () {
          // Navigator.pop(context);
          context.read<MyAppState>().setPageIdx(3);
        },
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: Color.fromRGBO(245, 245, 245, 1.0),
            border: Border.all(width: 2.0, color: Colors.grey),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/momo_assets/icon_check.png',
                width: 20,
                height: 20,
              ),
              SizedBox(width: 10),
              Text('확인', style: TextStyle(fontFamily: 'NotoSansKR-Medium', fontSize: 15)),
            ],
          ),
        ),
      ),
    );

    if (Platform.isAndroid) {
      return SafeArea(child: mainContent);
    } else {
      return mainContent;
    }
  }
}
