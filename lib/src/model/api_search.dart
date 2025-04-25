class ApiSearch {
  String image;
  String title;
  String artist;
  String album;
  String songId;
  String date;
  String genre;


  ApiSearch({
    required this.image,
    required this.title,
    required this.artist,
    required this.album,
    required this.songId,
    required this.date,
    required this.genre
  });

  Map<String, dynamic> toJson() {
    return {
      'IMAGE' : image,
      'TITLE' : title,
      'ARTIST' : artist,
      'ALBUM' : album,
      'SONG_ID' : songId,
      'date' : date,
      'GENRE' : genre
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
      genre: json['GENRE'] ?? ''
    );
  }

  @override
  String toString() {
    return 'ApiSearch(image: $image, title: $title, artist: $artist, album: $album, songId: $songId, date: $date, genre: $genre)';
  }

}

