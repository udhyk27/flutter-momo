import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:pub_semver/pub_semver.dart';

import '../../services/api_service.dart';
import '/main.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

// 설정 페이지
class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  _SettingScreenState createState() => _SettingScreenState();
}
  class _SettingScreenState extends State<SettingScreen> {
    String updateMsg = '';
    String currentVersion = '';  // 앱 버전 저장

    @override
    void initState() {
      super.initState();
      _fetchAppVersion();  // 앱 버전 가져오는 함수 호출
    }

    // 앱 버전 가져오는 함수
    Future<void> _fetchAppVersion() async {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      // print('packageInfo Version :: ${packageInfo.version}');
      setState(() {
        currentVersion = packageInfo.version;  // 앱 버전 저장
      });
    }

    @override
    Widget build(BuildContext context) {
    int themeValue = context.watch<MyAppState>().selectedValue;
    Color textColor = themeValue == 2 ? Colors.white : Colors.black;

    Future<bool> launchPlayStore() async {
      final Uri url = Uri.parse(ApiService.storeUrl);

      // 버전 비교
      if (await canLaunchUrl(url)) {
        if (Version.parse(currentVersion) < Version.parse(ApiService.appVersion)) {
          await launchUrl(url);
          return false;
        } else {
          return true;
        }
      } else {
        // print('store url error');
        throw 'error';
      }
    }

  return ListView(
      padding: EdgeInsets.all(10),
      children: [
        Container(
          padding: EdgeInsets.only(top: 20, bottom: 20),
          decoration: BoxDecoration(
            color: themeValue == 2 ? Color.fromRGBO(90, 90, 90, 1.0) : Colors.white,
            borderRadius: BorderRadius.circular(16.0)
          ),
          child: Column(
            children: [
              Container(
                  decoration: BoxDecoration(border: Border(
                    bottom: BorderSide(color: Color.fromRGBO(245, 245, 245, 1.0))
                  )
                ),
                child:
                ListTile(
                  contentPadding: EdgeInsets.only(left:20, bottom: 10),
                  title: Text('고객센터', style: TextStyle(fontWeight: FontWeight.w600, color: textColor),),
                  leading: Image.asset('assets/momo_assets/setting_icon_headphone.png'),
                ),
              ),
              ListTile(
                title: Text('이용약관', style: TextStyle(fontSize: 15.0, color: textColor),),
                trailing: Icon(Icons.keyboard_arrow_right),
                onTap: () {
                  context.read<MyAppState>().setPageIdx(4);
                },
              ),
              ListTile(
                title: Text('개인정보 처리방침', style: TextStyle(fontSize: 15.0, color: textColor),),
                trailing: Icon(Icons.keyboard_arrow_right),
                onTap: () {
                  context.read<MyAppState>().setPageIdx(5);
                },
              ),
            ],
          ),
        ),
        SizedBox(height: 10),
        Container(
          padding: EdgeInsets.only(top: 20, bottom: 20),
          decoration: BoxDecoration(
          color: themeValue == 2 ? Color.fromRGBO(90, 90, 90, 1.0) : Colors.white,
            borderRadius: BorderRadius.circular(16.0)
          ),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color.fromRGBO(245, 245, 245, 1.0))
                  )
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.only(left:20, bottom: 10),
                  title: Text('앱 설정 및 정보', style: TextStyle(fontWeight: FontWeight.w600, color: textColor),),
                  leading: Image.asset('assets/momo_assets/setting_icon_mobile.png'),
                )
              ),
              ListTile(
                leading: Padding(
                  padding: EdgeInsets.zero,
                  child: Text('화면 스타일', style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.normal, color: textColor),),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      context.watch<MyAppState>().theme,
                      style: TextStyle(fontSize: 13.0),
                    ),
                  ],
                ),
                trailing: Icon(Icons.keyboard_arrow_right),
                onTap: () {
                  context.read<MyAppState>().setPageIdx(6);
                },
              ),
              ListTile(
                title: Text('앱 실행 시 바로 검색', style: TextStyle(fontSize: 15.0, color: textColor),),
                trailing: Switch.adaptive( // adaptive => android ios 에 맞는 스타일로 알아서 디자인됨
                  value: context.watch<MyAppState>().isChecked, // 상태 읽기
                  onChanged: (value) {
                    context.read<MyAppState>().toggleChecked(value);
                  },
                  activeColor: Colors.white,
                  activeTrackColor: Colors.blueAccent,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey,
                ),
              ),
              ListTile(
                title: Text('검색내역 삭제', style: TextStyle(fontSize: 15.0, color: textColor),),
                trailing: SizedBox(
                  width: 90,
                  height: 30,
                  child: TextButton(
                    onPressed: () async { // 검색목록 전체 삭제
                      try {
                        http.Response response = await http.get(Uri.parse('${ApiService.historyUrl}/json?uid=${MyApp.uid}&proc=del'));
                        if (response.statusCode == 200) {
                          showConfirm(context, "검색내역");
                        }
                      } catch (e) {
                        print('searched song delete all error');
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Color.fromRGBO(245, 245, 245, 1.0),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(5),
                        )
                      )
                    ),
                    child: Text('삭제', style: TextStyle(fontSize: 10)),
                  ),
                ),
              ),
              ListTile(
                title: Text('임시파일 삭제', style: TextStyle(fontSize: 15.0, color: textColor),),
                trailing: SizedBox(
                  width: 90,
                  height: 30,
                  child: TextButton(
                    onPressed: () {
                      showConfirm(context, "임시파일");
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Color.fromRGBO(245, 245, 245, 1.0),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(5),
                        )
                      )
                    ),
                    child: Text('삭제', style: TextStyle(fontSize: 10),),
                  ),
                ),
              ),
              ListTile(
                title: Text('현재버전 $currentVersion', style: TextStyle(fontSize: 15.0, color: textColor),),
                trailing: SizedBox(
                  width: 90,
                  height: 30,
                  child: TextButton(
                    onPressed: () async {
                      if (await launchPlayStore()) {
                        updateMsg = '최신버전입니다.';
                      } else {
                        updateMsg = '업데이트를 위해 스토어로 이동합니다.';
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            updateMsg,
                            style: TextStyle(color: Colors.white, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          duration: Duration(seconds: 2), // 문구 뜨는 시간
                          behavior: SnackBarBehavior.floating, // 떠 있는 효과
                          margin: EdgeInsets.only( // 화면 가운데로 설정
                            bottom: MediaQuery.of(context).size.height * 0.5,
                            left: MediaQuery.of(context).size.width / 4,
                            right: MediaQuery.of(context).size.width / 4,
                          ),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Color.fromRGBO(245, 245, 245, 1.0),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(5),
                        )
                      )
                    ),
                    child: Text('업데이트', style: TextStyle(fontSize: 10),),
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  // Dialog
  void showConfirm(BuildContext context, String msg) {
    int themeValue = Provider.of<MyAppState>(context, listen: false).selectedValue;

    double c_width = MediaQuery.of(context).size.width;
    double c_height = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // 모서리 둥글게
          backgroundColor: themeValue == 2 ? Color.fromRGBO(66, 66, 66, 1) : Colors.white,
          child: SizedBox(
            width: c_width * 0.75,
            height: c_height * 0.22,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목 영역
                SizedBox(
                  height: c_height * 0.13,
                  child: Center(
                    child: Text(
                      '$msg을 삭제하시겠습니까?',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black54),
                    ),
                  ),
                ),

                // 구분선 추가
                Divider(thickness: 1, height: 1, color: Colors.grey),

                // 버튼 영역
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(color: Colors.grey, width: 1)
                          )
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('취소',style: TextStyle(fontSize: 15, color: Color.fromRGBO(151, 151, 151, 1)),),
                        ),
                      ),
                    ),

                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${msg} 삭제 완료',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                              duration: Duration(seconds: 2), // 문구 뜨는 시간
                              behavior: SnackBarBehavior.floating, // 떠 있는 효과
                              margin: EdgeInsets.only( // 화면 가운데로 설정
                                bottom: c_height * 0.5,
                                left: c_width / 4,
                                right: c_width / 4,
                              ),
                            ),
                          );
                          Navigator.of(context).pop();
                        },
                        child: Text('삭제',style: TextStyle(fontSize: 15, color: Colors.deepOrange),),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    );


  }
}

