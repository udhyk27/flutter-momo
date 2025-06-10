import 'dart:convert';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import 'package:http/http.dart' as http;
import 'package:wear_os/song_info.dart';
import 'package:wear_os/widgets/vmidc.dart';

import 'controller/RecController.dart';
import 'main.dart';

String text = '히스토리가 존재하지 않습니다.';

class History extends StatefulWidget {
  final PageController pageController;
  const History({super.key, required this.pageController});


  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {

  int visibleCount = 5;

  @override
  void initState() {
    super.initState();
    fetchData(); // Api Data
    ever(recController.networkType, (_) => fetchData());
  }

  Future<void> fetchData() async {
    var networkType = recController.networkType.value;
    if (networkType == 'bluetooth') {
      // 블루투스 연결이면 폰에 데이터 요청
      final result = await platform.invokeMethod(
        'requestHistory',
        {'uid':MyApp.uid},
      );

      if (result != 'success' && mounted) {
        // Fluttertoast.showToast(msg: "블루투스 연결이 원활하지 않습니다.");
      }
    } else if (networkType == 'wifi' || networkType == 'cellular') {
      // 와이파이나 셀룰러로 직접 요청
      try {
        http.Response response = await http.get(Uri.parse(
          'https://www.mo-mo.co.kr/api/get_song_history/json?uid=${MyApp.uid}'));
        if (response.statusCode == 200 && mounted) {
          List<dynamic> apiData = jsonDecode(response.body);
            recController.historyList.value = apiData.map<Map<String, String>>((item) {
              return {
                'image': item['IMAGE']?.toString() ?? '',
                'title': item['TITLE']?.toString() ?? '',
                'artist': item['ARTIST']?.toString() ?? '',
                'album': item['ALBUM']?.toString() ?? '',
                'date': item['date']?.toString() ?? ''
              };
            }).toList();
          recController.historyLoading.value = false;
        }
      } catch (e) {
        print('Watch History Api Error :: $e');
      }
    } else { // 네트워크 연결 감지 안되면
      text = '네트워크 연결상태를 확인해주세요.';
    }
  }

  Future<void> delHistory() async {
    var networkType = recController.networkType.value;
    if (networkType == 'bluetooth') {
      // 블루투스 연결이면 폰에 데이터 요청
      final result = await platform.invokeMethod('delHistory', {'uid':MyApp.uid});

      if (result == 'success') {
        Fluttertoast.showToast(msg: "삭제되었습니다.");
        recController.historyList.clear();
      } else {
        Fluttertoast.showToast(msg: "다시 시도해주세요.");
      }

    } else if (networkType == 'wifi' || networkType == 'cellular') {
      try {
        http.Response response = await http.get(Uri.parse('https://www.mo-mo.co.kr/api/get_song_history/json?uid=${MyApp.uid}&proc=del'));
        if (response.statusCode == 200) {
          Fluttertoast.showToast(msg: "삭제되었습니다.");
          recController.historyList.clear();
        }
      } catch (e) {
        print('searched song delete all error : $e');
      }
    } else {
      Fluttertoast.showToast(msg: "네트워크 연결상태를 확인해주세요.");
    }
  }



  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final deviceHeight = MediaQuery.of(context).size.height;
    final RecController recController = Get.find<RecController>();

    List<Color> gradientColors = [
      // Color.fromRGBO(194, 40, 222, 1.0), // 위쪽 색
      // Color.fromRGBO(62, 195, 255, 1.0), // 아래쪽 색

      // darkmode
      Color.fromRGBO(158, 158, 158, 1.0),
      Color.fromRGBO(0, 0, 0, 1.0)
    ];

    return Obx(() {
      int listLength = recController.historyList.length < visibleCount
        ? recController.historyList.length
        : visibleCount;

      int totalCount = listLength + 2;

      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: gradientColors
              )
          ),
          child: Stack(
            children: [
              recController.historyLoading.value
              ? Center(
                child: CircularProgressIndicator(
                  color: Colors.grey,
                  strokeWidth: 2.0,
                ),
              )
              : recController.historyList.isEmpty
              ?

              Column(
                children: [
                  IconButton(
                    onPressed: () {
                      widget.pageController.animateToPage(
                        0,
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: Icon(
                      Icons.keyboard_double_arrow_up,
                      color: Colors.white70,
                      size: 36,
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: deviceHeight / 4),
                    child: Center(child: Text(text, style: TextStyle(color: Colors.white),),),
                  )
                ],
              )

              : ListView.builder(
                padding: EdgeInsets.only(bottom: 10.0),
                itemCount: totalCount,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                        child: Text(
                          '히스토리',
                          style: TextStyle(fontSize: 15.sp, color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ),
                    );
                  } else if (index == listLength + 1) {
                    // 마지막 아이템: 버튼
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 2.h,),

                        if (recController.historyList.length > visibleCount)
                          SizedBox(
                            width: deviceWidth * 0.4,
                            height: 8.h,

                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  visibleCount += 5;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.black54
                              ),
                              child: Text(
                                '더보기',
                                style: TextStyle(fontSize: 12.sp),
                              ),
                            ),

                          ),


                        SizedBox(height: 2.h,),
                        SizedBox(
                        width: deviceWidth * 0.4,
                        height: 8.h,
                          child: ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    insetPadding: EdgeInsets.symmetric(vertical: 5),
                                    content: SizedBox(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "삭제하시겠습니까?",
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.of(context).pop(); // 알림창 닫기
                                          await delHistory();
                                        },
                                        child: Text("확인", style: TextStyle(color: Colors.black26,fontSize: 10.sp,),),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(); // 취소 시 그냥 닫기
                                        },
                                        child: Text("취소", style: TextStyle(color: Colors.black26,fontSize: 10.sp,), ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.black54
                            ),
                            child: Text(
                              '삭제',
                              style: TextStyle(fontSize: 12.sp),
                            ),
                          ),
                        ),

                        SizedBox(height: 2.h,),

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
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.black54
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

                  // 리스트 목록
                  final item = recController.historyList[index - 1];

                  return GestureDetector(
                    onTap: () {
                      Get.to(() => SongInfo(
                        song: {
                          'TITLE': item['title'],
                          'ALBUM': item['album'],
                          'IMAGE': item['image'],
                          'ARTIST': item['artist'],
                          'date': item['date']
                        },
                      ));
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3.0),

                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 26, vertical: 0.5),
                        height: deviceHeight * 0.3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),

                          image: DecorationImage(
                            image: ExtendedNetworkImageProvider(item['image']!),
                            fit: BoxFit.cover,
                          ),

                        ),
                        child: Stack(
                          children: [
                            // 왼쪽 검은색 그라데이션 배경
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: deviceWidth * 0.4,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerRight,
                                    end: Alignment.centerLeft,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.8), // 왼쪽으로 갈수록 진해짐
                                    ],
                                  ),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(25),
                                    bottomLeft: Radius.circular(25),
                                  ),
                                ),
                              ),
                            ),

                            // 텍스트 오버레이
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title']!,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    Text(
                                      item['artist']!,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10.sp,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),



                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    });

  }
}
