import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '/main.dart';
import 'package:provider/provider.dart';

import 'detail_screen.dart';


import 'package:http/http.dart' as http;
import '../services/api_service.dart';

import '../model/api_mmchart.dart';
import '../model/api_programs.dart';


class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {

  var page = 1;
  var page2 = 1;
  bool isChartLoading = false;
  bool isAirChartLoading = false;

  ScrollController _scrollController = ScrollController(); // ScrollController
  ScrollController _scrollController2 = ScrollController(); // Air Chart

  // API 요청 - 모모 검색 차트
  Future<void> fetchChart() async {

    if (isChartLoading || !hasMoreData) return; // 로딩중 일때는 X

    setState(() {
      isChartLoading = true;
    });

    try {
      // 현재 스크롤 위치 저장
      double currentScrollPosition = _scrollController.hasClients ? _scrollController.position.pixels : 0;

      // 페이지 요청
      http.Response response = await http.get(Uri.parse('${ApiService.mmchartUrl}?page=$page'));

      if (response.statusCode != 200) {
        throw Exception('차트 데이터 로딩 실패 ${response.statusCode}');
      }

      String jsonData = response.body;
      List<dynamic> map = jsonDecode(jsonData);
      // print('모모 검색 차트 ::::::::::::::::::::::: $map');

      if (mounted) {
        if (map.isNotEmpty) {
          setState(() {
            momo_sch_list.addAll(map
                .map((item) => ApiMmChart.fromJson(item as Map<String, dynamic>))
                .toList());
          });
          page++;
        } else {
          print('데이터 끝');
          hasMoreData = false; // 더 이상 데이터가 없음을 표시
        }

        setState(() {
          isChartLoading = false;
        });
      }


      // 기존 스크롤 위치 유지하기
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(currentScrollPosition);
        }
      });
    } catch (e) {
      print('모모 검색 차트 API 오류 : $e');

      if (mounted) {
        setState(() {
          isChartLoading = false;
        });
      }
    }
  }

  Future<void> fetchAirChart() async {
    if (isAirChartLoading || !hasMoreData) return; // 로딩중 일때, 데이터 없을 때 X

    setState(() {
      isAirChartLoading = true;
    });

    try {
      double currentScrollPosition = _scrollController2.hasClients ? _scrollController2.position.pixels : 0;

      http.Response response = await http.get(Uri.parse('${ApiService.airchartUrl}?page=$page2'));

      if (response.statusCode != 200) {
        throw Exception('에어차트 데이터 로딩 실패 ${response.statusCode}');
      }

      String jsonData = response.body;
      List<dynamic> map = jsonDecode(jsonData);
      // print('에어차트 :::::::::::::::::::::::::: $map');

      if (mounted) {
        if (map.isNotEmpty) {
          setState(() {
            air_chart.addAll(map
                .map((item) => ApiPrograms.fromJson(item as Map<String, dynamic>))
                .toList());
          });

          page2++;
        } else {
          print('에어차트 데이터 끝');
          setState(() {
            hasMoreData = false; // 데이터 없음
          });
        }

        setState(() {
            isAirChartLoading = false;
        });
      }

      // 기존 스크롤 위치 유지하기
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController2.hasClients) {
          _scrollController2.jumpTo(currentScrollPosition);
        }
      });

    } catch (e) {
      print('에어차트 API 오류 : $e');

      if (mounted) {
        setState(() {
          isAirChartLoading = false;
        });
      }
    }
  }

  // 디바이스 ID
  String? _uid;

  // DEVICE ID
  Future<void> getDeviceId() async {
    // DEVICE ID 가져오기
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        _uid = androidInfo.id;  // 안드로이드 디바이스 ID
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        _uid = iosInfo.identifierForVendor;  // iOS 디바이스 ID
      }
      // print('device uid ::::::::::::::::::::::: $_uid');
    } catch (e) {
      _uid = 'Failed to get id';
    }
  }

  PageController _pageController = PageController();

  // 리스트 초기화
  List<ApiMmChart> momo_sch_list = [];
  List<ApiPrograms> air_chart = [];

  // 페이지 전환시 현재 페이지 인덱스
  int _currentIndex = 0;
  double _barPosition = 0;
  String _currentText = '모모에서 가장 많이 검색된 음원입니다.';

  bool hasMoreData = true;

  @override
  void initState() {
    super.initState();

    fetchChart(); // 모모 차트
    fetchAirChart(); // 에어 차트
    getDeviceId(); // device id

    // 모모 차트 스크롤 감지
    _scrollController.addListener(() {
      if (hasMoreData && (_scrollController.position.pixels == _scrollController.position.maxScrollExtent)) {
        fetchChart(); // 스크롤이 맨 끝에 도달하면 데이터 로드
      }
    });

    // 에어 차트 스크롤
    _scrollController2.addListener(() {
      if (hasMoreData && (_scrollController2.position.pixels == _scrollController2.position.maxScrollExtent)) {
        fetchAirChart(); // 스크롤이 맨 끝에 도달하면 데이터 로드
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollController2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int themeValue = context.watch<MyAppState>().selectedValue;

    // 화면 너비
    double screenWidth = MediaQuery.of(context).size.width - 50;

    // 버튼 클릭 시 막대바 위치 변경 & 페이지 전환
    void _onButtonClick(int index) {
      setState(() {
        _currentIndex = index;
        _barPosition = _currentIndex == 0 ? 0 : screenWidth / 2;
        _currentText = _currentIndex == 0 ? "모모에서 가장 많이 검색된 음원입니다." : "최근 방송 재생 음원입니다.\nby 에어모니터";
      });
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: themeValue == 2 ? Color.fromRGBO(90, 90, 90, 1.0) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
          )
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [ // 버튼을 눌러서 페이지 전환
              TextButton(
                onPressed: () {
                  _pageController.animateToPage(0, duration: Duration(milliseconds: 300), curve: Curves.ease);
                  _onButtonClick(0);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black, // 글자색 설정
                  backgroundColor: Colors.transparent, // 배경색 설정 (투명으로 설정)
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // 버튼 크기 설정
                ),
                child: Text('모모 검색 차트', style: TextStyle(color: themeValue == 2 ? Colors.white : Colors.black),),
              ),

              SizedBox(width: 40),

              TextButton(
                onPressed: () {
                  _pageController.animateToPage(1, duration: Duration(milliseconds: 300), curve: Curves.ease);
                  _onButtonClick(1);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black, // 글자색 설정
                  backgroundColor: Colors.transparent, // 배경색 설정 (투명으로 설정)
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // 버튼 크기 설정
                ),
                child: Text('에어차트', style: TextStyle(color: themeValue == 2 ? Colors.white : Colors.black)),
              ),
            ],
          ),

          // 막대바
          Align(
            alignment: Alignment.topLeft,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: screenWidth / 2,
              height: 2,
              color: Colors.deepOrange,
              margin: EdgeInsets.only(left: _barPosition),
            ),
          ),

          Container(
            height: 80,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _currentText,
                style: TextStyle(
                  fontSize: 14,
                  color: Color.fromRGBO(200, 200, 200, 1.0),
                ),
              ),
            ),
          ),

          // 전환되는 리스트
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },

              physics: NeverScrollableScrollPhysics(), // 스와이프 탭 이동 막기
              children: [

                // 모모 검색 차트 //
                isChartLoading
                ? Center(child: CircularProgressIndicator(color: Colors.black,strokeWidth: 2.0,))
                : momo_sch_list.isEmpty
                    ? Center(child: Text('데이터가 존재하지 않습니다.'),)
                    : RefreshIndicator(
                      color: Colors.black,
                      backgroundColor: Colors.white,
                      onRefresh: fetchChart,
                      child: ListView.builder(
                          controller: _scrollController, // 컨트롤러 연결
                          itemCount: momo_sch_list.length,
                          itemBuilder: (context, index) {

                            if (index == momo_sch_list.length) {
                              return isChartLoading
                                ? Center(child: CircularProgressIndicator())
                                : SizedBox.shrink(); // 로딩 끝나면 빈 아이템 반환
                            }

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailScreen(
                                title: momo_sch_list[index].title,
                                artist: momo_sch_list[index].artist,
                                album: momo_sch_list[index].album,
                                image: momo_sch_list[index].image,
                                songId: momo_sch_list[index].songId,
                                deviceId: _uid.toString()
                              ),
                            ),
                          );
                        },

                        child: Container(
                          margin: EdgeInsets.only(bottom: 5),
                          height: 120,
                          padding: EdgeInsets.all(10),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: ExtendedImage.network(
                                  momo_sch_list[index].image,
                                  width: 100,
                                  height: 100,
                                  loadStateChanged: (state) {
                                    if (state.extendedImageLoadState == LoadState.failed) {
                                      return SizedBox(width: 100, height: 100, child: Image.asset('assets/no_image.png'),);
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(width: 10,),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center, // 수직 정렬
                                  crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
                                  children: [
                                    Text(
                                      momo_sch_list[index].title,
                                      overflow:
                                      TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    Text(
                                      momo_sch_list[index].artist,
                                      overflow:
                                      TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    Text(
                                      momo_sch_list[index].album,
                                      overflow:
                                      TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: TextStyle(fontSize: 13, color: Colors.grey),
                                    ),
                                  ],
                                )
                              ),
                            ],
                          ),
                        ),
                      );
                                        },
                                      ),
                    ),


                /////////////////////////////// 에어차트 ///////////////////////////////
                isAirChartLoading
                ? Center(child: CircularProgressIndicator(color: Colors.black,strokeWidth: 2.0,))
                : air_chart.isEmpty
                ? Center(child: Text('데이터가 존재하지 않습니다.'),)
                : RefreshIndicator(
                  color: Colors.black,
                  backgroundColor: Colors.white,
                  onRefresh: fetchAirChart,
                  child: ListView.builder(
                    controller: _scrollController2, // 컨트롤러 연결
                    itemCount: air_chart.length,
                    itemBuilder: (context, index) {

                      if (index == air_chart.length) { // 맨 마지막 item
                        return isAirChartLoading
                            ? Center(child: CircularProgressIndicator(color: Colors.black,strokeWidth: 2.0,))
                            : SizedBox.shrink(); // 로딩 끝나면 빈 아이템 반환
                      }

                      return Container(
                        margin: EdgeInsets.only(bottom: 5),
                        height: 120,
                        padding: EdgeInsets.all(10),
                        child: Row(
                          children: [

                            Container(

                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10)
                              ),

                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: ExtendedImage.network(
                                  air_chart[index].fLogo,
                                  width: 100,
                                  height: 100,
                                  loadStateChanged: (state) {
                                    if (state.extendedImageLoadState == LoadState.failed) {
                                      return SizedBox(width: 100, height: 100, child: Image.asset('assets/no_image.png'),);
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                            SizedBox(width: 10,),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center, // 수직 정렬
                                crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
                                children: [

                                  ExtendedImage.asset(
                                    air_chart[index].fType == 'TV' ? 'assets/momo_assets/icon_tv.png' : 'assets/momo_assets/icon_radio.png',
                                    scale: 4.5,
                                  ),

                                  Text(
                                    air_chart[index].fName,
                                    overflow:
                                    TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                  ),
                                  Text(
                                    air_chart[index].sTitle,
                                    overflow:
                                    TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                  ),Text(
                                    air_chart[index].sArtist,
                                    overflow:
                                    TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  )
                                ],
                              )
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
        ],
      ),
    );
  }
}

