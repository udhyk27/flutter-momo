import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:pub_semver/pub_semver.dart';

import '../../services/api_service.dart';
import '../common/custom_dialog.dart';
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
  String currentVersion = '';

  static const Color accentColor = Colors.deepOrange;

  @override
  void initState() {
    super.initState();
    _fetchAppVersion();
  }

  Future<void> _fetchAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      currentVersion = packageInfo.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    int themeValue = context.watch<MyAppState>().selectedValue;
    final bool isDark = themeValue == 2;

    final Color cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF222222);
    final Color subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final Color dividerColor =
    isDark ? const Color(0xFF3A3A3A) : const Color(0xFFEFEFEF);
    final Color buttonBgColor =
    isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF7F7F7);

    Future<bool> launchPlayStore() async {
      final Uri url = Uri.parse(ApiService().storeUrl);

      if (await canLaunchUrl(url)) {
        if (Version.parse(currentVersion) < Version.parse(ApiService().appVersion)) {
          await launchUrl(url);
          return false;
        } else {
          return true;
        }
      } else {
        throw 'error';
      }
    }

    /// 섹션 헤더
    /// 섹션 헤더
    Widget sectionHeader(String title, String iconPath) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: Row(
          children: [
            Image.asset(iconPath, width: 24, height: 24),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'NotoSansKR-Medium',
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: textColor,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      );
    }

    /// 작은 액션 버튼 (삭제/업데이트)
    Widget smallActionButton(String label, VoidCallback onPressed) {
      return SizedBox(
        width: 70,
        height: 28,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            backgroundColor: buttonBgColor,
            foregroundColor: accentColor,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
              side: BorderSide(color: dividerColor, width: 1),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        /// 고객센터 섹션
        Container(
          padding: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sectionHeader('고객센터', 'assets/momo_assets/setting_icon_headphone.png'),
              Container(height: 1, color: dividerColor),
              ListTile(
                dense: true,
                title: Text(
                  '이용약관',
                  style: TextStyle(
                    fontFamily: 'NotoSansKR-Regular',
                    fontSize: 13.5,
                    color: textColor,
                  ),
                ),
                trailing: Icon(Icons.keyboard_arrow_right,
                    size: 20, color: subTextColor),
                onTap: () {
                  context.read<MyAppState>().setPageIdx(4);
                },
              ),
              ListTile(
                dense: true,
                title: Text(
                  '개인정보 처리방침',
                  style: TextStyle(
                    fontFamily: 'NotoSansKR-Regular',
                    fontSize: 13.5,
                    color: textColor,
                  ),
                ),
                trailing: Icon(Icons.keyboard_arrow_right,
                    size: 20, color: subTextColor),
                onTap: () {
                  context.read<MyAppState>().setPageIdx(5);
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        /// 앱 설정 및 정보 섹션
        Container(
          padding: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sectionHeader('앱 설정 및 정보', 'assets/momo_assets/setting_icon_mobile.png'),
              Container(height: 1, color: dividerColor),

              /// 화면 스타일
              ListTile(
                dense: true,
                title: Text(
                  '화면 스타일',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontFamily: 'NotoSansKR-Regular',
                    color: textColor,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.watch<MyAppState>().theme,
                      style: TextStyle(fontSize: 12.5, color: subTextColor),
                    ),
                    Icon(Icons.keyboard_arrow_right,
                        size: 20, color: subTextColor),
                  ],
                ),
                onTap: () {
                  context.read<MyAppState>().setPageIdx(6);
                },
              ),

              /// 앱 실행 시 바로 검색
              ListTile(
                dense: true,
                title: Text(
                  '앱 실행 시 바로 검색',
                  style: TextStyle(
                    fontFamily: 'NotoSansKR-Regular',
                    fontSize: 13.5,
                    color: textColor,
                  ),
                ),
                trailing: Switch.adaptive(
                  value: context.watch<MyAppState>().isChecked,
                  onChanged: (value) {
                    context.read<MyAppState>().toggleChecked(value);
                  },
                  activeColor: Colors.white,
                  activeTrackColor: accentColor,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey[400],
                ),
              ),

              /// 검색내역 삭제
              ListTile(
                dense: true,
                title: Text(
                  '검색내역 삭제',
                  style: TextStyle(
                    fontFamily: 'NotoSansKR-Regular',
                    fontSize: 13.5,
                    color: textColor,
                  ),
                ),
                trailing: smallActionButton('삭제', () {
                  showConfirm(context, 0);
                }),
              ),

              /// 임시파일 삭제
              ListTile(
                dense: true,
                title: Text(
                  '임시파일 삭제',
                  style: TextStyle(
                    fontFamily: 'NotoSansKR-Regular',
                    fontSize: 13.5,
                    color: textColor,
                  ),
                ),
                trailing: smallActionButton('삭제', () {
                  showConfirm(context, 1);
                }),
              ),

              /// 현재버전
              ListTile(
                dense: true,
                title: Row(
                  children: [
                    Text(
                      '현재버전',
                      style: TextStyle(
                        fontFamily: 'NotoSansKR-Regular',
                        fontSize: 13.5,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currentVersion,
                      style: TextStyle(
                        fontFamily: 'NotoSansKR-Regular',
                        fontSize: 12.5,
                        color: subTextColor,
                      ),
                    ),
                  ],
                ),
                trailing: smallActionButton('업데이트', () async {
                  if (await launchPlayStore()) {
                    updateMsg = '최신버전입니다.';
                  } else {
                    updateMsg = '업데이트를 위해 스토어로 이동합니다.';
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        updateMsg,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.only(
                        bottom: MediaQuery.of(context).size.height * 0.5,
                        left: MediaQuery.of(context).size.width / 4,
                        right: MediaQuery.of(context).size.width / 4,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Dialog
  void showConfirm(BuildContext context, int index) {
    String msg = index == 0 ? '검색내역' : '임시파일';

    showConfirmDialog(
      context,
      title: '$msg을 삭제하시겠습니까?',
      cancelText: '취소',
      confirmText: '삭제',
      onConfirm: () async {
        try {
          http.Response? response;
          if (index == 0) {
            response = await http.get(
              Uri.parse('${ApiService().historyUrl}/json?uid=${MyApp.uid}&proc=del'),
            );
          }

          if (response != null && response.statusCode == 200) {
            final c_width = MediaQuery.of(context).size.width;
            final c_height = MediaQuery.of(context).size.height;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '$msg 삭제 완료',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.only(
                  bottom: c_height * 0.5,
                  left: c_width / 4,
                  right: c_width / 4,
                ),
              ),
            );
          }
        } catch (e) {
          print('delete error: $e');
        }
      },
    );
  }
}