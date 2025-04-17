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
import 'song_info_screen.dart';

class HistoryScreen extends StatefulWidget {

  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {

  List<ApiSearch> fullSearchList = []; // 전체 곡
  List<ApiSearch> searchList = []; // 검색 필터링 곡

  List<ApiRecommend> recommendList = []; // 추천 음악 리스트

  // API 요청 추천 음악 리스트 받기
  Future<void> fetchApiData() async {

    // 검색 목록
    try {
      http.Response response = await http.get(Uri.parse('${ApiService.historyUrl}/json?uid=${MyApp.uid}'));

      if (response.statusCode == 200) {
        String jsonData = response.body;
        List<dynamic> apiData = jsonDecode(jsonData);
        // print('검색 목록 곡 리스트 : $apiData');

        if (mounted) {
          setState(() {
            fullSearchList = apiData.map((item) => ApiSearch.fromJson(item as Map<String, dynamic>)).toList();
            searchList = fullSearchList;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('검색 목록 리스트 API 오류');
      print(e);
      if (!mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }

    // 추천 음악
    try {
      http.Response response = await http.get(Uri.parse('${ApiService.recommendUrl}/json?uid=${MyApp.uid}'));

      String jsonData = response.body;
      List<dynamic> apiRecommend = jsonDecode(jsonData);
      // print('추천 음악 리스트 ::::::::::::::::::: $apiRecommend');

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

  final TextEditingController _controller = TextEditingController(); // 검색어 관리하기 위한 컨트롤러
  bool isLoading = true;

  // 위젯이 생성될 때 초기화 작업을 수행
  @override
  void initState() {
    super.initState();
    fetchApiData(); // Api Data
  }

  RegExp basicReg = RegExp(
      r'[ㄱ-ㅎㅏ-ㅣ가-힣ᆞᆢㆍᆢᄀᆞᄂᆞᄃᆞᄅᆞᄆᆞᄇᆞᄉᆞᄋᆞᄌᆞᄎᆞᄏᆞᄐᆞᄑᆞᄒᆞa-zA-Z0-9\s~!@#$%^&*()_+=:`,./?><{}*\-]'
  );

  // 검색 기능
  void searchSongs(String query) {
    if (query.isNotEmpty) {
      setState(() {
        searchList = searchList.where((song) {
          return song.title.toLowerCase().contains(query.toLowerCase()) ||
            song.album.toLowerCase().contains(query.toLowerCase()) ||
            song.artist.toLowerCase().contains(query.toLowerCase());
        }).toList();
      });
    } else {
      // 검색어가 비어있으면 전체 목록 로드
      setState(() {
        searchList = fullSearchList;
      });
    }
  }

  // 리스트 삭제 버튼
  void showDeleteDialog(context, songId, index) {

    int themeValue = Provider.of<MyAppState>(context, listen: false).selectedValue;

    double c_width = MediaQuery.of(context).size.width;
    double c_height = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // 모서리 둥글게
          backgroundColor: themeValue == 2 ? Color.fromRGBO(66, 66, 66, 1) : Colors.white,
          child: Container(
            width: c_width * 0.75,
            height: c_height * 0.22,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목 영역
                SizedBox(
                  height: c_height * 0.13,
                  child: Center(
                    child: Text(
                      '이 항목을 삭제하시겠습니까?',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color.fromRGBO(151, 151, 151, 1)),
                    ),
                  ),
                ),

                // 구분선 추가
                Divider(thickness: 1, height: 1, color: Colors.grey),

                // 버튼 영역
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(color: Colors.grey, width: 1)
                          )
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('아니오',style: TextStyle(fontSize: 16,color: Color.fromRGBO(151, 151, 151, 1)),),
                        ),
                      ),
                    ),

                    Expanded(
                      child: Container(
                        child: TextButton(
                          onPressed: () async {
                            Navigator.of(context).pop();

                            try {
                              // http.Response response = await http.get(Uri.parse('${ApiService.historyUrl}/json?uid=${MyApp.uid}&id=${songId}&h_id=${index}&proc=del'));
                              http.Response response = await http.get(Uri.parse('${ApiService.historyUrl}/json?uid=${MyApp.uid}&id=${songId}&proc=del'));
                              if (response.statusCode == 200) {
                                setState(() {
                                  searchList.removeAt(index);  // 리스트에서 해당 항목 제거
                                });
                              }
                            } catch (e) {
                              print('searched song delete error');
                            }
                          },
                          child: Text('예',style: TextStyle(fontSize: 16,color: Color.fromRGBO(64, 220, 196, 1)),),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    );
  }
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    int themeValue = context.watch<MyAppState>().selectedValue;
    // },

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '발견한 노래 ${searchList.length}곡',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,),
          ),

          SizedBox(height: 10),

          Container(
            height: 50,
            child: TextFormField( // 검색창
              style: TextStyle(color: themeValue == 2 ? Colors.white : Colors.black),

              controller : _controller,
              autofocus: false,
              inputFormatters: [FilteringTextInputFormatter.allow(basicReg)],

              // onFieldSubmitted: (value) {
              //   searchSongs(value); // 엔터 입력 시 검색
              onChanged: (value) { // 바뀔 때 마다 텍스트 전달
                searchSongs(value);
                // searchSongs(_controller.text);
              },

              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: IconButton(onPressed: () {
                    searchSongs(_controller.text); // 검색 실행
                  }, icon: Icon(Icons.search)),
                ),

                // 검색어 삭제 버튼
                suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(icon: Icon(Icons.clear, color: Colors.grey), onPressed: () {
                      setState(() {
                        _controller.clear();
                        searchSongs(""); // 검색어 초기화
                      });
                    },
                  )
                  : null,

                  border: OutlineInputBorder( // 기본 설정
                  borderRadius: BorderRadius.circular(5.0),
                ),
                labelText: '곡/가수/앨범명으로 검색해주세요',
                labelStyle: TextStyle(
                  color: themeValue == 2 ? Colors.white : Colors.black,
                  fontSize: 12
                ),
                fillColor: themeValue == 2 ? Colors.black : Colors.grey[100],
                filled: true,

                // 비활성화 상태
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color:Color.fromRGBO(210, 210, 210, 1.0))
                ),

                // 포커스 상태
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

          // 검색 결과 및 로딩 상태 표시
          Expanded(
            child: SingleChildScrollView( // 같이 스크롤 되게 설정
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  isLoading
                    ? Center(child: CircularProgressIndicator()) // 로딩 중
                    : searchList.isEmpty
                    ? Center(
                      child: Text(
                        '검색 결과가 없습니다.',
                        style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.w700),
                        ),
                      )
                    :
                  ListView.builder(

                    physics: NeverScrollableScrollPhysics(),

                    shrinkWrap: true, // 높이를 결과 개수만큼만 설정
                    itemCount: searchList.length,
                    itemBuilder: (context, index) {

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              // 페이지 호출하면서 값 넘기기
                               builder: (context) => SongInfoScreen(song: searchList[index]),
                            ),
                          );
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 5),
                          height: 120,
                          padding: EdgeInsets.all(10),
                          child: Stack(
                            children: [ Row(
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
                                    mainAxisAlignment: MainAxisAlignment.center, // 수직 정렬
                                    crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
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


                  SizedBox(height: 20),
                    searchList.isNotEmpty
                    ?
                  Container()
                    :
                  Text(
                    '추천 음악',
                    style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.w900),
                  ),

                  SizedBox(height: 10),

                  searchList.isNotEmpty
                    ?
                  Container()
                    :
                    isLoading
                      ? Center(child: CircularProgressIndicator()) // 로딩 중
                      : ListView.builder(
                    shrinkWrap: true, // 내부 크기 조정 가능
                    physics: NeverScrollableScrollPhysics(), // 자체 스크롤 방지
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
}
// ------------------------------------------------------------------------------------------------------------------


// 곡 리스트 위젯
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
      margin: EdgeInsets.only(bottom: 5),
      height: 100,
      padding: EdgeInsets.all(10),
      child: Stack( // Positioned를 사용하기 위함
        children: [
          // 기본 콘텐츠

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    width: 1,
                    color: themeValue == 2 ? Color.fromRGBO(189,189,189,1) : Colors.black.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8)
                ),

                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ExtendedImage.network(
                    recommend.image,  // URL 형태로 이미지 로드
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,  // 이미지 비율에 맞게 크기 조정
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

