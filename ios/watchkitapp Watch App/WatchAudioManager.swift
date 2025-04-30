import Foundation
import WatchConnectivity
import AVFoundation

// 테스트용

class WatchAudioManager: NSObject, WCSessionDelegate, ObservableObject {
    private var contentView = ContentView()
    
    @Published var isRecognizing = false
    @Published var navigateToSongInfo = false
    
    private var audioEngine: AVAudioEngine!
    private var audioBuffer: Data = Data()  // 수집된 오디오 데이터를 담을 변수
    private let bufferSize: Int = 768  // 전달할 크기 (768바이트)
    private var sessionActivated = false
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // 테스트용 바이너리 데이터 보내기
    func sendTestAudioData() {
        // 임의의 768 바이트 데이터 생성 (예: 'a'로 채운 데이터)
//        let test1 = "ZGOOwxe/1f9dpeFRP3jpy1/+0+EefLXJH2ax1D1c6csXxvVkPXKY3xfH8ewddK3JD8fxbDx26eVP53Fsfrra58bHYWR+dKlOZ0dxyT/y2M2nx3NsffKaSe7Fcew+fNFNs5VxHjV16Uv30HEePdShSbdhYR41dK3bJ4LyXDF2i1s3ZvQfUeTsw7dBs7ZVJq1Ht0Y0R8G0hFN3FLrt1Tb2WzMB8aZnNs/NPwUitnNoV0u3YHLtW6TlS7Nk8+xWunFjd0Fg6tjQ0Nm/SGnKVnnL27cJMu3XUcNu92Bw6aNgU2fWyvP41rGzyWbgkPufWrPbzsQo0IdM81mDzOTQ3tz601eB4ptsW1O9ORwPHn7AB3i2J8uZY9pjuPszUc0DdItZ0iabmTvH65yeK1mZB+WqdPNtM5ljm7OQfgGangdnODFyy2Yz50mWlL5JmpgT8xgW0qeZmWNO0rg3Q1vdob04EnIfOjNn2pKs/xgf+YN6PB9VH253ZrNSlP8YmdwBOzg22iabmWPL3Ji/2F+YCT88W25PmDtnXbucX9gamYmeJT1zHy57ZtJjnD/IllkFOyQd9iaynUvaW5h/7Bn5AB0se3cLszlnym24r2QblTPTnBB3LTA5I8pymD9sSvUgk4wQNyaamWPKwog/zUCdIZucFCfbOlrmStKYXwxKkwjdrBRnN7nRZMuSuDdPGzM024wUZDKeVmnGk5ifxRmZhUecMmYzuku6yJaYP2cZkTjXLRF2tixPJkvDmA9vIbNt1y0zNRqZjUlaM/gPLyOl2XesVssaVl0q02I4J48xAlVWjirLOj2MKVsylD/PVRUPXbMyzGpmy0o3m5Yv32AcjzYzdshzCOlF01OZrz8loFU3Jmwwsim1avjJmJ/vZBKnXOY4KqqZMU55dra/z1EUDda7ci/OSDkvyz2UL68UpoBfWzYekkBrBOvxmi9rpuiF3aA3komIMYbD55R/OCj2qNOqJJLJmDkH2ciw/3RI6UgMqyWYcbK7xFeDsx9mafkQtIg"
//        
        let testData = Data(repeating: 97, count: 768)
        
        // 데이터를 base64로 인코딩
        let base64String = testData.base64EncodedString()

        // Flutter로 전달
        sendAudioToiPhone(base64String)
        print("테스트 데이터 전송 완료!")
    }
    
    
    // 녹음 시작
    func startRecording() {
        isRecognizing = true
        
        // 오디오 세션 활성화
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("오디오 세션 활성화 실패: \(error.localizedDescription)")
            return
        }
        
        // 오디오 엔진 설정
        audioEngine = AVAudioEngine()
        let inputNode = audioEngine.inputNode
        let bus = 0
        let format = inputNode.inputFormat(forBus: bus)
        
        inputNode.installTap(onBus: bus, bufferSize: 1024, format: format) { (buffer, time) in
            
            let data = Data(bytes: buffer.audioBufferList.pointee.mBuffers.mData!, count: Int(buffer.audioBufferList.pointee.mBuffers.mDataByteSize))
            self.audioBuffer.append(data)  // 데이터 수집

            // 수집된 데이터가 768바이트 이상이 되면 Flutter로 전송
            if self.audioBuffer.count >= self.bufferSize {
                self.sendBufferedData()
            }
        }
        
        // 오디오 엔진 시작
        try? audioEngine.start()
        
        // 테스트 데이터 전송
        sendTestAudioData()
        
        // 잠시 후 녹음 종료 처리
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isRecognizing = false
            self.navigateToSongInfo = true
        }
    }
    
    // 수집된 768바이트의 데이터를 Flutter로 전송
    func sendBufferedData() {
        if audioBuffer.count >= bufferSize {
            let dataToSend = audioBuffer.prefix(bufferSize)  // 768바이트만큼 잘라서
            let base64String = dataToSend.base64EncodedString()
            
            // Flutter로 전달
            sendAudioToiPhone(base64String)
            
            // 전달 후 나머지 데이터는 버퍼에 남겨두기
            audioBuffer.removeSubrange(0..<bufferSize)
        }
    }

    // iPhone으로 오디오 데이터 전송
    func sendAudioToiPhone(_ base64String: String) {
        if sessionActivated && WCSession.default.isReachable {
            WCSession.default.sendMessage(["action": "processAudio", "audioData": base64String], replyHandler: { response in
                print("iPhone으로 오디오 데이터 전송 완료: \(response)")
            }, errorHandler: { error in
                print("전송 실패: \(error.localizedDescription)")
            })
        } else {
            print("iOS 연결 안 됨 (세션 활성화 여부: \(sessionActivated))")
        }
    }

    // 녹음 종료
    func stopRecording() {
        print("녹음 종료")
        isRecognizing = false
        audioEngine.stop()  // 오디오 엔진 정지
        audioEngine.inputNode.removeTap(onBus: 0)  // 오디오 엔진 탭 제거
    }

    // iPhone에서 메시지 받기
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            if let result = message["result"] as? String {
                print("iPhone 분석 결과: \(result)")
            }
        }
    }

    // 세션 활성화 상태 변경
    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        sessionActivated = (state == .activated)
        print("세션 활성화 완료: \(state.rawValue)")
    }
}
