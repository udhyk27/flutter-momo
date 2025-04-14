class ApiRecommend {
  final String image;
  final String title;
  final String artist;
  final String album;
  final String songId;
  final String issueDate;
  final String cnt;

  ApiRecommend({
    required this.image,
    required this.title,
    required this.artist,
    required this.album,
    required this.songId,
    required this.issueDate,
    required this.cnt,
  });

  factory ApiRecommend.fromJson(Map<String, dynamic> json) {
    return ApiRecommend(
      image: json['IMAGE'] ?? '',
      title: json['TITLE'] ?? '',
      artist: json['ARTIST'] ?? '',
      album: json['ALBUM'] ?? '',
      songId: json['SONG_ID'] ?? '',
      issueDate: json['ISSUE_DATE'] ?? '',
      cnt: json['CNT'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'IMAGE': image,
      'TITLE': title,
      'ARTIST': artist,
      'ALBUM': album,
      'SONG_ID': songId,
      'ISSUE_DATE': issueDate,
      'CNT': cnt,
    };
  }
}
