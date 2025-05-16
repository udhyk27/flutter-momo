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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(255, 224, 226, 1.0),
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: ExtendedImage.network(
                widget.song['IMAGE'] ?? '',
                fit: BoxFit.cover,

                loadStateChanged: (state) {

                  switch (state.extendedImageLoadState) {
                    case LoadState.loading:
                    // 로딩 중일 때 보여줄 커스텀 위젯
                      return Container(
                        color: const Color.fromRGBO(255, 195, 200, 1.0),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: MediaQuery.of(context).size.width * 0.6, child: Image.asset('assets/loading2_pink.gif', fit: BoxFit.contain,)),
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

              )
            ),
          ),
          Column(
            children: [
              SizedBox(height: 10,),
              Text(
                widget.song['TITLE'] ?? '',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 5,),
              Text(
                widget.song['ARTIST'] ?? '', style: TextStyle(fontFamily: font, fontSize: 12.sp),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                widget.song['ALBUM'] ?? '', style: TextStyle(fontFamily: font, fontSize: 12.sp),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(widget.song['date'] ?? '', style: TextStyle(fontFamily: font, fontSize: 12.sp),),
              SizedBox(height: 20,),
              SizedBox(
                width: 80,
                height: 20,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    backgroundColor: Colors.white,
                    // overlayColor: null
                    // elevation: 0,
                  ),
                  child: Text(
                    '닫기',
                    style: TextStyle(
                      fontSize: 9.sp
                    ),
                  ),
                ),
              ),
              SizedBox(height: 15,)
            ],
          )
        ],
      ),
    );;
  }
}
