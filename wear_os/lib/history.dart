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

import 'main.dart';

String text = '히스토리가 존재하지 않습니다.';

class History extends StatefulWidget {
  final PageController pageController;
  const History({super.key, required this.pageController});


  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  List<Map<String, String>> historyList = [];

  @override
  void initState() {
    super.initState();
    fetchData(); // Api Data
  }

  var isLoading = true;
  var networkType = recController.networkType.value;

  Future<void> fetchData() async {


    if (networkType == 'bluetooth') {
      // 블루투스 연결이면 폰에 데이터 요청
      final jsonData = await platform.invokeMethod(
        'requestHistory',
        {'uid':MyApp.uid},
      );
      if (jsonData != null && mounted) {
        List<dynamic> apiData = jsonDecode(jsonData);
        setState(() {
          historyList = apiData.map<Map<String, String>>((item) {
            return {
              'image': item['IMAGE']?.toString() ?? '',
              'title': item['TITLE']?.toString() ?? '',
              'artist': item['ARTIST']?.toString() ?? '',
              'album': item['ALBUM']?.toString() ?? '',
              'date': item['date']?.toString() ?? ''
            };
          }).toList();
          isLoading = false;
        });
      }
    } else if (networkType == 'wifi' || networkType == 'celular') {
      // 와이파이나 셀룰러로 직접 요청
      try {
        http.Response response = await http.get(Uri.parse(
            'https://www.mo-mo.co.kr/api/get_song_history/json?uid=${MyApp.uid}'));
        if (response.statusCode == 200 && mounted) {
          List<dynamic> apiData = jsonDecode(response.body);
          setState(() {
            historyList = apiData.map<Map<String, String>>((item) {
              return {
                'image': item['IMAGE']?.toString() ?? '',
                'title': item['TITLE']?.toString() ?? '',
                'artist': item['ARTIST']?.toString() ?? '',
                'album': item['ALBUM']?.toString() ?? '',
                'date': item['date']?.toString() ?? ''
              };
            }).toList();
            isLoading = false;
          });
        }
      } catch (e) {
        print('Watch History Api Error');
      }
    } else { // 네트워크 연결 감지 안되면
      text = '네트워크 연결상태를 확인해주세요.';
    }
  }

  Future<void> delHistory() async {

    if (networkType == 'bluetooth') {

      // 블루투스 연결이면 폰에 데이터 요청
      final result = await platform.invokeMethod('delHistory', {'uid':MyApp.uid});

      if (result) {
        Fluttertoast.showToast(msg: "삭제되었습니다.");

        setState(() {
          historyList.clear();
        });
      } else {
        Fluttertoast.showToast(msg: "다시 시도해주세요.");
      }

    } else if (networkType == 'wifi' || networkType == 'celular') {
      try {
        http.Response response = await http.get(Uri.parse('https://www.mo-mo.co.kr/api/get_song_history/json?uid=${MyApp.uid}&proc=del'));
        if (response.statusCode == 200) {
          Fluttertoast.showToast(msg: "삭제되었습니다.");
          setState(() {
            historyList.clear();
          });
        }
      } catch (e) {
        print('searched song delete all error');
      }
    } else {
      Fluttertoast.showToast(msg: "네트워크 연결상태를 확인해주세요.");
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
            )
          ),
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
                                // contentPadding: EdgeInsets.all(5), // 안쪽 여백
                                content: SizedBox(
                                  // width: 50,
                                  // height: 20,
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
                          foregroundColor: Colors.grey,
                          backgroundColor: const Color.fromRGBO(
                              255, 224, 226, 1.0),
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

                            switch (state.extendedImageLoadState) {
                              case LoadState.loading:
                              return Image.asset('assets/no_image.png', fit: BoxFit.cover,);

                              case LoadState.completed:
                                return null; // 기본 이미지 렌더링

                              case LoadState.failed:
                                return Image.asset('assets/no_image.png', fit: BoxFit.cover);
                              }
                            },



                          //   if (state.extendedImageLoadState == LoadState.failed) {
                          //     return Image.asset('assets/no_image.png',
                          //         fit: BoxFit.cover);
                          //   }
                          //   return null;
                          // },
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
        ],
      ),
    );
  }
}
