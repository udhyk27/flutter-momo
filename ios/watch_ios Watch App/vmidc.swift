import SwiftUI
import Foundation
import AVFoundation

class Vmidc: NSObject {
    private var audioEngine: AVAudioEngine?
    
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

    func start() {
        print(" VMIDC started")
        appState.isRecording = true
        
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        wbuf.clear()
        dna.clear()

        let inputNode = audioEngine.inputNode
        let format = inputNode.inputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            print("processBuffer 호출중임, frameLength: \(buffer.frameLength)")
//            self?.processBuffer(buffer)
            
            
            
            
            
        }

        do {
            try audioEngine.start()
            print("레코더 시작")
        } catch {
            print("Failed to start audio engine: \(error)")
            appState.isRecording = false
            return
        }
    }

    func stop() {
        print("VMIDC stopped")
        appState.isRecording = false
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil

        
        wbuf.clear()
        dna.clear()
        
        sendCount = 0
    }

    func processBuffer(_ buffer: AVAudioPCMBuffer) {
        print("[VMIDC] processBuffer 호출됨, frameLength: \(buffer.frameLength)")
        print("buffer.format: \(buffer.format)")

        guard let channelData = buffer.floatChannelData else {
            print("int16ChannelData와 floatChannelData 모두 없음")
            return
        }

        let frameLength = Int(buffer.frameLength)
        let channels = Int(buffer.format.channelCount)
        var bytes = [UInt8]()
        
        print("buffer.format: \(buffer.format)")
        
        let totalBytes = frameLength * channels * 2  // Int16 2바이트씩
        var offset = 0
        
        while offset < totalBytes {
            bytes.removeAll(keepingCapacity: true)
            
            let chunkByteSize = min(fftHop * channels * 2, totalBytes - offset)
            let chunkFrameCount = chunkByteSize / (channels * 2)
            
            let startFrame = offset / (channels * 2)
            let endFrame = startFrame + chunkFrameCount
            
            for frame in startFrame..<endFrame {
                for ch in 0..<channels {
                    let floatSample = channelData[ch][frame]
                    let clampedSample = max(-1.0, min(floatSample, 1.0))
                    let intSample = Int16(clampedSample * Float(Int16.max))
                    
                    let byte1 = UInt8(truncatingIfNeeded: intSample & 0xFF)
                    let byte2 = UInt8(truncatingIfNeeded: (intSample >> 8) & 0xFF)
                    bytes.append(byte1)
                    bytes.append(byte2)
                }
            }

            // wbuf에 청크 푸시
            let success = wbuf.push(bytes)
            if !success {
                print("WaveBuf 용량 부족으로 데이터 푸시 실패")
                return
            }
            print("WaveBuf에 푸시 성공, 현재 길이: \(wbuf.length)")
            print("bytes :::: \(bytes)")

            // 충분한 데이터가 쌓였으면 dna에 푸시
            while wbuf.length >= fftN * 2 {
                wbuf.read(fftN * 2, to: pcm)
                dna.push(pcm: pcm)
                print("dna length: \(dna.length), qLen: \(qLen)")
                wbuf.pop(fftHop * 2)
                
                if dna.length == qLen {
                    let now = Date()
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm:ss.SSS"
                    let timeString = formatter.string(from: now)
                    print("[\(timeString)] 32개의 DNA 쌓임, 서버로 전송 !!")
                    
                    Task {
                        print("sendDnaToServerAndProcess 시작")
                        await sendDnaToServerAndProcess()
                        print("sendDnaToServerAndProcess 종료")
                    }
                }
            }
            
            offset += chunkByteSize
        }
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
        
//        print(base64String)
        print("byte ::: \(data.count)")

        
//        
//        if let decodedData = Data(base64Encoded: base64String) {
//            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//            let fileURL = documents.appendingPathComponent("recorded.wav")
//            do {
//                try decodedData.write(to: fileURL)
//                print("오디오 저장 위치: \(fileURL)")
//            } catch {
//                print("파일 저장 실패: \(error)")
//            }
//        } else {
//            print("base64 디코딩 실패")
//        }
        
//        let base64String = "MkTdGkMw7OOmzMENQ2F8w2LMxxlP8txDdaznGUZyZeMR6sQ4cS7FcxuoyWURzs/jH6jLRikdfcc56EmHVK6xkzfAS6kwp+djG4RvuEiOldObzGGpSIqcD2uEybFzrhjre8TRoVSutFof8BI2V47S0jrl9ZRIhp3DP9phdkynrZk/GtN3TgavwSwa82RItu/ISZTDrFimP9nrhNOuGIxvDjYY0+4crp9ZBj7T7pisNpnfOkvuGKwlkTOkzSy0DSWTH6jJZHCha5Mz5MswWL6cnzrozKgWNpwfM1bSqtWIMpMilvGLRY7KzyvwyZNGj/lKN7bGiFaOzco/l2umWO3Ni2e0AptibFc2pyS6mnN9MwlWc0saax0WNF9MfMgjtDBIVWEMeuh5UrQfPHiYnfnjAjRhp5sySpIkkzJpbCz2oyFnbmaOs1jWrUdXpIxUUKEuImbUsM04FzWnJ2LMxrRRPMPEOpGnSROp10NB1MXYnjgYqlqMK0vTjOcZSKmTuE11bYc2qlvP07y/jqL4RjlzVMI5ZoIYMxIzzTYwqzQ6M2fGOU4yWLMzMYuycHQpOiNnGiluRsJT75bmNLiSJJHIZHQzamY5Qsqchza68CzTMS1bNk3SRnOKOtsrIWO0VSwl5jiW2HLplrDPhjPpOTeZM5ohP1Ji0tK7nwdkdSscihb1ITo2V1JS7OVX3IJFmQkV0Ck6im5a8jD11s2DjlkJP9UlOdZ9L/JhpjSYo5d4LSvcI3PC9kreINdsmKmnWWpj4CNclEzZyzBfi6ophbl8euDjcO48x5u5daK8p555bF7Js3iIMc6TiV1rzq5nXHx1k47SknIuQ5EXS3bGdjVxKyApkkLWHJazl0tD2GdwEi3FMWZifFLb8ZcGIJVFvaAImSI+UvBC35CPDdG+dHNjZZP23MhMEtuodw6dklZ5ZiZSNm7AzkpbsicEmtIp7axhdjdNUMtK5pjbjhqX5NRtbVYnVWLjUua6t240ydo8S1FIO1ZoS3nHtn+OnUvJPkxX"
        
//        let base64String = "r7oPfCSZHE6OvZ59dMjc3q5+D3womBxOj78ffXTI3F6J6Z4+ZNpc5s+/H350mVxaiemePGTKTPbLuh98ZJkcXojtnj10yEzW774PfGSZHE6OvZ59dMjc3q9+D3womBxux78ff3SIXF7j555+PMxQLcdvHuf0bJZlU3WepF3IJDbGeZ+2PM+JZpZ9v7JU7kx0xzQ/8lTOTj3HNJ/HUildehZ+jm/NCFgwV25fLsoqHb3j/l8lb668tNZv38d6Jb1/xm6f7hwx0Wyzzn/vWpJ6M0KOv9s27VFXQ/sOvXzOtc5Xb1+z1KoY9Yf3HqvmqlGp4+5ek2yL5XnD7x9jTxWldmGepaH8Ed8YW+3m3f1M8lwzP6phrLhauVvFU275wSkPYZ6k4+wRUhhb7PaV/Az0WBM3ouG8KV6ZX8XSb/lBqh9zOOxz7FEev1PFa2r+yTwPUbai4fw53plfxfbv/Um6HjI7bHlsmB67U8VrbnrZaA9RnqXh/DHeGU/t5t39TfIcMjvqcayYWrlTxXNuetFoD2GepaH8Ed4YS+3m3fxM8lwzP6phrLhauVvFU275wSkPYZ6k4+wRUhhb7PaV/Az0WBM2ouH4OV6ZH9Xab3lBuh+wjZJwMptwjq5uf578c71eaX1yOLbJOB9faHY2/cmebFl59nQ2616vDRszH87NGE+ZLOb49koaFx5oWxLtzVhnETVtstJIkw6eYXmZfVXMVxB37nD2lDmTPno1j3VWrXrctmaKeZnIEz1iNA/9xt98s23WSOUZmQ9fUe6p/FQ7DMxxxFxxiXmHPnb9NvtQ7ixyXIps6UiaZh59aJ+92jks3bRynZnCWgo/aSc3+9GvKJ1XN1eTWnmtXGjtmPfTLC/uWobr3JoSN46MvPH9XWs6LY9y3JMcGzvPYubk2dPlOlg97JmTTro0TXnLb3SMa2e16ebOQNMbJx5SV959m6ZWbZnMzCAzeqYfadr9fFEmRkmSiYwpSrI9TmxzPrSZpmnSOJuZcmo+D49Yeav0S6ca"
        
        
        // JSON에 넣을 데이터 구성
        let arr: [String: Any] = [
            "uid": uuid,
            "req_times": sendCount, // 서버에 보내는 요청 횟수, 변수로 선언해 주세요
            "dna_data": base64String
        ]

        var request = URLRequest(url: URL(string: "https://www.mo-mo.co.kr/tpi/getdnasong")!)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        
        print("서버로 보낼 값 :::: \(base64String)")
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
