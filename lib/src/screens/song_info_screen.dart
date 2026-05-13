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
List<num> listY = [];
var intX;
List listX = [];

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

const Color _accentColor = Colors.deepOrange;

class SongInfoScreen extends StatefulWidget {
  final ApiSearch song;
  const SongInfoScreen({super.key, required this.song});

  @override
  State<SongInfoScreen> createState() => _SongInfoScreenState();
}

class _SongInfoScreenState extends State<SongInfoScreen> {

  List<DetailProgram> infoProgram = [];
  bool isLoading = true;
  bool programLoading = true;

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

      final Map<String, dynamic> detailList = jsonDecode(response.body);

      song_recommends = detailList['song_recommend'] ?? [];
      count = detailList['count'] ?? 0;
      song_cnts = detailList['song_cnts'] ?? [];
      broad_weeks_chart = detailList['broad_weeks_chart'] ?? [];

      print('broad_weeks_chart: $broad_weeks_chart');

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('노래 상세화면 API 통신 오류 ################ $e');
    }

    try {
      final programsResponse = await http.get(
        Uri.parse('${ApiService().programsUrl}/json?id=${widget.song.songId}'),
      );

      final List<dynamic> programList = jsonDecode(programsResponse.body);

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

  /// 섹션 타이틀
  Widget _sectionTitle(String text, Color textColor) {
    return Row(
      children: [
        Container(width: 3, height: 16, color: _accentColor),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: textColor,
            fontFamily: 'NotoSansKR-Bold',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  /// TV / RADIO 뱃지
  Widget _typeBadge(String type, bool isDark) {
    final bool isTv = type == 'TV';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isTv
            ? _accentColor.withOpacity(0.12)
            : (isDark ? Colors.white12 : const Color(0xFFF0F0F0)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        isTv ? 'TV' : 'RADIO',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: isTv
              ? _accentColor
              : (isDark ? Colors.grey[300] : Colors.grey[700]),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: _accentColor,
              strokeWidth: 2.0,
            ),
          ),
        ),
      );
    }

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
    final Color innerBoxColor = isDark
        ? const Color(0xFF1F1F1F)
        : const Color(0xFFF7F7F7);

    final isExist = programs.isEmpty;
    final isExist2 = song_recommends.isEmpty;

    var deviceWidth = MediaQuery.of(context).size.width;
    var deviceHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        backgroundColor: bgColor,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back, color: textColor, size: 22),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Share.share(
                '${ApiService().shareUrl}?f_id=${widget.song.songId}',
                sharePositionOrigin: Rect.fromLTRB(0, 0, deviceWidth, deviceHeight * 0.5),
              );
            },
            icon: Icon(Icons.share, color: textColor, size: 20),
          )
        ],
      ),

      body: SingleChildScrollView(
        child: SafeArea(
          bottom: Platform.isAndroid,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                /// 곡 정보 박스
                Container(
                  decoration: BoxDecoration(
                    color: innerBoxColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(width: 1, color: dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(11),
                            topRight: Radius.circular(11),
                          ),
                          child: ExtendedImage.network(
                            '$image',
                            fit: BoxFit.cover,
                            loadStateChanged: (state) {
                              if (state.extendedImageLoadState == LoadState.failed) {
                                return SizedBox(
                                  child: Image.asset(
                                    'assets/no_image.png',
                                    fit: BoxFit.cover,
                                  ),
                                );
                              }
                              return null;
                            },
                          ),
                        ),
                      ),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 19.0,
                                fontFamily: 'NotoSansKR-Medium',
                                fontWeight: FontWeight.w700,
                                color: textColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              artist,
                              style: TextStyle(
                                color: textColor.withOpacity(0.85),
                                fontSize: 14.0,
                                fontFamily: 'NotoSansKR-Regular',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              album,
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 12.0,
                                fontFamily: 'NotoSansKR-Regular',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              date_,
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 11.5,
                                fontFamily: 'NotoSansKR-Regular',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                /// 주간 방송 차트
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('주간 방송 차트', textColor),
                      const SizedBox(height: 12),

                      isLoading
                          ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: _accentColor,
                          strokeWidth: 2.0,
                        ),
                      )
                          : Container(
                        width: deviceWidth,
                        height: 200,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: innerBoxColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(width: 1, color: dividerColor),
                        ),
                        child: Center(
                          child: FractionallySizedBox(
                            widthFactor: 0.9,
                            heightFactor: 0.9,
                            child: line_chart(broad_weeks_chart),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// 안내 문구
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: innerBoxColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset('assets/result_search.png', width: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '방송차트: 지상파(TV, RADIO) 집계기준',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '방송차트 자료는 에어모니터에서 제공받았습니다.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _accentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                /// 방송 재생 정보 리스트
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _sectionTitle('최신 방송 재생 정보', textColor),
                          const Spacer(),
                          if (!isExist)
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailScreen(
                                    deviceId: "",
                                    title: title,
                                    image: image,
                                    artist: artist,
                                    songId: widget.song.songId,
                                    album: album,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '더보기',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: subTextColor,
                                      fontFamily: 'NotoSansKR-Regular',
                                    ),
                                  ),
                                  Icon(Icons.chevron_right,
                                      size: 16, color: subTextColor),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: isExist ? 100 : 430,
                        child: programLoading
                            ? Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: _accentColor,
                              strokeWidth: 2.0,
                            ),
                          ),
                        )
                            : isExist
                            ? Center(
                          child: Text(
                            '최신 방송 재생정보가 없습니다.',
                            style: TextStyle(
                              color: subTextColor,
                              fontFamily: 'NotoSansKR-Medium',
                              fontSize: 13,
                            ),
                          ),
                        )
                            : Row(children: [_listView(programs)]),
                      ),
                      if (!isExist)
                        Container(
                          margin: const EdgeInsets.fromLTRB(0, 4, 0, 24),
                          child: Center(
                            child: SmoothPageIndicator(
                              controller: pageController,
                              count: programs.isEmpty
                                  ? 1
                                  : (programs.length / 4).ceil(),
                              effect: const WormEffect(
                                activeDotColor: _accentColor,
                                dotColor: Color(0xFFD9D9D9),
                                dotHeight: 6,
                                dotWidth: 6,
                                type: WormType.thinUnderground,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                /// 추천 음악 리스트
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('추천 음악', textColor),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: isExist2 ? 100 : 430,
                        child: isLoading
                            ? Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: _accentColor,
                              strokeWidth: 2.0,
                            ),
                          ),
                        )
                            : isExist2
                            ? Center(
                          child: Text(
                            '추천 음악이 없습니다.',
                            style: TextStyle(
                              color: subTextColor,
                              fontFamily: 'NotoSansKR-Medium',
                              fontSize: 13,
                            ),
                          ),
                        )
                            : Row(children: [_listView2(song_recommends)]),
                      ),
                      if (!isExist2)
                        Container(
                          margin: const EdgeInsets.fromLTRB(0, 4, 0, 24),
                          child: Center(
                            child: SmoothPageIndicator(
                              controller: pageController2,
                              count: (song_recommends.length / 4).ceil(),
                              effect: const WormEffect(
                                activeDotColor: _accentColor,
                                dotColor: Color(0xFFD9D9D9),
                                dotHeight: 6,
                                dotWidth: 6,
                                type: WormType.thinUnderground,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 차트
  Widget line_chart(broad_weeks_chart) {
    int themeValue = context.watch<MyAppState>().selectedValue;

    broad_weeks_chart.sort((a, b) {
      final int aMonth = int.parse(a['MONTH'].toString());
      final int bMonth = int.parse(b['MONTH'].toString());
      final int aWeek = int.parse(a['WEEK'].toString());
      final int bWeek = int.parse(b['WEEK'].toString());
      if (aMonth == bMonth) return aWeek.compareTo(bWeek);
      return aMonth.compareTo(bMonth);
    });

    final ranksIn100 = broad_weeks_chart
        .map((e) => int.tryParse(e['RANK'].toString()) ?? 0)
        .where((r) => r > 0 && r <= 100)
        .toList();

    if (ranksIn100.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: themeValue == 2 ? Colors.grey.shade700 : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '주간 방송 차트 순위는 TOP 100만 제공됩니다.',
            style: TextStyle(
              fontSize: 12,
              color: themeValue == 2 ? Colors.white : Colors.black,
            ),
          ),
        ),
      );
    }

    final int minRank = ranksIn100.reduce((a, b) => a < b ? a : b);
    final int maxRank = ranksIn100.reduce((a, b) => a > b ? a : b);

    final List<FlSpot> spots = [];
    final List<int> showingIndicators = [];

    for (int i = 0; i < broad_weeks_chart.length; i++) {
      final int rank = int.tryParse(broad_weeks_chart[i]['RANK'].toString()) ?? 0;
      double y = 0;

      if (rank > 0) {
        y = (maxRank - rank + 1).toDouble();
      }

      spots.add(FlSpot(i.toDouble(), y));

      if (y > 0) showingIndicators.add(i);
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: spots.length - 1,
        minY: 0,
        maxY: (maxRank - minRank + 1).toDouble(),
        baselineY: 0,
        borderData: FlBorderData(show: false),

        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (value) => FlLine(
            strokeWidth: 1,
            color: themeValue == 2
                ? Colors.grey.withOpacity(0.4)
                : Colors.grey.withOpacity(0.25),
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
              getTitlesWidget: bottomTitleWidgets,
            ),
          ),
        ),

        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.15,
            barWidth: 2.5,
            color: _accentColor,
            belowBarData: BarAreaData(show: false),
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, _) => spot.y > 0,
              getDotPainter: (spot, percent, barData, index) {
                final int originalRank =
                    int.tryParse(broad_weeks_chart[index]['RANK'].toString()) ?? 0;

                return RankDotPainter(
                  rank: originalRank,
                  color: _accentColor,
                );
              },
            ),
            showingIndicators: showingIndicators,
          ),
        ],

        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes.map((index) {
              return TouchedSpotIndicatorData(
                FlLine(color: Colors.transparent, strokeWidth: 0),
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
                    color: _accentColor,
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
    final dateList = broad_weeks_chart
        .map((e) =>
    '${int.parse(e['MONTH'].toString().substring(4, 6))}월 ${e['WEEK']}주차')
        .toList();

    if (index < 0 || index >= dateList.length) {
      return const SizedBox.shrink();
    }

    return SideTitleWidget(
      meta: meta,
      space: 8,
      child: Text(
        dateList[index],
        style: const TextStyle(fontSize: 10.5),
      ),
    );
  }

  /// 최신 방송 재생 정보 리스트
  Widget _listView(programs) {
    int themeValue = context.watch<MyAppState>().selectedValue;
    final bool isDark = themeValue == 2;
    final Color textColor = isDark ? Colors.white : const Color(0xFF222222);
    final Color subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final Color dividerColor =
    isDark ? const Color(0xFF424242) : const Color(0xFFEFEFEF);
    final Color imageBorderColor =
    isDark ? const Color(0xFFBDBDBD) : Colors.black.withOpacity(0.08);

    return Expanded(
      child: PageView.builder(
        itemCount: (programs.length / 4).ceil(),
        controller: pageController,
        itemBuilder: (BuildContext context, int pageIndex) {
          return ListView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
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
              String parseProgramDate = DateFormat('yyyy.MM.dd')
                  .format(DateTime.parse(programDate))
                  .toString();

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: dividerColor, width: 1),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          width: 1,
                          color: imageBorderColor,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: ExtendedImage.network(
                          program['F_LOGO'],
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
                          _typeBadge(program['F_TYPE'], isDark),
                          const SizedBox(height: 5),
                          Text(
                            program['CL_NM'],
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'NotoSansKR-Bold',
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            program['F_NAME'],
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
                            parseProgramDate,
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
          );
        },
      ),
    );
  }

  /// 추천 음악 리스트
  Widget _listView2(song_recommends) {
    int themeValue = context.watch<MyAppState>().selectedValue;
    final bool isDark = themeValue == 2;
    final Color textColor = isDark ? Colors.white : const Color(0xFF222222);
    final Color subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final Color dividerColor =
    isDark ? const Color(0xFF424242) : const Color(0xFFEFEFEF);
    final Color imageBorderColor =
    isDark ? const Color(0xFFBDBDBD) : Colors.black.withOpacity(0.08);

    return Expanded(
      child: PageView.builder(
        itemCount: (song_recommends.length / 4).ceil(),
        controller: pageController2,
        itemBuilder: (BuildContext context, int pageIndex) {
          return ListView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: song_recommends == null
                ? 0
                : min(4, song_recommends.length - pageIndex * 4),
            itemBuilder: (context, index) {
              final song_recommend = pageIndex == 0
                  ? song_recommends[index]
                  : song_recommends[index + (pageIndex * 4)];

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: dividerColor, width: 1),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          width: 1,
                          color: imageBorderColor,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: ExtendedImage.network(
                          song_recommend['IMAGE'] ?? "",
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
                          Text(
                            song_recommend['TITLE'] ?? "",
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'NotoSansKR-Bold',
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            song_recommend['ARTIST'] ?? "",
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
                            song_recommend['ALBUM'] ?? "",
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 11.5,
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
          );
        },
      ),
    );
  }
}