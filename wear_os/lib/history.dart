import 'dart:convert';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:http/http.dart' as http;

import 'main.dart';

class History extends StatefulWidget {
  History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  @override
  void initState() {
    super.initState();
    fetchData(); // Api Data
  }

  List<Map<String, String>> historyList = [];
  var isLoading = true;
  String? _pressedTitle; // <-- 추가

  Future<void> fetchData() async {
    try {
      http.Response response = await http.get(Uri.parse(
          'https://www.mo-mo.co.kr/api/get_song_history/json?uid=${MyApp.uid}'));

      if (response.statusCode == 200) {
        String jsonData = response.body;
        List<dynamic> apiData = jsonDecode(jsonData);

        if (mounted) {
          setState(() {
            historyList = apiData.map<Map<String, String>>((item) {
              return {
                'image': item['IMAGE']?.toString() ?? '',
                'title': item['TITLE']?.toString() ?? '',
                'artist': item['ARTIST']?.toString() ?? '',
              };
            }).toList();
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Watch History Api Error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final deviceHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(deviceHeight * 0.15),
        child: AppBar(
          backgroundColor: const Color.fromRGBO(255, 195, 200, 1.0),
          title: Center(
              child: Text(
                '히스토리',
                style: TextStyle(fontSize: 15.sp),
              )),
        ),
      ),
      backgroundColor: const Color.fromRGBO(255, 195, 200, 1.0),
      body: Stack(
        children: [
          isLoading
              ? Center(
            child: CircularProgressIndicator(
              color: Colors.grey,
              strokeWidth: 2.0,
            ),
          )
              : ListView.builder(
            padding: EdgeInsets.only(bottom: 10.0),
            itemCount: historyList.length,
            itemBuilder: (context, index) {
              final item = historyList[index];

              return GestureDetector(
                onTapDown: (_) {
                  setState(() {
                    _pressedTitle = item['title'];
                  });
                },
                onTapUp: (_) {
                  Future.delayed(Duration(milliseconds: 300), () {
                    if (mounted) {
                      setState(() {
                        _pressedTitle = null;
                      });
                    }
                  });
                },
                onTapCancel: () {
                  setState(() {
                    _pressedTitle = null;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: ExtendedImage.network(
                          width: deviceWidth * 0.2,
                          item['image']!,
                          fit: BoxFit.cover,
                          loadStateChanged: (state) {
                            if (state.extendedImageLoadState ==
                                LoadState.failed) {
                              return Image.asset('assets/no_image.png',
                                  fit: BoxFit.cover);
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: 10.0),
                      SizedBox(
                        width: deviceWidth * 0.5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title']!,
                              style: TextStyle(fontSize: 10.sp),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Text(
                              item['artist']!,
                              style: TextStyle(fontSize: 8.sp),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 누르고 있는 제목 표시
          if (_pressedTitle != null)
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                  EdgeInsets.symmetric(horizontal: 20.w, vertical: 7.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _pressedTitle!,
                    style: TextStyle(color: Colors.white, fontSize: 14.sp),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true, // 자동 줄바꿈 허용
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
