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
    
    lazy var pcm: UnsafeMutablePointer<UInt8> = {
        UnsafeMutablePointer<UInt8>.allocate(capacity: fftN * 2)
    }()
    
    private var appState = AppState.shared
    
    func openSession() { // 
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
           print("오디오 세션 닫기 완료 @@")
       } catch {
           print("오디오 세션 닫기 실패: \(error)")
       }
    }

    func start() {
        print(" VMIDC started")
        appState.isRecording = true
        
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }

        let inputNode = audioEngine.inputNode
        let format = inputNode.inputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            print("processBuffer 호출중임, frameLength: \(buffer.frameLength)")
            self?.processBuffer(buffer)
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
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        print("VMIDC stopped")
        pcm.deallocate()  // 메모리 해제
    }

    func processBuffer(_ buffer: AVAudioPCMBuffer) {
        print("processBuffer 호출됨 !!")
        // 1. AVAudioPCMBuffer -> [UInt8] 변환
        print("buffer.format: \(buffer.format)")
        
        if let channelData = buffer.int16ChannelData {
            print("int16ChannelData 존재")
            // int16 변환 로직 (아마 호출 안될 것임)
        } else if let channelData = buffer.floatChannelData {
            print("floatChannelData 존재 - 변환 시작")
            let frameLength = Int(buffer.frameLength)
            let channels = Int(buffer.format.channelCount)
            var bytes = [UInt8]()
            
            for frame in 0..<frameLength {
                for ch in 0..<channels {
                    let floatSample = channelData[ch][frame]
                    // -1.0 ~ 1.0 범위의 float을 Int16로 변환
                    let intSample = Int16(max(min(floatSample, 1.0), -1.0) * Float(Int16.max))
                    let byte1 = UInt8(truncatingIfNeeded: intSample & 0xFF)
                    let byte2 = UInt8(truncatingIfNeeded: (intSample >> 8) & 0xFF)
                    bytes.append(byte1)
                    bytes.append(byte2)
                }
            }
            print("변환된 바이트 수 (float->int16): \(bytes.count)")
            
            let success = wbuf.push(bytes)
            if !success {
                print("WaveBuf 용량 부족으로 데이터 푸시 실패")
                return
            }
            print("WaveBuf에 푸시 성공, 현재 길이: \(wbuf.length)")
            
            if wbuf.length >= fftN * 2 {
                wbuf.read(fftN * 2, to: pcm)
                dna.push(pcm: pcm)
                wbuf.pop(fftHop * 2)
                
                if dna.length == qLen {
                    print("32개의 DNA 쌓임, 서버로 전송 !!")
                    Task {
                        await sendDnaToServerAndProcess()
                    }
                }
            }
        } else {
            print("int16ChannelData와 floatChannelData 모두 없음")
        }
    
    }


    // dna.pack()이 Data 타입 반환한다고 가정
    func sendDnaToServerAndProcess() async {
        let byteArray = dna.pack()   // [UInt8]
        let data = Data(byteArray)   // Data 타입 변환
        let base64String = data.base64EncodedString()  // base64 인코딩 문자열 변환

        // JSON에 넣을 데이터 구성
        let arr: [String: Any] = [
            "uid": "applewatch",          // MyApp.uid와 같은 값, 적절히 가져오기
            "req_times": 5,               // 서버에 보내는 요청 횟수, 변수로 선언해 주세요
            "dna_data": base64String
        ]

        var request = URLRequest(url: URL(string: "https://www.mo-mo.co.kr/api/getdnasong")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("서버로 보낼 값 :::: \(base64String)")

        do { // 서버로 전송
            request.httpBody = try JSONSerialization.data(withJSONObject: arr)
        } catch {
            print("JSON 변환 에러: \(error)")
            return
        }

        do {
            let (responseData, _) = try await URLSession.shared.data(for: request)
            let result = try JSONDecoder().decode(SongResult.self, from: responseData)
            print("서버에서 돌려받은 값 : \(result.title) - \(result.artist)")
        } catch {
            print("Server or decoding error: \(error)")
        }
    }

}

// 서버 응답 데이터 모델
struct SongResult: Codable {
    let title: String
    let artist: String
    let album: String
}
