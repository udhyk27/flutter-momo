
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import '/main.dart';

// import 'dart:convert';
// import '../../servicesapi_service.dart';
// import 'package:http/http.dart' as http;

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  _TermsScreenState createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  String termsContent = "로딩 중...";
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadTerms();
  }

  Future<void> _loadTerms() async {

    // try {
    //   http.Response response = await http.get(Uri.parse(ApiService.termsUrl));
    //
    //   print('test1 : ${response.body}');
    //   String test = jsonDecode(response.body);
    //
    //   print('test2 : $test');
    // } catch (e) {
    //   print('통신 실패');
    // }




    try {
      // assets/terms.txt 파일 읽기
      String loadedContent = await rootBundle.loadString('assets/terms.txt');
      setState(() {
        termsContent = loadedContent;
      });
    } catch (e) {
      print(e);
      setState(() {
        termsContent = "이용약관을 불러오는 데 실패했습니다.";
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
            ),
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
              Text('확인', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
