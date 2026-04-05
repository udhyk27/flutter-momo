# Momo — 음악 인식 앱

> 주변 음악을 마이크로 녹음하고 서버에 전송해 곡을 실시간으로 찾아주는 Flutter 앱

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-FA7343?style=flat&logo=swift&logoColor=white)
![Kotlin](https://img.shields.io/badge/Kotlin-7F52FF?style=flat&logo=kotlin&logoColor=white)

<br>

## 기술 스택

| 분류 | 기술 |
|---|---|
| 프레임워크 | Flutter (Dart) |
| 상태 관리 | GetX · Provider |
| 오디오 | flutter_sound · FFI (Native C) |
| 네트워크 | http (Dart) · OkHttp (Kotlin) |
| 워치 연동 | WearOS Flutter · Apple WatchKit (Swift) |
| 블루투스 | RFCOMM Socket · MethodChannel |
| 플랫폼 | iOS · Android · Wear OS · watchOS |

<br>

## 아키텍처

```
[정상 경로]
Watch / Phone  →  POST /api/getdnasong  →  Server  →  곡 정보 JSON

[블루투스 환경]
Watch  →  BT RFCOMM  →  Phone  →  POST /api/getdnasong  →  Server
                                                              ↓
Watch  ←  BT RFCOMM  ←  Phone  ←────────────────────── 곡 정보 JSON
```

<br>

## 핵심 코드

### 오디오 녹음 & DNA 변환

iOS는 ~180ms 단위 대형 청크, Android는 ~20ms 단위 소형 청크로 수신
`fftHop * 2` 단위로 정규화해 `WaveBuf → DnaBuf` 파이프라인에 투입

```dart
_audioStream = recCtrl.stream.listen((buffer) async {
  if (Platform.isIOS && buffer.length > fftHop * 2) {
    int offset = 0;
    while (offset < buffer.length) {
      int chunkSize = min(fftHop * 2, buffer.length - offset);
      _wbuf.push(buffer.sublist(offset, offset + chunkSize));
      _processBuffer();
      offset += chunkSize;
    }
  } else {
    _wbuf.push(buffer);
    _processBuffer();
  }
});
```

### 서버 전송

32프레임 DNA 누적 후 base64 인코딩해 POST. 5초 타임아웃 초과 시 즉시 종료

```dart
Future<Map<String, dynamic>> sendDnaToServer(List<int> dna) async {
  final response = await http.post(
    Uri.parse(ApiService.serverUrl),
    headers: {'Content-Type': 'application/octet-stream'},
    body: jsonEncode({
      'uid'      : MyApp.uid,
      'req_times': num,
      'dna_data' : base64Encode(Uint8List.fromList(dna)),
    }),
  ).timeout(Duration(seconds: ApiService.sv_timeOut),
    onTimeout: () => http.Response(jsonEncode({'err_msg': 'TIME OUT'}), 408),
  );
  return jsonDecode(response.body);
}
```

### 네트워크 상태에 따른 전송 경로 분기

```dart
Future<void> _sendDnaToServerAndProcess() async {
  if (recController.networkType.value == 'bluetooth') {
    await _sendDataToKotlin(_dna.pack());
  } else {
    m = await sendDnaToServer(_dna.pack());
  }
}
```
