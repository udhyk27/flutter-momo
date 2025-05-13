import 'dart:convert';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:http/http.dart' as http;

import 'main.dart';

String text = '히스토리가 존재하지 않습니다.';

class History extends StatefulWidget {
  final PageController pageController;
  const History({super.key, required this.pageController});


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
        'https://www.mo-mo.co.kr/api/get_song_history/json?uid=${MyApp.uid}')
      );
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
      text = '네트워크 연결을 확인해주세요.';
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
              :
          historyList.isEmpty
              ?
          Center(
            child: Text(text),
          )
              :
          ListView.builder(
            padding: EdgeInsets.only(bottom: 10.0),
            itemCount: historyList.length + 1,
            itemBuilder: (context, index) {


              if (index == historyList.length) {
                // 마지막 아이템: 버튼
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 2.h,),
                    // SizedBox(
                    // width: deviceWidth * 0.4,
                    // height: 8.h,
                    //   child: ElevatedButton(
                    //     onPressed: () {
                    //
                    //       showDialog(
                    //         context: context,
                    //         builder: (BuildContext context) {ㅋ
                    //           return AlertDialog(
                    //             content: SizedBox(
                    //               width: 200,
                    //               height: 100,
                    //               child: Center(child: Text("리스트가 삭제됩니다."))
                    //             ),
                    //             actions: [
                    //               TextButton(
                    //                 onPressed: () {
                    //                   Navigator.of(context).pop(); // 알림창 닫기
                    //                   // 여기에 삭제 로직 추가
                    //
                    //
                    //                 },
                    //                 child: Text("확인"),
                    //               ),
                    //               TextButton(
                    //                 onPressed: () {
                    //                   Navigator.of(context).pop(); // 취소 시 그냥 닫기
                    //                 },
                    //                 child: Text("취소"),
                    //               ),
                    //             ],
                    //           );
                    //         },
                    //       );
                    //
                    //
                    //     },
                    //     style: ElevatedButton.styleFrom(
                    //       foregroundColor: Colors.grey,
                    //       backgroundColor: const Color.fromRGBO(
                    //           255, 224, 226, 1.0),
                    //     ),
                    //     child: Text(
                    //       '삭제',
                    //       style: TextStyle(fontSize: 12.sp),
                    //     ),
                    //   ),
                    // ),
                    //
                    // SizedBox(height: 2.h,),

                    SizedBox(
                      width: deviceWidth * 0.4,
                      height: 8.h,
                      child: ElevatedButton(
                        onPressed: () {
                          widget.pageController.animateToPage(
                            0,
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          backgroundColor: const Color.fromRGBO(
                              255, 224, 226, 1.0),
                        ),
                        child: Text(
                          '닫기',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h,),
                  ],
                );
              }

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
