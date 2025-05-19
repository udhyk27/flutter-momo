import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SongInfo extends StatefulWidget {

  final Map<String, dynamic> song;

  const SongInfo({
    super.key,
    required this.song
  });

  @override
  State<SongInfo> createState() => _SongInfoState();
}

class _SongInfoState extends State<SongInfo> {

  String font = 'NotoSansKR-Regular';
  List<Color> gradientColors = [
    Color.fromRGBO(62, 195, 255, 1.0), // 위쪽 색
    Color.fromRGBO(194, 40, 222, 1.0), // 아래쪽 색
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(62, 195, 255, 1.0),
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack (
                children: [

                  ExtendedImage.network(
                    widget.song['IMAGE'] ?? '',
                    fit: BoxFit.cover,

                    loadStateChanged: (state) {
                      switch (state.extendedImageLoadState) {
                        case LoadState.loading:
                        // 로딩 중일 때 보여줄 커스텀 위젯
                          return Container(
                            decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: gradientColors
                                )
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(width: MediaQuery.of(context).size.width * 0.6, child: Image.asset('assets/loading2_blue.gif', fit: BoxFit.contain,)),
                                Text("곡 발견!", style: TextStyle(color: Colors.white, fontFamily: 'NotoSansKR-Regular',)),
                              ],
                            ),
                          );

                        case LoadState.completed:
                          return null; // 기본 이미지 렌더링

                        case LoadState.failed:
                          return Image.asset('assets/no_image.png', fit: BoxFit.cover);
                      }
                    },
                  ),

                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: MediaQuery.of(context).size.height * 0.5, // 원하는 높이만큼
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 1.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Positioned( // 글씨
                    left: 0,
                    right: 0,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          widget.song['TITLE'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 18.sp,
                            // shadows: [Shadow(blurRadius: 3, color: Colors.black54)],
                          ),
                        ),
                        Text(
                          widget.song['ARTIST'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 14.sp,
                            // shadows: [Shadow(blurRadius: 2, color: Colors.black38)],
                          ),
                        ),
                        // Text(
                        //   widget.song['ALBUM'] ?? '', style: TextStyle(color: Colors.white70, fontFamily: font, fontSize: 12.sp),
                        //   maxLines: 1,
                        //   overflow: TextOverflow.ellipsis,
                        // ),
                        // Text(widget.song['date'] ?? '', style: TextStyle(color: Colors.white70, fontFamily: font, fontSize: 12.sp),),

                      ],
                    ),
                  ),

                ],
              )
            ),
          ),
          // Column(
          //   children: [
          //     SizedBox(height: 10,),
          //     Text(
          //       widget.song['TITLE'] ?? '',
          //       style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp),
          //       textAlign: TextAlign.center,
          //       maxLines: 1,
          //       overflow: TextOverflow.ellipsis,
          //     ),
          //     SizedBox(height: 5,),
          //     Text(
          //       widget.song['ARTIST'] ?? '', style: TextStyle(fontFamily: font, fontSize: 12.sp),
          //       maxLines: 1,
          //       overflow: TextOverflow.ellipsis,
          //     ),
          //     Text(
          //       widget.song['ALBUM'] ?? '', style: TextStyle(fontFamily: font, fontSize: 12.sp),
          //       maxLines: 1,
          //       overflow: TextOverflow.ellipsis,
          //     ),
          //     Text(widget.song['date'] ?? '', style: TextStyle(fontFamily: font, fontSize: 12.sp),),
          //     SizedBox(height: 20,),
          //     SizedBox(
          //       width: 80,
          //       height: 20,
          //       child: ElevatedButton(
          //         onPressed: () {
          //           Navigator.pop(context);
          //         },
          //         style: ElevatedButton.styleFrom(
          //           foregroundColor: Colors.grey,
          //           backgroundColor: Colors.white,
          //           // overlayColor: null
          //           // elevation: 0,
          //         ),
          //         child: Text(
          //           '닫기',
          //           style: TextStyle(
          //             fontSize: 9.sp
          //           ),
          //         ),
          //       ),
          //     ),
          //     SizedBox(height: 15,)
          //   ],
          // )
        ],
      ),
    );;
  }
}
