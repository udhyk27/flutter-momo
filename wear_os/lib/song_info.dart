import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SongInfo extends StatefulWidget {

  // final List song;

  const SongInfo({
    super.key,
    // required this.song
  });

  @override
  State<SongInfo> createState() => _SongInfoState();
}

class _SongInfoState extends State<SongInfo> {

  String font = 'NotoSansKR-Regular';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: ListView(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ExtendedImage.network(
                  'https://adm.airmonitor.co.kr/resource_music/2019/064/KA0094064/KA0094064.jpg',
                  fit: BoxFit.cover,
                  loadStateChanged: (state) {
                    if (state.extendedImageLoadState == LoadState.failed) {
                      return SizedBox(
                        child: Image.asset('assets/no_image.png', fit: BoxFit.cover),
                      );
                    }
                    return null;
                  },
                ),
              ),
            ),
            Column(
              children: [
                SizedBox(height: 10,),
                Text(
                  'Home Sweet Home',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp),
                ),
                SizedBox(height: 5,),
                Text('카더가든', style: TextStyle(fontFamily: font, fontSize: 12.sp),),
                Text('APARTMENT', style: TextStyle(fontFamily: font, fontSize: 12.sp),),
                Text('2017.12.02', style: TextStyle(fontFamily: font, fontSize: 12.sp),),
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
      ),
    );;
  }
}
