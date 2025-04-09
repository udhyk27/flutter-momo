class DetailProgram {
  final String songId;
  final String id;
  final String programId;
  final String date;
  final String name;
  final String createdDate;
  final String channelId;
  final String startTime;
  final String endTime;
  final String logo;
  final String image;
  final String channelName;
  final String type;

  // 생성자
  DetailProgram({
    required this.songId,
    required this.id,
    required this.programId,
    required this.date,
    required this.name,
    required this.createdDate,
    required this.channelId,
    required this.startTime,
    required this.endTime,
    required this.logo,
    required this.image,
    required this.channelName,
    required this.type,
  });

  // JSON에서 객체로 변환하는 함수
  factory DetailProgram.fromJson(Map<String, dynamic> json) {
    return DetailProgram(
      songId: json['F_SONG_ID'],
      id: json['F_ID'],
      programId: json['PR_ID'],
      date: json['F_DATE'],
      name: json['F_NAME'],
      createdDate: json['C_DATE'],
      channelId: json['CL_ID'],
      startTime: json['F_START'],
      endTime: json['F_END'],
      logo: json['F_LOGO'],
      image: json['F_IMAGE'],
      channelName: json['CL_NM'],
      type: json['F_TYPE'],
    );
  }

  // 객체에서 JSON으로 변환하는 함수 (선택 사항)
  Map<String, dynamic> toJson() {
    return {
      'F_SONG_ID': songId,
      'F_ID': id,
      'PR_ID': programId,
      'F_DATE': date,
      'F_NAME': name,
      'C_DATE': createdDate,
      'CL_ID': channelId,
      'F_START': startTime,
      'F_END': endTime,
      'F_LOGO': logo,
      'F_IMAGE': image,
      'CL_NM': channelName,
      'F_TYPE': type,
    };
  }
}
