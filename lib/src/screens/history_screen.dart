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

  List<ApiSearch> fullSearchList = []; /// 전체 곡
  List<ApiSearch> searchList = []; /// 검색 필터링 곡

  List<ApiRecommend> recommendList = []; /// 추천 음악 리스트

  /// API 요청 추천 음악 리스트 받기
  Future<void> fetchApiData() async {
    /// 검색 목록
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

    /// 추천 음악 리스트
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

  final TextEditingController _controller = TextEditingController(); /// 검색어 관리하기 위한 컨트롤러
  bool isLoading = true;

  /// 위젯이 생성될 때 초기화 작업을 수행
  @override
  void initState() {
    super.initState();
    fetchApiData(); /// Api Data
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
      /// 검색어가 비어있으면 전체 목록 로드
      setState(() {
        searchList = fullSearchList;
      });
    }
  }

  /// Container
  @override
  Widget build(BuildContext context) {
    int themeValue = context.watch<MyAppState>().selectedValue;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: BoxDecoration(
        color: themeValue == 2 ? Color.fromRGBO(90, 90, 90, 1.0) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        )
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '발견한 노래 ${searchList.length}곡',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,),
          ),

          SizedBox(height: 10),

          Container(
            height: 50,
            child: TextFormField( /// 검색창
              style: TextStyle(color: themeValue == 2 ? Colors.white : Colors.black),
              controller : _controller,
              autofocus: false,
              inputFormatters: [FilteringTextInputFormatter.allow(basicReg)],

              onChanged: (value) { /// 바뀔 때 마다 텍스트 전달
                searchSongs(value);
              },

              decoration: InputDecoration(
                prefixIcon: IconButton(onPressed: () {
                  searchSongs(_controller.text); /// 검색 실행
                }, icon: Icon(Icons.search)),

                /// 검색어 삭제 버튼
                suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(icon: Icon(Icons.clear, color: Colors.grey), onPressed: () {
                      setState(() {
                        _controller.clear();
                        searchSongs(""); /// 검색어 초기화
                      });
                    },
                  )
                  : null,

                  border: OutlineInputBorder( /// 기본 설정
                  borderRadius: BorderRadius.circular(5.0),
                ),
                labelText: '곡/가수/앨범명으로 검색해주세요',
                labelStyle: TextStyle(
                  color: themeValue == 2 ? Colors.white : Colors.black,
                  fontSize: 12
                ),
                fillColor: themeValue == 2 ? Colors.black : Colors.grey[100],
                filled: true,

                /// 비활성화 상태
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color:Color.fromRGBO(210, 210, 210, 1.0))
                ),

                /// 포커스 상태
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: themeValue == 2 ? Colors.white : Color.fromRGBO(210, 210, 210, 1.0)
                  )
                )
              ),
              cursorColor: Colors.blue
            ),
          ),

          SizedBox(height: 10),

          /// 검색 결과 및 로딩 상태 표시
          Expanded(
            child: SingleChildScrollView( /// 같이 스크롤 되게 설정
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isLoading
                    ? Center(child: CircularProgressIndicator(color: Colors.black,strokeWidth: 2.0,)) /// 로딩 중
                    : searchList.isEmpty
                      ? Center(
                        child: Container(
                          height: 100,
                          alignment: Alignment.center,
                          child: Text(
                            '검색 결과가 없습니다.',
                            style: TextStyle(
                              fontSize: 17.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      : ListView.builder(
                        physics: NeverScrollableScrollPhysics(),

                        shrinkWrap: true, /// 높이를 결과 개수만큼만 설정
                        itemCount: searchList.length,
                        itemBuilder: (context, index) {

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => SongInfoScreen(song: searchList[index]),),
                              );
                            },
                            child: Container(
                              height: 110,
                              child: Stack(
                                children: [
                                  Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(5),
                                        child: ExtendedImage.network(
                                          searchList[index].image,
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
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              searchList[index].title,
                                              overflow:
                                              TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                            ),
                                            Text(
                                              searchList[index].artist,
                                              overflow:
                                              TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                            ),
                                            Text(
                                              searchList[index].album,
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
                                  Positioned(
                                    top: -10,
                                    right: 0,
                                    child: IconButton(
                                      onPressed: () => showDeleteDialog(context, searchList[index].songId, index),
                                      icon: Icon(
                                        Icons.close,
                                        size: 15,
                                        color:
                                        themeValue == 2 ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ),
                                ]
                              ),
                            ),
                          );
                        },
                      ),

                  searchList.isNotEmpty
                  ? Container()
                  : Text('추천 음악', style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.w600),),

                  searchList.isNotEmpty
                    ? Container()
                    : ListView.builder(
                    shrinkWrap: true, /// 내부 크기 조정
                    physics: NeverScrollableScrollPhysics(), /// 자체 스크롤 방지
                    itemCount: recommendList.length,
                    itemBuilder: (context, index) {
                      return RecommendList(
                        recommend: recommendList[index],
                      );
                    },
                  ),
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

/// 곡 리스트 위젯
class RecommendList extends StatelessWidget {
  final ApiRecommend recommend;

  const RecommendList({
    super.key,
    required this.recommend,
  });

  @override
  Widget build(BuildContext context) {
    int themeValue = context.watch<MyAppState>().selectedValue;
    return Container(
      height: 90,
      child: Stack( /// Positioned를 사용하기 위함
        children: [
          /// 기본 콘텐츠
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8)
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ExtendedImage.network(
                    recommend.image,  /// URL 형태로 이미지 로드
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,  /// 이미지 비율에 맞게 크기 조정
                    loadStateChanged: (state) {
                      if (state.extendedImageLoadState == LoadState.failed) {
                        return SizedBox(width: 80, height: 80, child: Image.asset('assets/no_image.png'),);
                      }
                      return null;
                    },
                  )
                ),
              ),

              SizedBox(width: 10,),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommend.title,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      recommend.artist,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      recommend.album,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

