import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:http/http.dart' as http;
import '../model/api_detail_programs.dart';
import '../model/api_search.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../widgets/rank_dot_painter.dart';
import '/main.dart';

import 'package:share_plus/share_plus.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:intl/intl.dart';

import '../widgets/chart_container.dart';
import 'detail_screen.dart';

var dateTime;
var date;
var now = DateTime.now();
var year;

var cnt;

var intY;
List<num> listY = []; // SCH_CNT
var intX;
List listX = []; // 월

List<FlSpot> FlSpotDataAll = [];
var sum;
var avgY;
var track_no;
List programs = [];
List song_cnts = [];
List broad_weeks_chart = [];
bool hasRankIn100 = true;

final pageController = PageController();
final pageController2 = PageController();
var image;
var title;
var artist;
var album;
var date_;
var count;

List detailList = [];
List song_recommends = [];

List reversedDate = [];
List dateList = [];

class SongInfoScreen extends StatefulWidget {

  // 넘어온 값
  final ApiSearch song;
  const SongInfoScreen({super.key, required this.song});

  @override
  State<SongInfoScreen> createState() => _SongInfoScreenState();
}

class _SongInfoScreenState extends State<SongInfoScreen> {

  List<DetailProgram> infoProgram = [];
  bool isLoading = true;
  bool programLoading = true;

  // API 요청
  // API 요청
  Future<String> fetchData() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiService().detailUrl}/json'
            '?id=${widget.song.songId}'
            '&uid=${MyApp.uid}'
            '&genre=${widget.song.genre}',
        ),
      );

      final Map<String, dynamic> detailList =
      jsonDecode(response.body);

      song_recommends = detailList['song_recommend'] ?? [];
      count = detailList['count'] ?? 0;
      song_cnts = detailList['song_cnts'] ?? [];
      broad_weeks_chart = detailList['broad_weeks_chart'] ?? [];

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('노래 상세화면 API 통신 오류 ################ $e');
    }

    ///// 프로그램 API 요청 & 응답 /////
    try {
      final programsResponse = await http.get(
        Uri.parse(
          '${ApiService().programsUrl}/json?id=${widget.song.songId}',
        ),
      );

      final List<dynamic> programList =
      jsonDecode(programsResponse.body);

      setState(() {
        programs = programList;
        programLoading = false;
      });
    } catch (e) {
      print('상세화면 프로그램 API 통신 에러 : $e');
    }

    return 'done';
  }


  @override
  void initState() {
    fetchData();

    image = widget.song.image;
    title = widget.song.title;
    artist = widget.song.artist;
    album = widget.song.album;
    date_ = widget.song.date;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    if (isLoading) return Center(child: CircularProgressIndicator(color: Colors.black,strokeWidth: 2.0,));

    int themeValue = context.watch<MyAppState>().selectedValue;
    Color textColor = themeValue == 2 ? Colors.white : Colors.black;

    final isExist = programs.length == 0;
    final isExist2 = song_recommends.length == 0;

    var deviceWidth = MediaQuery.of(context).size.width;
    var deviceHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: themeValue == 2 ? Colors.black : Color.fromRGBO(245, 245, 245, 1.0),
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        backgroundColor: themeValue == 2 ? Colors.black : Color.fromRGBO(245, 245, 245, 1.0),
        leading: IconButton(
          onPressed: () {
            // 검색 차트로 이동
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back, color: themeValue == 2 ? Colors.white : Colors.black,),
        ),
        actions: [
          IconButton(
            onPressed: () { // 공유
              Share.share(
                '${ApiService().shareUrl}?f_id=${widget.song.songId}',
                sharePositionOrigin:
                Rect.fromLTRB(0, 0, deviceWidth, deviceHeight * 0.5)
              );
            },
            icon: Icon(Icons.share, color: themeValue == 2 ? Colors.white : Colors.black,),
          )
        ],
      ),

      /** 곡 정보 */
      body: SingleChildScrollView(
        child: SafeArea(
          bottom: Platform.isAndroid,
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.fromLTRB(10, 0, 10, 10),
            decoration: BoxDecoration(
              color: themeValue == 2 ? Color.fromRGBO(90, 90, 90, 1.0) : Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: themeValue == 2 ? Colors.black54 : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      width: 1,
                      color: themeValue == 2 ? Color.fromRGBO(50, 50, 50, 1) : Color.fromRGBO(219, 219, 219, 1),
                    )
                  ),

                  // 선택한 곡 정보
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20)
                        ),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: ExtendedImage.network(
                              '${image}',
                              fit: BoxFit.cover,
                              loadStateChanged: (state) {
                                if (state.extendedImageLoadState == LoadState.failed) {
                                  return SizedBox(child: Image.asset('assets/no_image.png', fit: BoxFit.cover,),);
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                      ),

                      // 텍스트 컨테이너
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(top: 10, bottom: 15, left: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 22.0,
                                fontFamily: 'NotoSansKR-Medium',
                                color: textColor
                              ),
                            ),
                            Text(
                              artist,
                              style: TextStyle(color: textColor, fontSize: 16.0, fontFamily: 'NotoSansKR-Regular',),
                            ),
                            Text(
                              album,
                              style: TextStyle(color: textColor, fontSize: 12.0, fontFamily: 'NotoSansKR-Regular',),
                            ),
                            Text(
                              date_,
                              style: TextStyle(color: textColor, fontSize: 12.0, fontFamily: 'NotoSansKR-Regular',),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

            Container(
              margin: EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        // margin: const EdgeInsets.only(top: 25),
                        child: Text(
                          '주간 방송 차트',
                          style: TextStyle(
                            color: themeValue == 2
                            ? Colors.white
                            : Color.fromRGBO(36, 36, 36, 1),
                              fontFamily: 'NotoSansKR-Bold',
                              fontSize: 18),
                        )
                      ),

                      SizedBox(height: 10,),

                      isLoading
                        ? CircularProgressIndicator(color: Colors.black,strokeWidth: 2.0,)
                        : Container(
                          width: deviceWidth,
                          height: 200, // 최소 높이 지정
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: themeValue == 2 ? Colors.grey.shade800 : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: FractionallySizedBox(
                              widthFactor: 0.9,  // 가로 길이
                              heightFactor: 0.9, // 세로 높이
                              child: line_chart(broad_weeks_chart),
                            ),
                          ),
                        )
                    ],
                  ),

                  Container(
                    width: deviceWidth * 0.9,
                    child: Row(
                      children: [
                        Image.asset('assets/result_search.png', width: 18),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 10, 0, 0),
                              child: Text('방송차트: 지상파(TV, RADIO) 집계기준',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: themeValue == 2
                                    ? Colors.white
                                    : Colors.black
                                )
                              ),
                            ),
                            SizedBox(height: 5,),
                            Padding(
                              padding: const EdgeInsets.only(left: 10.0),
                              child: Text('방송차트 자료는 에어모니터에서 제공받았습니다.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.red[500]
                                )
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 방송 재생 정보 리스트
            Container(
              margin: const EdgeInsets.only(right: 20, left: 20),
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.only(top: 30.0),
                        child: Text('최신 방송 재생 정보',
                          style: TextStyle(
                            color: themeValue == 2
                            ? Colors.white
                            : Color.fromRGBO(36, 36, 36, 1),
                              fontFamily: 'NotoSansKR-Bold',
                              fontSize: 18
                          )
                        ),
                      ),
                      Spacer(),
                      Padding(
                        padding:
                        EdgeInsets.only(top: 40),
                        child: GestureDetector(
                          onTap: () => {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                  DetailScreen(
                                    deviceId: "",
                                    title: title,
                                    image: image,
                                    artist: artist,
                                    songId: widget.song.songId,
                                    album: album,
                                  )
                              )
                            )
                          },
                          child: isExist ? Container() :
                          Container(
                            width: 50,
                            height: 30,
                            child: Text("더보기", style: TextStyle(fontSize: 13, color: Colors.grey, fontFamily: 'NotoSansKR-Regular',),
                            ),
                          )
                        ),
                      )
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                    height: isExist ? 100 : 430,
                    child: programLoading
                      ? Center(child: CircularProgressIndicator(color: Colors.black,strokeWidth: 2.0,),) // 로딩 인디케이터
                      : isExist
                        ?
                          Center(
                            child: Text(
                              '최신 방송 재생정보가 없습니다.',
                              style: TextStyle(
                                color: themeValue == 2 ? Colors.white : Colors.black,
                                fontFamily: 'NotoSansKR-Medium',
                                fontSize: 16
                              )
                            )
                          )
                        :
                          Row(
                            children: [
                              _listView(programs)
                            ],
                          )
                  ),
                  isExist
                      ? const SizedBox.shrink()
                      : Container(
                    margin: const EdgeInsets.fromLTRB(0, 0, 0, 40),
                    child: Center(
                      child: SmoothPageIndicator(
                        controller: pageController,
                        count: programs.isEmpty ? 1 : (programs.length / 4).ceil(),
                        effect: const WormEffect(
                          activeDotColor: Color.fromRGBO(254, 36, 61, 1),
                          dotHeight: 7,
                          dotWidth: 7,
                          type: WormType.thinUnderground,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ),

            // 추천 음악 리스트
            Container(
              margin: const EdgeInsets.only(right: 20, left: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
                    child: Text('추천 음악',
                      style: TextStyle(
                        color: themeValue == 2
                          ? Colors.white
                          : Color.fromRGBO(36, 36, 36, 1),
                            fontFamily: 'NotoSansKR-Bold',
                            fontSize: 18
                      )
                    ),
                  ),
                  SizedBox(
                    height: isExist2 ? 100 : 430,
                    child: Container(
                      child: isLoading
                        ? Center(child: CircularProgressIndicator(color: Colors.black,strokeWidth: 2.0,),) // 로딩 인디케이터
                        : isExist2
                            ?
                          Center(
                            child: Text('추천 음악이 없습니다.',
                              style: TextStyle(
                                color: themeValue == 2 ? Colors.white : Colors.black,
                                  fontFamily: 'NotoSansKR-Medium',
                                  fontSize: 16
                              )
                            )
                          )
                            :
                          Row(
                            children: [
                              _listView2(song_recommends)
                            ],
                          )
                    )
                  ),

                  // 스와이프 페이징
                  isExist2
                      ? const SizedBox.shrink()
                      : Container(
                    margin: const EdgeInsets.fromLTRB(0, 10, 10, 40),
                    child: Center(
                      child: SmoothPageIndicator(
                        controller: pageController2,
                        count: (song_recommends.length / 4).ceil(),
                        effect: const WormEffect(
                          activeDotColor: Color.fromRGBO(254, 36, 61, 1),
                          dotHeight: 7,
                          dotWidth: 7,
                          type: WormType.thinUnderground,
                        ),
                      ),
                    ),
                  ),
                ],)
              )
            ],),
          ),
        ),
      ),
    );
  }

  // 차트
  Widget line_chart(broad_weeks_chart) {
    int themeValue = context.watch<MyAppState>().selectedValue;

    // ===== 정렬 (MONTH → WEEK) =====
    broad_weeks_chart.sort((a, b) {
      final int aMonth = int.parse(a['MONTH'].toString());
      final int bMonth = int.parse(b['MONTH'].toString());
      final int aWeek = int.parse(a['WEEK'].toString());
      final int bWeek = int.parse(b['WEEK'].toString());
      if (aMonth == bMonth) return aWeek.compareTo(bWeek);
      return aMonth.compareTo(bMonth);
    });

    // ===== 유효 순위만 필터 (1~100) =====
    final ranksIn100 = broad_weeks_chart
        .map((e) => int.tryParse(e['RANK'].toString()) ?? 0)
        .where((r) => r > 0 && r <= 100)
        .toList();

    if (ranksIn100.isEmpty) {
      return Center(
        child: SizedBox(
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(5.0)
            ),
            child: Center(
              child: Text(
                '주간 방송 차트 순위는 TOP 100만 제공됩니다.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // ===== 최고/최악 순위 계산 =====
    final int minRank = ranksIn100.reduce((a, b) => a < b ? a : b); // 가장 높은 순위
    final int maxRank = ranksIn100.reduce((a, b) => a > b ? a : b); // 가장 낮은 순위

    // ===== FlSpot 생성 =====
    final List<FlSpot> spots = [];
    final List<int> showingIndicators = [];

    for (int i = 0; i < broad_weeks_chart.length; i++) {
      final int rank = int.tryParse(broad_weeks_chart[i]['RANK'].toString()) ?? 0;
      double y = 0;

      if (rank > 0) {
        y = (maxRank - rank + 1).toDouble(); // 최고 순위가 차트 맨 위
      }

      spots.add(FlSpot(i.toDouble(), y));

      if (y > 0) showingIndicators.add(i); // 상시 tooltip 표시
    }

    // ===== 차트 =====
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: spots.length - 1,
        minY: 0,
        maxY: (maxRank - minRank + 1).toDouble(), // 최고순위가 맨 위
        baselineY: 0,
        borderData: FlBorderData(show: false),

        // ===== 눈금선 =====
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2, // 눈금 간격
          getDrawingHorizontalLine: (value) => FlLine(
            strokeWidth: 1,
            color: themeValue == 2
                ? Colors.grey.withOpacity(0.6)
                : Colors.grey.withOpacity(0.3),
          ),
        ),

        titlesData: FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              // reservedSize: 30,
              getTitlesWidget: bottomTitleWidgets,
            ),
          ),
        ),

        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.15,
            barWidth: 3,
            color: const Color.fromRGBO(51, 211, 180, 1),
            belowBarData: BarAreaData(show: false),

            // ===== 순위 상시 표시 =====
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, _) => spot.y > 0,
              getDotPainter: (spot, percent, barData, index) {
                final int originalRank =
                    int.tryParse(broad_weeks_chart[index]['RANK'].toString()) ?? 0;

                return RankDotPainter(
                  rank: originalRank,
                  color: const Color.fromRGBO(51, 211, 180, 1),
                );
              },
            ),
            showingIndicators: showingIndicators,
          ),
        ],

        // ===== 터치 세로줄 제거 =====
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          getTouchedSpotIndicator: (barData, spotIndexes) {
            // 세로 라인 제거, dot도 안 보이게
            return spotIndexes.map((index) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: Colors.transparent, // 세로선 없앰
                  strokeWidth: 0,
                ),
                FlDotData(show: false),
              );
            }).toList();
          },
          touchTooltipData: LineTouchTooltipData(
            tooltipPadding: EdgeInsets.zero,
            tooltipMargin: 6,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final int realRank = maxRank - spot.y.toInt() + 1;
                return LineTooltipItem(
                  '$realRank위',
                  const TextStyle(
                    color: Colors.green,
                    fontSize: 11,
                    fontFamily: 'NotoSansKR-Bold',
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    final index = value.toInt();
    // build 시점에 리스트 재생성
    final dateList = broad_weeks_chart
        .map((e) => '${int.parse(e['MONTH'].toString().substring(4, 6))}월 ${e['WEEK']}주차')
        .toList();

    if (index < 0 || index >= dateList.length) {
      return const SizedBox.shrink();
    }

    return SideTitleWidget(
      meta: meta,
      space: 8,
      child: Text(
        dateList[index],
        style: const TextStyle(fontSize: 11),
      ),
    );
  }

  // 최신 방송 재생 정보 리스트
  Widget _listView(programs) {
    int themeValue = context.watch<MyAppState>().selectedValue;
    var deviceWidth = MediaQuery.of(context).size.width;

    return Expanded(
      child: PageView.builder(
        itemCount: (programs.length / 4).ceil(),
        controller: pageController,
        itemBuilder: (BuildContext context, int pageIndex) {

          return ListView.builder(
            padding: EdgeInsets.zero,
            physics: NeverScrollableScrollPhysics(),
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: programs == null
              ? 0
              : min(4, programs.length - pageIndex * 4),
            itemBuilder: (context, index) {
              final program = pageIndex == 0
                ? programs[index]
                : programs[index + (pageIndex * 4)];

              String programDate = program['F_DATE'];
              String parseProgramDate = DateFormat('yyyy.MM.dd').format(DateTime.parse(programDate)).toString();

              return Container(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(1),
                      margin: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          width: 1,
                          color: themeValue == 2
                            ? const Color.fromRGBO(189, 189, 189, 1)
                            : Colors.black.withValues(alpha:0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox.fromSize(
                          child: ExtendedImage.network(
                            program['F_LOGO'],
                            width: 80,
                            height: 80,
                            loadStateChanged: (state) {
                              if (state.extendedImageLoadState == LoadState.failed) {
                                return SizedBox(width: 80, height: 80, child: Image.asset('assets/no_image.png'),);
                              }
                              return null;
                            },
                          ),
                        ),
                      )
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(bottom: 2),
                          child: program['F_TYPE'] == "TV"
                            ? Image.asset('assets/momo_assets/icon_tv.png', scale: 4,)
                            : Image.asset('assets/momo_assets/icon_radio.png', scale: 4),
                        ),
                        Container(
                          width: deviceWidth * 0.5,
                          child: Text(program['CL_NM'],
                            style: TextStyle(
                              fontSize: 12,
                              overflow: TextOverflow.ellipsis,
                              fontFamily: 'NotoSansKR-Bold',
                              color: themeValue == 2
                                ? Colors.white
                                : Colors.black
                            )
                          )
                        ),
                        Container(
                          width:
                          deviceWidth * 0.5,
                          margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin:
                                const EdgeInsets.only(bottom: 3),
                                child: Text(program['F_NAME'],
                                  style: const TextStyle(
                                    overflow: TextOverflow.ellipsis,
                                    fontFamily: 'NotoSansKR-Bold',
                                    fontSize: 12)
                                ),
                              ),
                              Text(parseProgramDate,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: themeValue == 2
                                    ? Colors.grey.withValues(alpha: 0.8)
                                    : Colors.black.withValues(alpha: 0.3)
                                )
                              ),
                            ],
                          ),
                        )
                      ]
                    )
                  ],
                ),
              );
            }
          );
      })
    );
  }

  Widget _listView2(song_recommends) {
    int themeValue = context.watch<MyAppState>().selectedValue;
    var deviceWidth = MediaQuery.of(context).size.width;

    return Expanded(
      child: PageView.builder(
      itemCount: (song_recommends.length / 4).ceil(),
      controller: pageController2,
      itemBuilder: (BuildContext context, int pageIndex) {
        return ListView.builder(
          padding: EdgeInsets.zero,
          physics: NeverScrollableScrollPhysics(),
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemCount: song_recommends == null
            ? 0
            : min(4, song_recommends.length - pageIndex * 4),
          itemBuilder: (context, index) {
            final song_recommend = pageIndex == 0
              ? song_recommends[index]
              : song_recommends[index + (pageIndex * 4)];
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                        padding: const EdgeInsets.all(1),
                        margin: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            width: 1,
                            color: themeValue == 2
                                ? const Color.fromRGBO(189, 189, 189, 1)
                                : Colors.black.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox.fromSize(
                            child: ExtendedImage.network(
                              song_recommend['IMAGE'] ?? "",
                              width: 80,
                              height: 80,
                              loadStateChanged: (state) {
                                if (state.extendedImageLoadState == LoadState.failed) {
                                  return SizedBox(width: 80, height: 80, child: Image.asset('assets/no_image.png'),);
                                }
                                return null;
                              },
                            ),
                          ),
                        )
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: deviceWidth * 0.5,
                          child: Text(song_recommend['TITLE'] ?? "",
                            style: TextStyle(
                              fontSize: 12,
                              overflow: TextOverflow.ellipsis,
                              fontFamily: 'NotoSansKR-Bold',
                              color: themeValue == 2
                                ? Colors.white
                                : Colors.black)
                          )
                        ),
                        Container(
                          width: deviceWidth * 0.5,
                          margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(bottom: 3),
                                child: Text(song_recommend['ARTIST'] ?? "",
                                    style: const TextStyle(
                                        overflow:
                                        TextOverflow.ellipsis,
                                        fontFamily: 'NotoSansKR-Bold',
                                        fontSize: 12
                                    )
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(bottom: 3),
                                child: Text(song_recommend['ALBUM'] ?? "",
                                  style: const TextStyle(
                                      overflow:
                                      TextOverflow.ellipsis,
                                      fontFamily: 'NotoSansKR-Bold',
                                      fontSize: 12
                                  )
                                ),
                              ),
                            ],
                          ),
                        )
                      ]
                    )
                  ],
                ),
              ],
            );
          });
        }
      )
    );
  }
}
