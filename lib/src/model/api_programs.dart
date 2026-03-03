class ApiPrograms {
  final String fSongId;
  final String fId;
  final String prId;
  final String fDate;
  final String fName;
  final String cDate;
  final String clId;
  final String fStart;
  final String fEnd;
  final String fProgIds;
  final String fLogo;
  final String fImage;
  final String clNm;
  final String fType;
  final String sTitle;
  final String sArtist;

  ApiPrograms({
    required this.fSongId,
    required this.fId,
    required this.prId,
    required this.fDate,
    required this.fName,
    required this.cDate,
    required this.clId,
    required this.fStart,
    required this.fEnd,
    required this.fProgIds,
    required this.fLogo,
    required this.fImage,
    required this.clNm,
    required this.fType,
    required this.sTitle,
    required this.sArtist,
  });

  factory ApiPrograms.fromJson(Map<String, dynamic> json) {
    return ApiPrograms(
      fSongId: json['F_SONG_ID'] as String,
      fId: json['F_ID'] as String,
      prId: json['PR_ID'] as String,
      fDate: json['F_DATE'] as String,
      fName: json['F_NAME'] as String,
      cDate: json['C_DATE'] as String,
      clId: json['CL_ID'] as String,
      fStart: json['F_START'] as String,
      fEnd: json['F_END'] as String,
      fProgIds: json['F_PROG_IDS'] as String,
      fLogo: json['F_LOGO'] as String,
      fImage: json['F_IMAGE'] as String,
      clNm: json['CL_NM'] as String,
      fType: json['F_TYPE'] as String,
      sTitle: json['S_TITLE'] as String,
      sArtist: json['S_ARTIST'] as String,
    );
  }

  factory ApiPrograms.empty() => ApiPrograms(
    fSongId: '-1',  // 더미 구분용
    fId: '',
    prId: '',
    fDate: '',
    fName: '',
    cDate: '',
    clId: '',
    fStart: '',
    fEnd: '',
    fProgIds: '',
    fLogo: '',
    fImage: '',
    clNm: '',
    fType: '',
    sTitle: '',
    sArtist: '',
  );

  // toJson method to convert ApiPrograms object to JSON
  Map<String, dynamic> toJson() {
    return {
      'F_SONG_ID': fSongId,
      'F_ID': fId,
      'PR_ID': prId,
      'F_DATE': fDate,
      'F_NAME': fName,
      'C_DATE': cDate,
      'CL_ID': clId,
      'F_START': fStart,
      'F_END': fEnd,
      'F_PROG_IDS': fProgIds,
      'F_LOGO': fLogo,
      'F_IMAGE': fImage,
      'CL_NM': clNm,
      'F_TYPE': fType,
      'S_TITLE': sTitle,
      'S_ARTIST': sArtist,
    };
  }
}
