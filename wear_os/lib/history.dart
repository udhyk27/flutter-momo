import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class History extends StatelessWidget {
  History({super.key});

  final List<Map<String, String>> historyList = [
    {
      'image': 'https://adm.airmonitor.co.kr/resource_music/2019/064/KA0094064/KA0094064.jpg',
      'title': '곡제목 1',
      'artist': '가수명 1',
    },
    {
      'image': 'https://adm.airmonitor.co.kr/resource_music/2019/064/KA0094064/KA0094064.jpg',
      'title': '곡제목 2',
      'artist': '가수명 2',
    },
    {
      'image': 'https://adm.airmonitor.co.kr/resource_music/2019/064/KA0094064/KA0094064.jpg',
      'title': '곡제목 3',
      'artist': '가수명 3',
    },
    {
      'image': 'https://adm.airmonitor.co.kr/resource_music/2019/064/KA0094064/KA0094064.jpg',
      'title': '곡제목 4',
      'artist': '가수명 4',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(deviceWidth * 0.15),
        child: AppBar(
          backgroundColor: const Color.fromRGBO(255, 195, 200, 1.0),
          title:
            Center(
              child: Text(
                        '검색목록',
                        style: TextStyle(fontSize: 15.sp,),
                      )
            ),
        ),
      ),

      backgroundColor: const Color.fromRGBO(255, 195, 200, 1.0),
      body: ListView.builder(
        itemCount: historyList.length,
        itemBuilder: (context, index) {
          final item = historyList[index];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: ExtendedImage.network(
                    width: deviceWidth * 0.2,
                    item['image'] ?? '',
                    fit: BoxFit.cover,
                    loadStateChanged: (state) {
                      if (state.extendedImageLoadState == LoadState.failed) {
                        return Image.asset('assets/no_image.png', fit: BoxFit.cover);
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 10.0),
                // 텍스트
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] ?? '제목',
                      style: TextStyle(fontSize: 12.sp),
                    ),
                    Text(
                      item['artist'] ?? '가수명',
                      style: TextStyle(fontSize: 10.sp),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),


    );
  }
}
