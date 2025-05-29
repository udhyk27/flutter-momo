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
    
    @StateObject private var appState = AppState.shared
    
    func openSession() { // 
        if appState.isRecording { return }

        do {
            try AVAudioSession.sharedInstance().setActive(true)
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
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            self?.processBuffer(buffer)
        }

        do {
            try audioEngine.start()
            print("🎤 Microphone started")
        } catch {
            print("❌ Failed to start audio engine: \(error)")
            appState.isRecording = false
            return
        }
    }

    func stop() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        print("🛑 Microphone stopped")
        pcm.deallocate()  // 메모리 해제
    }

    func processBuffer(_ buffer: AVAudioPCMBuffer) {
        // wbuf.length가 fftN*2 이상일 때만 처리
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
    }

    // dna.pack()이 Data 타입 반환한다고 가정
    func sendDnaToServerAndProcess() async {
        let byteArray = dna.pack()   // [UInt8]
        let data = Data(byteArray)   // Data 타입 변환

        var request = URLRequest(url: URL(string: "https://www.mo-mo.co.kr/api/getdnasong")!)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        do {
            let (responseData, _) = try await URLSession.shared.data(for: request)

            let result = try JSONDecoder().decode(SongResult.self, from: responseData)
            print("🎶 Result: \(result.title) - \(result.artist)")
            
            // 필요시 UI 업데이트 등 추가 작업
            
        } catch {
            print("❗️Server or decoding error: \(error)")
        }
    }
}

// 서버 응답 데이터 모델
struct SongResult: Codable {
    let title: String
    let artist: String
    let album: String
}
