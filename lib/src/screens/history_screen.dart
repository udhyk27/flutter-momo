import 'dart:convert';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../model/api_search.dart';
import '/main.dart';
import '../model/api_recommend.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import 'common/custom_dialog.dart';
import 'song_info_screen.dart';

/**
 * 히스토리 스크린
 */
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {

  List<ApiSearch> fullSearchList = [];
  List<ApiSearch> searchList = [];
  List<ApiRecommend> recommendList = [];

  static const Color accentColor = Colors.deepOrange;

  /// API 요청 추천 음악 리스트 받기
  Future<void> fetchApiData() async {
    try {
      http.Response response = await http.get(Uri.parse('${ApiService().historyUrl}/json?uid=${MyApp.uid}'));

      if (response.statusCode == 200) {
        String jsonData = response.body;
        List<dynamic> apiData = jsonDecode(jsonData);
        if (mounted) {
          setState(() {
            fullSearchList = apiData.map((item) => ApiSearch.fromJson(item as Map<String, dynamic>)).toList();
            searchList = fullSearchList;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('검색 목록 리스트 API 오류 : $e');
      if (!mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }

    try {
      http.Response response = await http.get(Uri.parse('${ApiService().recommendUrl}/json?uid=${MyApp.uid}'));
      String jsonData = response.body;
      List<dynamic> apiRecommend = jsonDecode(jsonData);
      if (mounted) {
        setState(() {
          recommendList = apiRecommend.map((item) => ApiRecommend.fromJson(item as Map<String, dynamic>)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      print('추천 음악 리스트 API 오류 : $e');
      if (!mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  final TextEditingController _controller = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchApiData();
  }

  RegExp basicReg = RegExp(
      r'[ㄱ-ㅎㅏ-ㅣ가-힣ᆞᆢㆍᆢᄀᆞᄂᆞᄃᆞᄅᆞᄆᆞᄇᆞᄉᆞᄋᆞᄌᆞᄎᆞᄏᆞᄐᆞᄑᆞᄒᆞa-zA-Z0-9\s~!@#$%^&*()_+=:`,./?><{}*\-]'
  );

  /// 검색 기능
  void searchSongs(String query) {
    if (query.isNotEmpty) {
      setState(() {
        searchList = fullSearchList.where((song) {
          return song.title.toLowerCase().contains(query.toLowerCase()) ||
              song.album.toLowerCase().contains(query.toLowerCase()) ||
              song.artist.toLowerCase().contains(query.toLowerCase());
        }).toList();
      });
    } else {
      setState(() {
        searchList = fullSearchList;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int themeValue = context.watch<MyAppState>().selectedValue;
    final bool isDark = themeValue == 2;

    final Color bgColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF222222);
    final Color subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final Color dividerColor = isDark ? const Color(0xFF424242) : const Color(0xFFEFEFEF);
    final Color fieldFillColor = isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF7F7F7);
    final Color fieldBorderColor = isDark ? const Color(0xFF424242) : const Color(0xFFE0E0E0);

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 타이틀
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: -0.2,
              ),
              children: [
                const TextSpan(text: '발견한 노래 '),
                TextSpan(
                  text: '${searchList.length}',
                  style: const TextStyle(color: accentColor),
                ),
                const TextSpan(text: '곡'),
              ],
            ),
          ),

          const SizedBox(height: 14),

          /// 검색창
          SizedBox(
            height: 48,
            child: TextFormField(
              style: TextStyle(color: textColor, fontSize: 13),
              controller: _controller,
              autofocus: false,
              inputFormatters: [FilteringTextInputFormatter.allow(basicReg)],
              onChanged: (value) => searchSongs(value),
              decoration: InputDecoration(
                prefixIcon: IconButton(
                  onPressed: () => searchSongs(_controller.text),
                  icon: Icon(Icons.search, color: subTextColor, size: 20),
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: subTextColor, size: 18),
                  onPressed: () {
                    setState(() {
                      _controller.clear();
                      searchSongs("");
                    });
                  },
                )
                    : null,
                hintText: '곡 / 가수 / 앨범명으로 검색',
                hintStyle: TextStyle(color: subTextColor, fontSize: 13),
                fillColor: fieldFillColor,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: fieldBorderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: fieldBorderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: accentColor, width: 1.2),
                ),
              ),
              cursorColor: accentColor,
            ),
          ),

          const SizedBox(height: 6),

          /// 검색 결과 및 로딩 상태
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
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
                    )
                  else if (searchList.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          '검색 결과가 없습니다.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: subTextColor,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: searchList.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SongInfoScreen(song: searchList[index]),
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
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: ExtendedImage.network(
                                    searchList[index].image,
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
                                        searchList[index].title,
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
                                        searchList[index].artist,
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
                                        searchList[index].album,
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
                                /// 삭제 버튼
                                InkWell(
                                  onTap: () => showDeleteDialog(
                                      context, searchList[index].songId, index),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: subTextColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  /// 추천 음악 섹션
                  if (searchList.isNotEmpty)
                    const SizedBox.shrink()
                  else ...[
                    const SizedBox(height: 24),
                    Text(
                      '추천 음악',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recommendList.length,
                      itemBuilder: (context, index) {
                        return RecommendList(
                          recommend: recommendList[index],
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 리스트 삭제 Dialog
  void showDeleteDialog(BuildContext context, songId, index) {
    showConfirmDialog(
      context,
      title: '이 항목을 삭제하시겠습니까?',
      cancelText: '아니오',
      confirmText: '예',
      onConfirm: () async {
        try {
          http.Response response = await http.get(
            Uri.parse(
              '${ApiService().historyUrl}/json?uid=${MyApp.uid}&id=${songId}&proc=del',
            ),
          );

          if (response.statusCode == 200) {
            setState(() {
              searchList.removeAt(index);
            });
          }
        } catch (e) {
          print('searched song delete error');
        }
      },
    );
  }
}

/// 추천 곡 리스트 위젯
class RecommendList extends StatelessWidget {
  final ApiRecommend recommend;

  const RecommendList({
    super.key,
    required this.recommend,
  });

  @override
  Widget build(BuildContext context) {
    int themeValue = context.watch<MyAppState>().selectedValue;
    final bool isDark = themeValue == 2;

    final Color textColor = isDark ? Colors.white : const Color(0xFF222222);
    final Color subTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final Color dividerColor = isDark ? const Color(0xFF424242) : const Color(0xFFEFEFEF);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: dividerColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: ExtendedImage.network(
              recommend.image,
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
                  recommend.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 3),
                Text(
                  recommend.artist,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: textColor.withOpacity(0.85),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(
                  recommend.album,
                  style: TextStyle(fontSize: 12, color: subTextColor),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}