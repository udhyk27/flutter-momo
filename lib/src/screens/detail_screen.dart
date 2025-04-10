import 'dart:convert';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '/main.dart';

import '../services/api_service.dart';
import 'package:http/http.dart' as http;
import '../model/api_detail_programs.dart';

class DetailScreen extends StatefulWidget {

  // Chart Screen 에서 넘긴 값

  final String title;
  final String image;
  final String artist;
  final String songId;
  final String deviceId;
  final String album;

  DetailScreen({
    required this.title,
    required this.image,
    required this.artist,
    required this.songId,
    required this.deviceId,
    required this.album,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {

  List<DetailProgram> detailProgram = [];
  bool isLoading = false;


  // 프로그램 API 요청
  Future<void> fetchData() async {

    print('곡 코드 :::::::::::::::: ${widget.songId}');

    try {
      http.Response programs_response = await http.get(Uri.parse('${ApiService.programsUrl}/json?id=${widget.songId}'));

      // programs data 파싱
      String programs_json = programs_response.body;
      List<dynamic> programsList = jsonDecode(programs_json);

      print(programsList);

      setState(() {
        detailProgram = programsList.map((item) => DetailProgram.fromJson(item as Map<String, dynamic>)).toList();
        isLoading = false;
      });

      print(detailProgram);

    } catch (e) {
      print('상세화면 API 통신 오류 ################# : $e');
      setState(() {
        isLoading = false;
      });
    }
  }


  @override
  void initState() {
    super.initState();
    fetchData();
  }


  @override
  Widget build(BuildContext context) {
    int themeValue = context.watch<MyAppState>().selectedValue;
    Color textColor = themeValue == 2 ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: themeValue == 2 ? Colors.black : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: themeValue == 2 ? Colors.black : Colors.grey[100],
        title: Text('모모 방송 재생 정보',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: themeValue == 2 ? Colors.white : Colors.black
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            // 검색 차트로 이동
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back, color: themeValue == 2 ? Colors.white : Colors.black,),
        ),
      ),
      body: isLoading
        ? Center(child: CircularProgressIndicator())
        : Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 10),
        padding: EdgeInsets.only(left: 20, right: 20),
        decoration: BoxDecoration(
          color: themeValue == 2 ? Color.fromRGBO(90, 90, 90, 1.0) : Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.all(20),
              
              // 선택한 곡 정보
              child: Row(
                children: [
                  Container(

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5)
                    ),

                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: ExtendedImage.network(
                        widget.image,
                        width: 100,
                        loadStateChanged: (state) {
                          if (state.extendedImageLoadState == LoadState.failed) {
                            return SizedBox(child: Image.asset('assets/no_image.png'),);
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  Container(
                    width: 120,
                    margin: EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'NotoSansKR-Medium',
                            color: textColor
                          ),
                        ),
                        Text(
                          widget.artist,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(color: textColor),
                        ),
                        Text(
                          widget.album,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(color: textColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: themeValue == 2 ? Colors.white : Colors.black, thickness: 1.0),

            SizedBox(height: 15),

            Container(
              alignment: Alignment.bottomLeft,
              child: Text(
                '최신 방송내역',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoSansKR-Black',
                  color: textColor
                ),
              ),
            ),

            SizedBox(height: 10),

            Expanded(
              child:
              ListView.builder(
                itemCount: detailProgram.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [

                        Container(
                          decoration: BoxDecoration(
                            border:Border.all(
                              width: 1,
                              color: themeValue == 2 ? Color.fromRGBO(189,189,189,1.0) : Colors.black.withValues(alpha:0.3)
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(

                            borderRadius: BorderRadius.circular(8),
                            child: ExtendedImage.network(
                              detailProgram[index].logo,
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
                        ),
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.asset(
                                detailProgram[index].type == 'TV' ? 'assets/momo_assets/icon_tv.png' : 'assets/momo_assets/icon_radio.png',
                                width: 50,
                                height: 20,
                              ),
                              Text(
                                detailProgram[index].channelName,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                              ),
                              Text(
                                detailProgram[index].name,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                              ),
                              Text(
                                detailProgram[index].date,
                                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
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
          ],
        ),
      ),
    );
  }
}
