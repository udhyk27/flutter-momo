import SwiftUI
import Foundation
import AVFoundation
import AVFoundation

class Vmidc: ObservableObject {
    private var audioEngine: AVAudioEngine?
    
    @Published var foundSongData: [String: String]? = nil

    
    let wbuf = WaveBuf()
    let dna = DnaBuf()

    let srate = 16000
    let fftN = 2048
    let fftHop = 1000
    let qLen = 32
    
    func getDeviceUUID() -> String {
        let defaults = UserDefaults.standard
        if let uuid = defaults.string(forKey: "deviceUUID") {
            print("uuid : \(uuid)")
            return uuid
        } else {
            let newUUID = UUID().uuidString
            defaults.set(newUUID, forKey: "deviceUUID")
            return newUUID
        }

        // TEST
//        return "AP3A.250530.001.A1"

    }

    
    private var sendCount = 0
    private let maxSendCount = 5
    
    
    lazy var pcm: UnsafeMutablePointer<UInt8> = {
        UnsafeMutablePointer<UInt8>.allocate(capacity: fftN * 2)
    }()
    
    private var appState = AppState.shared
    
    func openSession() {
        if appState.isRecording { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .default, options: [])
            try session.setActive(true)
            print("오디오 세션 오픈 완료 !!")
        } catch {
            print("오디오 세션 오픈 실패: \(error)")
        }
    }
    
    func closeSession() {
        if !appState.isRecording { return }
        
        do {
           try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        
           pcm.deallocate()  // 메모리 해제
            
           print("오디오 세션 닫기 완료 @@")
       } catch {
           print("오디오 세션 닫기 실패: \(error)")
       }
    }
    
    func checkPermission() {
        let session = AVAudioSession.sharedInstance()
           
           switch session.recordPermission {
           case .undetermined:
               // 권한 요청
               session.requestRecordPermission { [weak self] granted in
                   DispatchQueue.main.async {
                       if granted {
                           print("마이크 권한 허용됨")
                           self?.start()
                       } else {
                           print("마이크 권한 거부됨")
                           // 필요 시 사용자에게 권한 설정 안내 가능
                       }
                   }
               }
               
           case .denied:
               print("마이크 권한 거부됨")
               // 필요 시 권한 설정으로 유도하는 UI 안내 가능
               
           case .granted:
               print("마이크 권한 이미 허용됨")
               start()
               
           @unknown default:
               print("알 수 없는 권한 상태")
           }
    }
    
    var isSendingDna = false // 클래스 프로퍼티로 선언
    
    func start() {
        print("VMIDC started")
        appState.isRecording = true
        
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        wbuf.clear()
        dna.clear()
        
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        
        // 원하는 출력 포맷: 16000Hz mono, 16-bit float
        let desiredSampleRate: Double = 16000
        let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                         sampleRate: desiredSampleRate,
                                         channels: 1,
                                         interleaved: false)!

        guard let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
            print("Converter 생성 실패")
            return
        }
        
        print("Sample rate: \(inputFormat.sampleRate)") // 48000
        print("Output Sample rate: \(outputFormat.sampleRate)") // 16000 (출력)
        
        
        inputNode.installTap(onBus: 0, bufferSize: 2048, format: inputFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            
            // 출력 버퍼 준비 (16000Hz 변환용)
            guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat,
                                                         frameCapacity: AVAudioFrameCount(Double(buffer.frameLength) * desiredSampleRate / inputFormat.sampleRate)) else {
                return
            }

            var error: NSError?
            let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }

            converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputBlock)

            if let error = error {
                print("변환 실패: \(error)")
                return
            }

            let inputFrames = buffer.frameLength
            let outputFrames = convertedBuffer.frameLength
            
            print("입력 프레임 수: \(inputFrames), 변환된 프레임 수: \(outputFrames)")
            print("변환된 샘플레이트: \(convertedBuffer.format.sampleRate)")
            
            print("변환된 frameLength: \(convertedBuffer.frameLength)")
            
            if let int16Samples = self.float32ToInt16(buffer: convertedBuffer) {
                let byteData = self.int16ArrayToBytes(int16Samples)

                print("전체 byteData 길이: \(byteData.count)")

                var offset = 0
                let chunkSize = self.fftHop * 2  // Int16 -> 2 bytes

                while offset < byteData.count {
                    let end = min(offset + chunkSize, byteData.count)
                    let chunk = Array(byteData[offset..<end])

                    let success = self.wbuf.push(chunk)
                    if success {
                        print("청크 wbuf에 push 완료 (길이: \(chunk.count), wbuf 총 길이: \(self.wbuf.length))")
                    } else {
                        print("청크 wbuf push 실패")
                    }
                    
                    print("변환된 Int16 샘플 수: \(int16Samples.count)")
                    let minSample = int16Samples.min() ?? 0
                    let maxSample = int16Samples.max() ?? 0
                    print("Int16 값 범위: \(minSample) ~ \(maxSample)")
                    
                    // 처리 루틴 (wbuf → dna)
                    while self.wbuf.length >= self.fftN * 2 {
                        self.wbuf.read(self.fftN * 2, to: self.pcm)
                        self.dna.push(pcm: self.pcm)
                        print("DNA length: \(self.dna.length)")

                        self.wbuf.pop(self.fftHop * 2)

                        if self.dna.length == self.qLen && !self.isSendingDna {
                            self.isSendingDna = true
                            
                            let now = Date()
                            let formatter = DateFormatter()
                            formatter.dateFormat = "HH:mm:ss.SSS"
                            let timeString = formatter.string(from: now)
                            print("[\(timeString)] 32개의 DNA 쌓임, 서버로 전송 !!")
                            
                            
                            Task {
                                await self.sendDnaToServerAndProcess()
                                self.isSendingDna = false
                            }
                        }
                    }

                    offset += chunkSize
                }
            }
        }

        
        do {
            try audioEngine.start()
            print("레코더 시작")
        } catch {
            print("Failed to start audio engine: \(error)")
            appState.isRecording = false
        }
    }

    
    
    
    func float32ToInt16(buffer: AVAudioPCMBuffer) -> [Int16]? {
        guard let floatChannelData = buffer.floatChannelData else {
            print("floatChannelData가 없음")
            return nil
        }
        
        let frameLength = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)
        
        var int16Array = [Int16]()
        int16Array.reserveCapacity(frameLength * channelCount)
        
        for ch in 0..<channelCount {
            let floatData = floatChannelData[ch]
            for i in 0..<frameLength {
                // Float32 샘플값을 -1.0 ~ 1.0 범위로 가정
                let sample = floatData[i]
                // 클램핑: -1.0~1.0 벗어나면 자르기
                let clampedSample = max(-1.0, min(1.0, sample))
                // Float -> Int16 변환 (-32768 ~ 32767 범위)
                let int16Sample = Int16(clampedSample * Float(Int16.max))
                int16Array.append(int16Sample)
            }
        }
        
        return int16Array
    }
    
    func int16ArrayToBytes(_ samples: [Int16]) -> [UInt8] {
        var bytes = [UInt8]()
        for sample in samples {
            let byte1 = UInt8(truncatingIfNeeded: sample & 0xFF)
            let byte2 = UInt8(truncatingIfNeeded: (sample >> 8) & 0xFF)
            
            bytes.append(byte1)
            bytes.append(byte2)
            
        }
        return bytes
    }
    

    func stop() {
        print("VMIDC stopped")
        DispatchQueue.main.async {
            self.appState.isRecording = false
        }
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil

        
        wbuf.clear()
        dna.clear()
        
        sendCount = 0
    }


    // dna.pack()이 Data 타입 반환한다고 가정
    func sendDnaToServerAndProcess() async {
        
        let uuid = getDeviceUUID()
        
        if sendCount >= maxSendCount {
              print("최대 전송 횟수 도달, 전송 중단")
              self.stop()
              return
        }
        sendCount += 1
        print("sendCount: \(sendCount)")
        
        let byteArray = dna.pack()   // [UInt8]
        let data = Data(byteArray)   // Data 타입 변환
        let base64String = data.base64EncodedString()  // base64 인코딩 문자열 변환
//        let base64String = "l/H/zgwPs0u36HW1Uo50X7fYe5IgjXNdn7/1LCudd1s+9+WlQJtJeT7/6x1Vq9NMP/37LFGtsma/Xb946dp4St6evaLEJ+c6p2+NqlI3d0M6tpsLIe32Qt/990cp0zZ7N+o7Jla6s3t/c/OKVKs+bfv+72V1LTZ7XvPtnkQ5Mmle8+WiEHsza531+askWTNrzfiePmwdu2MfSK+2cBk/fmVE9yn0uNlv77Y+ynSsuH638X3LSY2/TF/z7Z4QerJf5qRnshBtMxvO+PjlqIy4HT9jNs6DSflKX/PtvhB5u1K+87siliube/+S5S4VKDl/v7ueHMCPfC8/++6OQsmMfeiU2d2uy2YYvMfJJV1/dGoUU9pZJBvTGD7HSOQZn8gmkIzzZS5b8xk8xWi5ZV8nZUpMs0m218I829f3a1pLagwQGAbzSxqzH1sfX+cx3zxLG5vNZs9xsjF7R333pfokKVOy8szMSpoe6xVz7cV/awVCysS56FmmHnyP2Rr7xTITcPAaDl5Zxhe/4XZnemtmZxhblskYXU4dPM1fnXPSZGZTTNN9HG2SFOmSOEfuo8QC04zacZwv5463u/l6rauWMjQjyEcLR0sePB7e3MVOzUxksc1EtlpajnaaTi/H5q5IE52yLLZLrR7ve2p2r66UGjIZ0h+vS0sdbyGnlnhm7WMmUuYcp0PDHG4zrvdaLaUndgzKmaUXQz5zlVRq6bNmJNmaktHJZlsU4XjC/t1hrSMmteLS/gnSDeln4rmapIxjNL1MyuVZ0x43fjg5M8+gEjAvqabIZLML5e4079yN7njCOOOJrkP6CB7PybtVn6ZKJmJWHaZD+hhvMS63WiStIzTXthyuU/MJn/Y43TucpmPIzKrJVGf7CV1wlbdM2zg+DWDTGeJ81By7Zw4cFmc6ejZi5xrHY5YxbyMvtlIttSdc69yc7kNTG9fKLWtH5k4uM6bKjOlL2xr3yx3JMatyTVZc2mDVVlcPuaee5m5z6WBMseJhcMo4F70nrap6bdtk"
        
//        let base64String = "b4cqJRuz5RPvgygtivH0I/lfHO4YY3QLeY9ybBvjcgv5rkrciXHkGW4XGu3Oae0b59Narna0rRlhO85e8/acI306QmPGvMlJZZcmn53RyANiloaSScPkSas/DKeN65gN7x6kthHT3A/tMZaeZ9u1EWsVgZ6b49gNbqKSnjaheRVNqlmMZrBmEfk/j5PZyPwL/0MOr5eP9AWrLzub0C3VGisjuqbEqLlPY4ueJsY4x1lzD0+Z1yjcCX3OSsvOIX0LaS6XHu+ttR1hJjOjwuzkG6olM8O0/dVJ62M34vab4Qn8Gq9v57BlJnqerk+xsf0Xava4unQg7RetbUVMnjGnGccWSst5Sssi6JyaZGbMNSbMjJu+MWtSBvfsjtXMxDks0IdHM7JaTQr2vl2xuVMte84HXmpES/O45iZLto4IeUzHgJMVKH37BVWtfUbMNPBZ+eTRnDH2ygRdPZ0z5IFpXBx6GPd1zcsELJ5Vcc45K20bZRrbaFNPjKS+JkVube8ZHHBwR3O51YyxmkwEDhCXXHOpZ3vjWtagIR43YRxEk2nTLGdysl77mCcsPWkyd09pYahmNubD2BivzN8meYIfRUOnDrOx8bKU1+zeEjN2nmdmqt7zaTYbEfHt0atea65xqsMHbdLZsQTEPDMzC0n7IJiWaevBHNMA3HUuZhJpbmWyPJJGFp3LpPUlrEKbXTlpZ8JgaHj705Lhrp0NemSycXTHb0Aw3ZmoZ/9NMX9RPU5Ut3Gam3O9pM1OuQ7ml+9omOxgjmPXOzzsjA0shkePZhR4SCa3ONcYpj7NxNZhn2ZZ5EKO0NlSIAY12QrtkNNhluUDTtIV2zB2Jt7wzJDnKP6oUfMiVvIMtjZqJpZR7QsubFC4clrjFCZ+Nko3F29qdM1pkbI5czTOzDmMhqcNeLbqplNJ1zWlaLhNHjfDbnU/6XCrWbqepWhabAF7x80MB8wJ63k/2SHkHuxDZp6zNFg2Rs5kaxuBx5g928RmzmPJpyOSuWqzFHDKORxXmNgI"
        
        print("DNA pack 길이: \(byteArray.count)")
        print("앞쪽 바이트 샘플: \(byteArray[0..<10])")
        
        
        print("byte ::: \(data.count)")

        
        // JSON에 넣을 데이터 구성
        let arr: [String: Any] = [
            "uid": uuid,
            "req_times": sendCount,
            "dna_data": base64String
        ]

        var request = URLRequest(url: URL(string: "https://www.mo-mo.co.kr/tpi/getdnasong")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("서버로 보낼 값 :::: \(arr)")
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let timeString = formatter.string(from: now)
        print("[\(timeString)] 서버로 보낼 값 타이머")

        do { // 서버로 전송
            request.httpBody = try JSONSerialization.data(withJSONObject: arr)
            
            
            dna.clear()
            print("clear 후 dna.length:", dna.length)
            
            
            
        } catch {
            print("JSON 변환 에러: \(error)")
            return
        }

        do {
            let (responseData, _) = try await URLSession.shared.data(for: request)
            
//            dna.clear()
//            print("clear 후 dna.length:", dna.length)
            
            if let jsonString = String(data: responseData, encoding: .utf8) {
                print("서버 응답 원문:\n\(jsonString)")
                
                // JSON 파싱해서 err_msg 존재 확인
                  if let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any] {
                      if let errMsg = json["err_msg"] as? String, !errMsg.isEmpty {
                          
                          print("서버 에러 메시지 감지: \(errMsg), 녹음 중단")
                          DispatchQueue.main.async {
                              self.stop()
                          }
                      }
                      
                      // 곡 찾았을 때
                      if let data = json["data"] as? [String: String], !data.isEmpty {
                          print("곡 찾음 !!")
                          DispatchQueue.main.async {
                              self.stop()
                              self.foundSongData = data
                          }
                          
                          
                      }
                      
                  }
            }
        
//            let result = try JSONDecoder().decode(SongResult.self, from: responseData)
//            print("서버에서 돌려받은 값 : \(result)")

        } catch {
            print("Server or decoding error: \(error)")
        }
    }

}

// 서버 응답 데이터 모델
//struct SongResult: Codable {
//    let ret: String
//    let data: String
//}
