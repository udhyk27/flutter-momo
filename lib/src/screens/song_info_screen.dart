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
  Future<String> fetchData() async {
    ///// 곡 상세화면 API 요청 & 응답 /////
    try {

      http.Response response = await http.get(Uri.parse('${ApiService.detailUrl}/json?id=${widget.song.songId}&uid=${MyApp.uid}&genre=${widget.song.genre}'));

      String jsonData = response.body;
      Map<String, dynamic> detailList = jsonDecode(jsonData);

      song_recommends = detailList['song_recommend'] ?? [];
      // print('추천 음악 :: ${song_recommends}');

      count = detailList['count'] ?? 0;
      song_cnts = detailList['song_cnts'] ?? [];
      broad_weeks_chart = detailList['broad_weeks_chart'] ?? [];

      final hasRankIn100 = broad_weeks_chart.any((e) {
        final rank = int.tryParse(e['RANK'].toString()) ?? 0;
        return rank > 0 && rank <= 100;
      });


      print('@@ 주간 방송 차트 @@');
      print(broad_weeks_chart);
      // print(detailList);

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('노래 상세화면 API 통신 오류 ################ $e');
    }

    ///// 프로그램 API 요청 & 응답 /////
    try {
      http.Response programs_response = await http.get(Uri.parse('${ApiService.programsUrl}/json?id=${widget.song.songId}'));

      // programs data 파싱
      String programs_json = programs_response.body;
      List<dynamic> programList = jsonDecode(programs_json);

      setState(() {
        programs = programList;
        programLoading = false;
      });

    } catch (e) {
      print('상세화면 프로그램 API 통신 에러 : $e');
    }

    try {
      List _contain = [];  // 실데이타 파싱
      sum = 0;

      // for (int i = 0; i <= broad_weeks_chart.length - 1; i++) {
      //   final item = broad_weeks_chart[i] as Map<String, dynamic>;
      //
      //   intX = int.parse(
      //       broad_weeks_chart[i]['MONTH'].toString().substring(4, 6)); //#mod
      //
      //   final ranking = item['RANK']; //#mod
      //   print(ranking); // 랭킹
      //
      //   final intY = int.tryParse(ranking.toString()) ?? 0;
      //
      //   listX.add(intX);
      //   listY.add(intY);
      //
      //   _contain.add(broad_weeks_chart[i]['MONTH'].toString());
      // }
      // broad_weeks_chart.sort((a, b) {
      //   return a['MONTH'].compareTo(b['MONTH']);
      // });


      // 차트 실데이터 파싱
      // 먼저 정렬 (한 번만)
      broad_weeks_chart.sort((a, b) {
        if (a['MONTH'] == b['MONTH']) {
          return a['WEEK'].compareTo(b['WEEK']);
        }
        return a['MONTH'].compareTo(b['MONTH']);
      });

      // FlSpot 생성
      FlSpotDataAll.clear();

      for (int i = 0; i < broad_weeks_chart.length; i++) {
        final int rank =
            int.tryParse(broad_weeks_chart[i]['RANK'].toString()) ?? 0;

        // 100등 밖이면 0
        final double y =
        (rank > 0 && rank <= 100) ? rank.toDouble() : 0.0;

        FlSpotDataAll.add(
          FlSpot(i.toDouble(), y),
        );
      }


      // for (int j = 0; j < _reverse.length; j++) {
        //   // 없는 월 제외
        //   double mon = double.parse(j.toString()) + 1;
        //   FlSpotDataAll.insert(j, FlSpot(mon, 0));
        //
        //   for (int jj = 0; jj < broad_weeks_chart.length; jj++) {
        //     if (broad_weeks_chart[jj]['MONTH'].toString() == _reverse[j]) {
        //       cnt = double.parse(broad_weeks_chart[jj]['RANK']);
        //       FlSpotDataAll.removeAt(j);
        //       FlSpotDataAll.insert(j, FlSpot(mon, cnt));
        //     }
        //   }
        // for (int jj = 0; jj < song_cnts.length; jj++) {
        //   if (song_cnts[jj]['F_MONTH'].toString() == _reverse[j]) {
        //     cnt = double.parse(song_cnts[jj]['CTN']);
        //     FlSpotDataAll.removeAt(j);
        //     FlSpotDataAll.insert(j, FlSpot(mon, cnt));
        //   }
        // }
        // }
      // FlSpotDataAll.removeWhere((items) => items.y == 0.0);
    } catch (e) {
      print(e);
    }
    // HapticFeedback.vibrate();
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


    final isCNTS = broad_weeks_chart.length > 3;
    // final isCNTS = song_cnts.length > 3;

    var deviceWidth = MediaQuery.of(context).size.width;
    var deviceHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: themeValue == 2 ? Colors.black : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: themeValue == 2 ? Colors.black : Colors.grey[100],
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
                  '${ApiService.shareUrl}?f_id=${widget.song.songId}',
                  sharePositionOrigin:
                  Rect.fromLTRB(0, 0, deviceWidth, deviceHeight * 0.5)
              );
            },
            icon: Icon(Icons.share, color: themeValue == 2 ? Colors.white : Colors.black,),
          )
        ],
      ),

      /////////////////////////////////// 곡 정보 ///////////////////////////////////
      body: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: themeValue == 2 ? Color.fromRGBO(90, 90, 90, 1.0) : Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: themeValue == 2 ? Colors.black : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        width: 1,
                        color: themeValue == 2 ? Color.fromRGBO(50, 50, 50, 1):Color.fromRGBO(219, 219, 219, 1),
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
                          margin: EdgeInsets.only(top: 20, bottom: 20, left: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'NotoSansKR-Medium',
                                    color: textColor
                                ),
                              ),
                              Text(
                                artist,
                                style: TextStyle(color: textColor, fontSize: 20),
                              ),
                              Text(
                                album,
                                style: TextStyle(color: textColor),
                              ),

                              Text(
                                date_,
                                style: TextStyle(color: textColor),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

              SizedBox(height: 20),

              Container(
                margin: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 25),
                          child: Text(
                            '주간 방송 차트',
                            style: TextStyle(
                              color: themeValue == 2
                              ? Colors.white
                              : Color.fromRGBO(36, 36, 36, 1),
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                          )
                        ),

                        SizedBox(height: 10,),

                        isLoading
                          ?
                        CircularProgressIndicator(color: Colors.black,strokeWidth: 2.0,)
                          :
                          isCNTS
                            ?
                          ChartContainer(
                            color: themeValue == 2
                            ? Colors.black
                            : Colors.white,
                            // chart: line_chart(song_cnts),
                            chart: line_chart(broad_weeks_chart),
                          )
                            :
                          const SizedBox(
                            height: 200,
                            child: Center(
                              child: Text('차트 정보가 없습니다.',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20
                                )
                              )
                            )
                          )
                      ],
                    ),

                    Container(
                      decoration: BoxDecoration(
                        // color: themeValue == 2
                        //   ? const Color.fromRGBO(42, 42, 42, 1)
                        //   : const Color.fromRGBO(250, 250, 250, 1),
                        borderRadius: BorderRadius.circular(5)
                      ),
                      height: 50,
                      width: deviceWidth * 0.9,
                      child: Row(
                        children: [
                          // Spacer(),
                          Image.asset('assets/result_search.png', width: 18),

                          // Container(
                          //   margin: const EdgeInsets.only(left: 10, right: 10),
                          //   child:
                          //     // Text('총 검색 : ${count}회',
                          //     Text('방송차트: 지상파(TV, RADIO) 집계기준',
                          //     style: TextStyle(
                          //       fontSize: 13,
                          //       color: themeValue == 2
                          //         ? Colors.white
                          //         : Colors.black
                          //     )
                          //   ),
                          // ),

                          Column(
                            children: [
                              Text('방송차트: 지상파(TV, RADIO) 집계기준',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: themeValue == 2
                                    ? Colors.white
                                    : Colors.black
                                )
                              ),
                              SizedBox(height: 5,),
                              Text('방송차트 자료는 에어모니터에서 제공받았습니다.',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red
                                )
                              )
                            ],
                          ),

                          // Spacer(),
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
                          padding:
                          const EdgeInsets.fromLTRB(0, 30, 0, 0),
                          child: Text('최신 방송 재생 정보',
                            style: TextStyle(
                              color: themeValue == 2
                              ? Colors.white
                              : Color.fromRGBO(36, 36, 36, 1),
                              fontWeight: FontWeight.bold,
                              fontSize: 20
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
                            child: Container(
                              width: 50,
                              height: 30,
                              child: Text("더보기 >", style: TextStyle(fontSize: 15),
                              ),
                            )
                          ),
                        )
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                      height: 440,
                      child:
                        programLoading
                          ?
                        Center(
                          child: CircularProgressIndicator(color: Colors.black,strokeWidth: 2.0,), // 로딩 인디케이터
                        )
                            :
                          isExist
                            ?
                          Center(
                            child: Text(
                              '최신 방송 재생정보가 없습니다.',
                              style: TextStyle(
                                color: Theme.of(context).primaryColorLight,
                                fontSize: 20
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
                    Container(
                      margin: const EdgeInsets.fromLTRB(
                          0, 0, 0, 40),
                      child: Center(
                        child: SmoothPageIndicator(
                          controller: pageController,
                          count: (programs.length / 4).ceil(),
                          effect: const WormEffect(
                            activeDotColor:
                            Color.fromRGBO(254, 36, 61, 1),
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
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
                      child: Text('추천 음악',
                        style: TextStyle(
                          color: themeValue == 2
                            ?
                          Colors.white
                            :
                          Color.fromRGBO(36, 36, 36, 1),
                          fontWeight: FontWeight.bold,
                          fontSize: 20
                        )
                      ),
                    ),
                    SizedBox(
                      height: 450,
                      child: Container(
                        child:
                          isLoading
                            ?
                          Center(
                            child: CircularProgressIndicator(color: Colors.black,strokeWidth: 2.0,), // 로딩 인디케이터
                          )
                            :
                        isExist2
                          ?
                        Center(
                          child: Text('추천 음악이 없습니다.',
                            style: TextStyle(
                              color: themeValue == 2 ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 20
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
                    Container(
                      margin: const EdgeInsets.fromLTRB(0, 10, 10, 40),
                      child: Center(
                        child: SmoothPageIndicator(
                          controller: pageController2,
                          count: (song_recommends.length/ 4).ceil(),
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
              )
            ],
          ),
        ),
      ),
    );
  }

  // 차트
  Widget line_chart(broad_weeks_chart) {
    int themeValue = context.watch<MyAppState>().selectedValue;
    List<FlSpot> FlSpotData = [];
    FlSpotData.addAll(FlSpotDataAll);
    final minCnt = listY.isNotEmpty ? listY.last >= 50 : false;
    final maxRank = listY.isNotEmpty ? listY.reduce(max) : 10;

    var result = LineChart(
      LineChartData(
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 0,
              color: themeValue == 2
                ? Colors.grey.withValues(alpha: 0.6)
                : Colors.grey.withValues(alpha: 0.3)
            )
          ],
        ),
        baselineY: 0,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          getDrawingHorizontalLine: (value) {
            return FlLine(
              strokeWidth: 1,
              color: themeValue == 2
                ? Colors.grey.withValues(alpha: 0.6)
                : Colors.grey.withValues(alpha: 0.3)
            );
          },
          drawVerticalLine: false,
          drawHorizontalLine: true,
          horizontalInterval: minCnt ? avgY / 8 : 30
        ),
        minX: 1, // 최소 1
        minY: maxRank.toDouble(), // 최소 횟수 0
        maxX: 4, // #mod

        // maxY: double.parse((listY.isNotEmpty ? listY.last : 100).toString()), // 최대 횟수 마지막 요소 + 100
        // maxY: listY.isNotEmpty
        //     ? listY.reduce(max).toDouble() + 20
        //     : 100,
        maxY: 1,
        lineBarsData: [
          LineChartBarData(
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
                  radius: 3.0,
                  color: const Color.fromRGBO(51, 211, 180, 1),
                  strokeColor:
                  themeValue == 2 ? Colors.white : Colors.grey.shade200,
                  strokeWidth: 5.0
                ),
            ),



              color: const Color.fromRGBO(51, 211, 180, 1),
            isCurved: true,
            curveSmoothness: 0.1,
            barWidth: 3,
            isStrokeCapRound: true,
            isStrokeJoinRound: true,
            belowBarData: BarAreaData(show: false),
            // belowBarData: BarAreaData(
            //   show: true,
            //   gradient: themeValue == 2
            //     ?
            //       LinearGradient(
            //         begin: Alignment.topCenter,
            //         end: Alignment.bottomCenter,
            //         colors: [Color.fromRGBO(51, 215, 180, 1), Colors.white12]
            //       )
            //     :
            //       LinearGradient(
            //         begin: Alignment.topCenter,
            //         end: Alignment.bottomCenter,
            //         colors: [Color.fromRGBO(51, 215, 180, 1), Colors.white24]
            //       ),
            // ),
            spots: FlSpotData
          )
        ],

        titlesData: FlTitlesData(
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),

          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          // leftTitles: AxisTitles(
          //   sideTitles: SideTitles(
          //     showTitles: true,
          //     reservedSize: 32,
          //     interval: 1,
          //     getTitlesWidget: (value, meta) {
          //       return Text(
          //         value.toInt().toString(),
          //         style: const TextStyle(
          //           fontSize: 10,
          //           color: Colors.grey,
          //         ),
          //       );
          //     },
          //   ),
          // ),

          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: false
            ),
          ),

          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: bottomTitleWidgets
            )
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              return spots.map((spot) {
                return LineTooltipItem(
                  '${spot.y.toInt()}위',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),

      )
    );
    return result;
  }

  late String text;

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    text = '';

    try {
      // int i = 0;
      dateList = [];

      // for (i; i < 12; i++) {
      //   dateTime = DateTime(now.year, now.month - i, 1);
      //   date = DateFormat('MM').format(dateTime);
      //   year = DateFormat('yy').format(now);
      // // print(dateTime);
      //
      //   dateList.add(date);
      // }

      for (int i = 0; i < broad_weeks_chart.length; i++) {
        final item = broad_weeks_chart[i] as Map<String, dynamic>;
        var month = int.parse(item['MONTH'].substring(4, 6));
        var week = item['WEEK'];

        dateList.add('${month}월 ${week}주차');
      }
    } catch (e) {
      print('bottom title : $e');
    }

    switch (value.toInt()) {
      case 1:
        text = dateList[0];
        break;
      case 2:
        text = dateList[1];
        break;
      case 3:
        text = dateList[2];
        break;
      case 4:
        text = dateList[3];
        break;
    }
    return SideTitleWidget(
      child: Text(text),
      meta: meta,  // 필수 파라미터 유지
      space: 8.0,  // 선택 사항: 텍스트와 축 사이 간격
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
                            // program['F_IMAGE'],
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
                              fontSize: 14,
                              overflow: TextOverflow.ellipsis,
                              fontWeight: FontWeight.bold,
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
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)
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

                    // final isDarkMode = MyApp.selectedTheme == 'dark';
                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                                padding: const EdgeInsets.all(1),
                                margin:
                                const EdgeInsets.fromLTRB(0, 10, 10, 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    width: 1,
                                    color: themeValue == 2
                                        ? const Color.fromRGBO(189, 189, 189, 1)
                                    // : const Color.fromRGBO(228, 228, 228, 1),
                                        : Colors.black.withValues(alpha: 0.3),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox.fromSize(
                                    child: ExtendedImage.network(
                                      // program['F_IMAGE'],
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
                                        fontSize: 14,
                                        overflow: TextOverflow.ellipsis,
                                        fontWeight: FontWeight.bold,
                                        color: themeValue == 2
                                          ? Colors.white
                                          : Colors.black))),
                                  Container(
                                    width: deviceWidth * 0.5,
                                    margin:
                                    const EdgeInsets.fromLTRB(0, 0, 0, 10),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          margin:
                                          const EdgeInsets.only(bottom: 3),
                                          child: Text(song_recommend['ARTIST'] ?? "",
                                              style: const TextStyle(
                                                  overflow:
                                                  TextOverflow.ellipsis,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14)),
                                        ),
                                        Container(
                                          margin:
                                          const EdgeInsets.only(bottom: 3),
                                          child: Text(song_recommend['ALBUM'] ?? "",
                                              style: const TextStyle(
                                                  overflow:
                                                  TextOverflow.ellipsis,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14)),
                                        ),
                                      ],
                                    ),
                                  )
                                ])
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
