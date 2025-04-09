class ApiRecommend {
  final String image;
  final String title;
  final String artist;
  final String album;
  final String songId;
  final String date;
  final String schDate;
  final String count;

  ApiRecommend({
    required this.image,
    required this.title,
    required this.artist,
    required this.album,
    required this.songId,
    required this.date,
    required this.schDate,
    required this.count,
  });

  factory ApiRecommend.fromJson(Map<String, dynamic> json) {
    return ApiRecommend(
      image: json['IMAGE'] ?? '',
      title: json['TITLE'] ?? '',
      artist: json['ARTIST'] ?? '',
      album: json['ALBUM'] ?? '',
      songId: json['SONG_ID'] ?? '',
      date: json['date'] ?? '',
      schDate: json['SCH_DATE'] ?? '',
      count: json['count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'IMAGE': image,
      'TITLE': title,
      'ARTIST': artist,
      'ALBUM': album,
      'SONG_ID': songId,
      'date': date,
      'SCH_DATE': schDate,
      'count': count,
    };
  }
}
