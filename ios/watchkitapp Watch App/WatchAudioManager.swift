import Foundation
import WatchConnectivity
import AVFoundation

class WatchAudioManager: NSObject, WCSessionDelegate, ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var sessionActivated = false  // ✅ 세션 활성화 상태 저장
    
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
            print("📡 iPhone 실행 요청 전송")
        } else {
            print("🚫 iPhone 연결 안 됨 (세션 활성화 여부: \(sessionActivated))")
        }
    }

    func startRecording() {
        let audioFilename = FileManager.default.temporaryDirectory.appendingPathComponent("recording.m4a")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            print("녹음 시작")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.stopRecording()
            }
        } catch {
            print( "녹음 실패: \(error.localizedDescription)")
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        print("녹음 종료")
        
        if let url = audioRecorder?.url {
            sendAudioToiPhone(url: url)
        }

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
                print("📡 iPhone 분석 결과: \(result)")
            }
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        sessionActivated = (state == .activated)  // 세션 활성화 여부 저장
        print("세션 활성화 완료: \(state.rawValue)")
    }
}
