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

/***
 * 검색차트 스크린
 */
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

  ScrollController _scrollController = ScrollController();
  ScrollController _scrollController2 = ScrollController();

  static const Color accentColor = Colors.deepOrange;

  /// API 요청 - 모모 검색 차트
  Future<void> fetchChart() async {
    if (isChartLoading || !hasMoreMomo) return;

    setState(() {
      isChartLoading = true;
    });

    try {
      double currentScrollPosition = _scrollController.hasClients ? _scrollController.position.pixels : 0;

      http.Response response = await http.get(Uri.parse('${ApiService().mmchartUrl}?page=$page'));

      if (response.statusCode != 200) {
        throw Exception('차트 데이터 로딩 실패 ${response.statusCode}');
      }

      String jsonData = response.body;
      List<dynamic> map = jsonDecode(jsonData);

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
          hasMoreMomo = false;
        }
        setState(() {
          isChartLoading = false;
        });
      }

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
    if (isAirChartLoading || !hasMoreAir) return;

    setState(() {
      isAirChartLoading = true;
    });

    try {
      double currentScrollPosition = _scrollController2.hasClients ? _scrollController2.position.pixels : 0;
      http.Response response = await http.get(Uri.parse('${ApiService().airchartUrl}?page=$page2'));

      if (response.statusCode != 200) {
        throw Exception('에어차트 데이터 로딩 실패 ${response.statusCode}');
      }

      String jsonData = response.body;
      List<dynamic> map = jsonDecode(jsonData);
      if (mounted) {
        if (map.isNotEmpty) {
          setState(() {
            air_chart.addAll(map
                .map((item) => ApiPrograms.fromJson(item as Map<String, dynamic>))
                .toList());
          });
          page2++;
        } else {
          print('에어차트 데이터 X');
          setState(() {
            hasMoreAir = false;
            if (air_chart.isEmpty) {
              air_chart.add(ApiPrograms.empty());
            }
          });
        }
        setState(() {
          isAirChartLoading = false;
        });
      }

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

  String? _uid;
  Future<void> getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        _uid = androidInfo.id;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        _uid = iosInfo.identifierForVendor;
      }
    } catch (e) {
      _uid = 'Failed to get id';
    }
  }

  PageController _pageController = PageController();

  List<ApiMmChart> momo_sch_list = [];
  List<ApiPrograms> air_chart = [];

  int _currentIndex = 0;
  double _barPosition = 0;
  String _currentText = '모모에서 가장 많이 검색된 음원입니다.';

  bool hasMoreMomo = true;
  bool hasMoreAir = true;

  @override
  void initState() {
    super.initState();

    fetchChart();
    fetchAirChart();
    getDeviceId();

    _scrollController.addListener(() {
      if (hasMoreMomo && (_scrollController.position.pixels == _scrollController.position.maxScrollExtent)) {
        fetchChart();
      }
    });

    _scrollController2.addListener(() {
      if (hasMoreAir && (_scrollController2.position.pixels == _scrollController2.position.maxScrollExtent)) {
        fetchAirChart();
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
    final bool isDark = themeValue == 2;

    final Color bgColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF222222);
    final Color subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final Color dividerColor = isDark ? const Color(0xFF424242) : const Color(0xFFEFEFEF);

    double screenWidth = MediaQuery.of(context).size.width - 50;

    void _onButtonClick(int index) {
      setState(() {
        _currentIndex = index;
        _barPosition = _currentIndex == 0 ? 0 : screenWidth / 2;
        _currentText = _currentIndex == 0
            ? "모모에서 가장 많이 검색된 음원입니다."
            : "최근 방송 재생 음원입니다.  by 에어모니터";
      });
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      child: Column(
        children: [
          /// 탭 버튼
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    _pageController.animateToPage(0,
                        duration: const Duration(milliseconds: 300), curve: Curves.ease);
                    _onButtonClick(0);
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.transparent),
                    overlayColor: MaterialStateProperty.all(Colors.transparent),
                    padding: MaterialStateProperty.all(
                        const EdgeInsets.symmetric(vertical: 12)),
                  ),
                  child: Text(
                    '모모 검색 차트',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: _currentIndex == 0 ? FontWeight.w700 : FontWeight.w500,
                      color: _currentIndex == 0
                          ? accentColor
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    _pageController.animateToPage(1,
                        duration: const Duration(milliseconds: 300), curve: Curves.ease);
                    _onButtonClick(1);
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.transparent),
                    overlayColor: MaterialStateProperty.all(Colors.transparent),
                    padding: MaterialStateProperty.all(
                        const EdgeInsets.symmetric(vertical: 12)),
                  ),
                  child: Text(
                    '에어차트',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: _currentIndex == 1 ? FontWeight.w700 : FontWeight.w500,
                      color: _currentIndex == 1
                          ? accentColor
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ),
                ),
              ),
            ],
          ),

          /// 인디케이터 (전체 라인 + 강조 바)
          Stack(
            children: [
              Container(
                height: 2,
                color: dividerColor,
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: screenWidth / 2,
                height: 2,
                color: accentColor,
                margin: EdgeInsets.only(left: _barPosition),
              ),
            ],
          ),

          /// 페이지뷰
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              physics: const NeverScrollableScrollPhysics(),
              children: [
                //// ======================== 모모 검색 차트 ========================
                Stack(
                  children: [
                    RefreshIndicator(
                      color: accentColor,
                      backgroundColor: isDark ? const Color(0xFF3A3A3A) : Colors.white,
                      onRefresh: fetchChart,
                      child: Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: false,
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: momo_sch_list.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                child: Text(
                                  _currentText,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: subTextColor,
                                  ),
                                ),
                              );
                            }

                            final dataIndex = index - 1;
                            final item = momo_sch_list[dataIndex];

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailScreen(
                                      title: item.title,
                                      artist: item.artist,
                                      album: item.album,
                                      image: item.image,
                                      songId: item.songId,
                                      deviceId: _uid.toString(),
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: dividerColor, width: 1),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      child: Text(
                                        '${dataIndex + 1}',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: dataIndex < 3 ? accentColor : subTextColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: ExtendedImage.network(
                                        item.image,
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
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13.5,
                                              color: textColor,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            item.artist,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w400,
                                              fontSize: 12,
                                              color: textColor.withOpacity(0.85),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item.album,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: subTextColor,
                                            ),
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
                      ),
                    ),
                    if (isChartLoading)
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: accentColor,
                              strokeWidth: 2.0,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                //// ======================== 에어 차트 ========================
                Stack(
                  children: [
                    RefreshIndicator(
                      color: accentColor,
                      backgroundColor: isDark ? const Color(0xFF3A3A3A) : Colors.white,
                      onRefresh: fetchAirChart,
                      child: Scrollbar(
                        controller: _scrollController2,
                        thumbVisibility: false,
                        child: ListView.builder(
                          controller: _scrollController2,
                          itemCount: air_chart.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                child: Text(
                                  _currentText,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: subTextColor,
                                  ),
                                ),
                              );
                            }

                            final dataIndex = index - 1;
                            final item = air_chart[dataIndex];

                            if (item.fSongId == '-1') {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 60),
                                child: Center(
                                  child: Text(
                                    '차트를 준비중입니다',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: subTextColor,
                                    ),
                                  ),
                                ),
                              );
                            }

                            final bool isTv = item.fType == 'TV';

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
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        width: 1,
                                        color: isDark
                                            ? const Color(0xFFBDBDBD)
                                            : Colors.black.withOpacity(0.08),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(5),
                                      child: ExtendedImage.network(
                                        item.fLogo,
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
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
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
                                          item.fName,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13.5,
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.sTitle,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w400,
                                            fontSize: 12,
                                            color: textColor.withOpacity(0.85),
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          item.sArtist,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontSize: 12,
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
                    ),
                    if (isAirChartLoading)
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: accentColor,
                              strokeWidth: 2.0,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}