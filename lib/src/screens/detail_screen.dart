import 'dart:convert';
import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '/main.dart';

import '../services/api_service.dart';
import 'package:http/http.dart' as http;
import '../model/api_detail_programs.dart';

/** 모모 방송 재생 정보 */
class DetailScreen extends StatefulWidget {
  final String title;
  final String image;
  final String artist;
  final String songId;
  final String deviceId;
  final String album;

  DetailScreen({
    required this.title,
    required this.image,
    required this.artist,
    required this.songId,
    required this.deviceId,
    required this.album,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {

  List<DetailProgram> detailProgram = [];
  bool isLoading = false;

  static const Color accentColor = Colors.deepOrange;

  Future<void> fetchData() async {
    try {
      http.Response programs_response = await http.get(Uri.parse('${ApiService().programsUrl}/json?id=${widget.songId}'));

      String programs_json = programs_response.body;
      List<dynamic> programsList = jsonDecode(programs_json);

      setState(() {
        detailProgram = programsList.map((item) => DetailProgram.fromJson(item as Map<String, dynamic>)).toList();
        isLoading = false;
      });
    } catch (e) {
      print('상세화면 API 통신 오류 ################# : $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    int themeValue = context.watch<MyAppState>().selectedValue;
    final bool isDark = themeValue == 2;

    final Color bgColor = isDark ? Colors.black : const Color(0xFFF5F5F5);
    final Color cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF222222);
    final Color subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final Color dividerColor = isDark ? const Color(0xFF424242) : const Color(0xFFEFEFEF);
    final Color imageBorderColor = isDark
        ? const Color(0xFFBDBDBD)
        : Colors.black.withOpacity(0.08);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        backgroundColor: bgColor,
        title: Text(
          '모모 방송 재생 정보',
          style: TextStyle(
            fontSize: 17,
            fontFamily: 'NotoSansKR-Medium',
            fontWeight: FontWeight.w600,
            color: textColor,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back, color: textColor, size: 22),
        ),
      ),
      body: isLoading
          ? Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            color: accentColor,
            strokeWidth: 2.0,
          ),
        ),
      )
          : SafeArea(
        bottom: Platform.isAndroid,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 5),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              /// 선택한 곡 정보
              Container(
                margin: const EdgeInsets.fromLTRB(0, 20, 0, 16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 1,
                          color: imageBorderColor,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: ExtendedImage.network(
                          widget.image,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          loadStateChanged: (state) {
                            if (state.extendedImageLoadState == LoadState.failed) {
                              return SizedBox(
                                width: 90,
                                height: 90,
                                child: Image.asset('assets/no_image.png'),
                              );
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 15,
                              fontFamily: 'NotoSansKR-Bold',
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.artist,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 13,
                              color: textColor.withOpacity(0.85),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.album,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: subTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Container(height: 1, color: dividerColor),

              Expanded(
                child: ListView.builder(
                  itemCount: detailProgram.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              height: 14,
                              color: accentColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '최신 방송내역',
                              style: TextStyle(
                                fontSize: 15,
                                fontFamily: 'NotoSansKR-Medium',
                                fontWeight: FontWeight.w700,
                                color: textColor,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final program = detailProgram[index - 1];
                    final bool isTv = program.type == 'TV';

                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: dividerColor, width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                width: 1,
                                color: imageBorderColor,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: ExtendedImage.network(
                                program.logo,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                loadStateChanged: (state) {
                                  if (state.extendedImageLoadState == LoadState.failed) {
                                    return SizedBox(
                                      width: 64,
                                      height: 64,
                                      child: Image.asset('assets/no_image.png'),
                                    );
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// TV / RADIO 뱃지
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isTv
                                        ? accentColor.withOpacity(0.12)
                                        : (isDark
                                        ? Colors.white12
                                        : const Color(0xFFF0F0F0)),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    isTv ? 'TV' : 'RADIO',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: isTv
                                          ? accentColor
                                          : (isDark
                                          ? Colors.grey[300]
                                          : Colors.grey[700]),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  program.channelName,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'NotoSansKR-Medium',
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  program.name,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'NotoSansKR-Medium',
                                    color: textColor.withOpacity(0.85),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  program.date,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: subTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}