class ApiMmChart {
  final String cnt;
  final String songId;
  final String artist;
  final String title;
  final String album;
  final String date;
  final String image;

  ApiMmChart({
    required this.cnt,
    required this.songId,
    required this.artist,
    required this.title,
    required this.album,
    required this.date,
    required this.image,
  });

  // JSON 데이터를 ApiMmChart 객체로 변환하는 함수
  factory ApiMmChart.fromJson(Map<String, dynamic> json) {
    return ApiMmChart(
      cnt: json['cnt'] ?? '0', // cnt 값이 null이면 '0'으로 처리
      songId: json['song_id'] ?? '',
      artist: json['artist'] ?? '',
      title: json['title'] ?? '',
      album: json['album'] ?? '',
      date: json['date'] ?? '',
      image: json['image'] ?? '',
    );
  }

  // ApiMmChart 객체를 JSON 데이터로 변환하는 함수
  Map<String, dynamic> toJson() {
    return {
      'cnt': cnt,
      'song_id': songId,
      'artist': artist,
      'title': title,
      'album': album,
      'date': date,
      'image': image,
    };
  }
}
