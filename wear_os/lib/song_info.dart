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
                Text(
                  'Home Sweet Home',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp),
                ),
                Text('카더가든'),
                Text('APARTMENT'),
                Text('2017.12.02'),
                SizedBox(height: 10,),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    '닫기',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                SizedBox(height: 10,)
              ],
            )
          ],
        ),
      ),
    );;
  }
}
