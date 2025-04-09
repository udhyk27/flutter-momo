class ApiSearch {
  String image;
  String title;
  String artist;
  String album;
  String songId;
  String date;
  String schDate;
  int count;


  ApiSearch({
    required this.image,
    required this.title,
    required this.artist,
    required this.album,
    required this.songId,
    required this.date,
    required this.schDate,
    required this.count,
  });

  Map<String, dynamic> toJson() {
    return {
      'IMAGE' : image,
      'TITLE' : title,
      'ARTIST' : artist,
      'ALBUM' : album,
      'SONG_ID' : songId,
      'date' : date,
      'SCH_DATE' : schDate,
      'count' : count,
    };
  }

  factory ApiSearch.fromJson(Map<String, dynamic> json) {
    return ApiSearch(
      image: json['IMAGE'] ?? '',
      title: json['TITLE'] ?? '',
      artist: json['ARTIST'] ?? '',
      album: json['ALBUM'] ?? '',
      songId: json['SONG_ID'] ?? '',
      date: json['date'] ?? '',
      schDate: json['SCH_DATE'] ?? '',
      count: int.tryParse(json['count'].toString()) ?? 0,
    );
  }

}

