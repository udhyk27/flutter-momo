import Foundation
import WatchConnectivity
import AVFoundation

class WatchAudioManager: NSObject, WCSessionDelegate, ObservableObject {
    private var contentView = ContentView()
    
    // @Published는 값이 수정될 때마다 뷰에 반영함
    @Published var isRecognizing = false // 녹음 중 표시
    @Published var navigateToSongInfo = false // 결과 화면 전환 여부
    
    private var audioRecorder: AVAudioRecorder?
    private var sessionActivated = false  // 세션 활성화 상태 저장
    private var songFound = false // 곡 인식 성공여부
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func wakeUpiPhone() {
        if sessionActivated && WCSession.default.isReachable {
            WCSession.default.sendMessage(["action": "wakeUp"], replyHandler: nil)
            print("iPhone 실행 요청 전송")
        } else {
            print("iPhone 연결 안 됨 (세션 활성화 여부: \(sessionActivated))")
        }
    }

    // 녹음 시작
    func startRecording() {
        isRecognizing = true
        
        // iOS 데이터 전송
//        wakeUpiPhone()

//        songFound = true // 노래 찾았다고 가정

        // 3초 인디케이터
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // 순환 참조가 될 수 있는 것들은 self.
            self.isRecognizing = false
            self.navigateToSongInfo = true
        }
        
        // 오디오 세션 활성화
//        do {
//            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
//            try AVAudioSession.sharedInstance().setActive(true)
//        } catch {
//            print("오디오 세션 활성화 실패: \(error.localizedDescription)")
//            return
//        }
    }
    
    
    // 녹음 끝
    func stopRecording() {
//        audioRecorder?.stop()
        print("녹음 종료")
        
//        if let url = audioRecorder?.url {
//            sendAudioToiPhone(url: url)
//        }

        isRecognizing = false
        audioRecorder = nil  // 다음 녹음을 위해 초기화
        
    }

    func sendAudioToiPhone(url: URL) {
        if sessionActivated && WCSession.default.isReachable {
            do {
                let audioData = try Data(contentsOf: url)
                WCSession.default.sendMessage(["action": "processAudio", "audioData": audioData], replyHandler: nil, errorHandler: { error in
                    print("전송 실패: \(error.localizedDescription)")
                })
                print("iPhone으로 오디오 데이터 직접 전송")
            } catch {
                print("오디오 파일 변환 실패: \(error.localizedDescription)")
            }
        } else {
            print("iOS 연결 안 됨 (세션 활성화 여부: \(sessionActivated))")
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            if let result = message["result"] as? String {
                print("iPhone 분석 결과: \(result)")
            }
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        sessionActivated = (state == .activated)  // 세션 활성화 여부 저장
        print("세션 활성화 완료: \(state.rawValue)")
    }
}
