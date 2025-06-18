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
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: SizedBox(
                    height: mediaHeight * 0.6,
                    child: AspectRatio(
                    aspectRatio: 1,
                    child:
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: ExtendedImage.network(
                          widget.song['IMAGE'] ?? '',
                          fit: BoxFit.cover,

                          loadStateChanged: (state) {
                            switch (state.extendedImageLoadState) {
                              case LoadState.loading:
                              // 로딩 중일 때 보여줄 커스텀 위젯
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black
                                  ),
                                  alignment: Alignment.center,
                                  child: Text("로딩 중...", style: TextStyle(color: Colors.white, fontFamily: 'NotoSansKR-Regular',)),
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
                      ),
                    ),
                  ),
                ),
          if (imageLoaded)
            SizedBox(
              width: mediaWidth * 0.6,
              child: Text(
                widget.song['TITLE'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                ),
              ),
            ),

          if (imageLoaded)
            SizedBox(
              width: mediaWidth * 0.4,
              child: Text(
                widget.song['ARTIST'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ],
        )
      ),
    )
    );
  }
}
