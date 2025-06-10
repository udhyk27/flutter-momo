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
    // Color.fromRGBO(62, 195, 255, 1.0), // 위쪽 색
    // Color.fromRGBO(194, 40, 222, 1.0), // 아래쪽 색
    Color.fromRGBO(0, 0, 0, 1.0),
    Color.fromRGBO(158, 158, 158, 1.0)
  ];

  bool showIcon = false;
  bool imageLoaded = false;

  @override
  Widget build(BuildContext context) {

  var mediaWidth = MediaQuery.of(context).size.width;
  var mediaHeight =  MediaQuery.of(context).size.height;

    return GestureDetector(
      behavior: HitTestBehavior.opaque, // 전체 화면 터치 감지
      onTap: () {
        setState(() {
          showIcon = !showIcon;
        });
      },
      child: Scaffold(
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
                                  // SizedBox(width: mediaWidth * 0.6, child: Image.asset('assets/loading2_blue.gif', fit: BoxFit.contain,)),
                                  Text("로딩 중...", style: TextStyle(color: Colors.white, fontFamily: 'NotoSansKR-Regular',)),
                                ],
                              ),
                            );

                          case LoadState.completed:
                            if (!imageLoaded) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    imageLoaded = true;
                                  });
                                }
                              });
                            }
                            return null; // 기본 이미지 렌더링

                          case LoadState.failed:
                            return Image.asset('assets/no_image.png', fit: BoxFit.cover);
                        }
                      },
                    ),
                    if (imageLoaded)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: mediaHeight * 0.5, // 원하는 높이만큼
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

                    if (imageLoaded)
                      Positioned( // 글씨
                        left: 0,
                        right: 0,
                        bottom: 30,
                        child: Center(
                          child: Container(
                            width: mediaWidth * 0.8,
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
                                    fontSize: 16.sp,
                                  ),
                                ),
                                Text(
                                  widget.song['ARTIST'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12.sp,
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
                        ),
                      ),


                    if (showIcon)
                      Positioned(
                        top: mediaHeight / 2  - mediaHeight / 4 - 30,
                        right: mediaWidth / 2 - 15,
                        child: Container(
                          width: 30,
                          decoration: BoxDecoration(
                            color: Colors.white60,
                            shape: BoxShape.circle
                          ),
                          child: IconButton(
                            padding: EdgeInsets.all(2),
                            constraints: BoxConstraints(),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: Icon(
                              Icons.close_rounded,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              ),
            ),
          ],
        ),
      ),
    );;
  }
}
