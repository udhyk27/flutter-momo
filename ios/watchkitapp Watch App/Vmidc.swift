import AVFoundation
import Foundation
import WavBuf
import DnaBuf

let srate = 16000
let fftN = 2048
let fftHop = 1000
let qLen = 32

class VMIDC {
    private var audioEngine: AVAudioEngine!
    private var audioInputNode: AVAudioInputNode!
    private var audioFormat: AVAudioFormat!
    private var audioBuffer: AVAudioPCMBuffer!
    private var pcm: UnsafeMutablePointer<UInt8>
    
    private var wbuf = WavBuf()
    private var dna = DnaBuf()
    
    private var num = 1
    private var current: [String: Any] = [:]
    
    init() {
        pcm = UnsafeMutablePointer<UInt8>.allocate(capacity: fftN * 2)
    }
    
    func initRecorder() -> Bool {
        print("vmidc init")
        
        audioEngine = AVAudioEngine()
        audioInputNode = audioEngine.inputNode
        audioFormat = AVAudioFormat(standardFormatWithSampleRate: Double(srate), channels: 1)
        
        // 오디오 세션 설정
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("오디오 세션 설정 오류: \(error)")
            return false
        }
        
        // 오디오 입력 노드에서 오디오 데이터 읽기
        audioInputNode.installTap(onBus: 0, bufferSize: fftN, format: audioFormat) { (buffer, time) in
            self.processBuffer(buffer: buffer)
        }
        
        do {
            try audioEngine.start()
        } catch {
            print("오디오 엔진 시작 오류: \(error)")
            return false
        }
        
        return true
    }
    
    func processBuffer(buffer: AVAudioPCMBuffer) {
        // 오디오 버퍼 처리
        let audioData = buffer.int16ChannelData?[0]
        let bufferSize = Int(buffer.frameLength)
        
        var data = Data(bytes: audioData, count: bufferSize * MemoryLayout<Int16>.size)
        
        if data.count > fftHop * 2 {
            var offset = 0
            while offset < data.count {
                let chunkSize = min(fftHop * 2, data.count - offset)
                let chunk = data.subdata(in: offset..<(offset + chunkSize))
                
                wbuf.push(chunk)
                processWBuf()
                
                offset += chunkSize
            }
        } else {
            wbuf.push(data)
            processWBuf()
        }
    }
    
    func processWBuf() {
        if wbuf.length >= fftN * 2 {
            wbuf.read(fftN * 2, pcm)
            dna.push(pcm)
            wbuf.pop(fftHop * 2)
            
            if dna.length == qLen {
                sendDnaToServerAndProcess()
            }
        }
    }
    
    func sendDnaToServerAndProcess() {
        print("DNA \(qLen)개 도달: \(DateTime.now())")
        
        let dnaData = dna.pack()
        sendDnaToServer(dna: dnaData)
    }
    
    func sendDnaToServer(dna: [Int]) {
        let url = URL(string: "https://your-server.com/api")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "uid": MyApp.uid,
            "req_times": num,
            "dna_data": dna
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("HTTP 요청 중 오류 발생: \(error)")
                    return
                }
                
                guard let data = data else {
                    print("응답 데이터 없음")
                    return
                }
                
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        self.handleServerResponse(jsonResponse)
                    }
                } catch {
                    print("응답 데이터 처리 오류: \(error)")
                }
            }
            
            task.resume()
        } catch {
            print("HTTP 요청 오류: \(error)")
        }
    }
    
    func handleServerResponse(_ response: [String: Any]) {
        if let errorMsg = response["err_msg"] as? String, errorMsg != "" {
            print("error msg 1 / 음악 인식 STOP")
            stop()
        }
        
        if let data = response["data"] as? String, !data.isEmpty {
            print("곡 인식 성공 !!")
            let song = ApiSearch(fromJson: data)
            // 여기에 SongInfoScreen 화면으로 전환하는 코드 작성
        }
        
        dna.pop(qLen)
    }
    
    func start() {
        print("찾기까지 걸린 시작시간 :: \(DateTime.now())")
        num = 1
        
        // 녹음 시작
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: fftN, format: audioFormat) { (buffer, time) in
            self.processBuffer(buffer: buffer)
        }
        
        do {
            try audioEngine.start()
        } catch {
            print("오디오 엔진 시작 오류: \(error)")
        }
    }
    
    func stop() {
        print("vmid.stop()")
        num = 1
        
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        
        wbuf.clear()
        dna.clear()
    }
    
    func dispose() {
        print("vmidc dispose")
        
        stop()
        pcm.deallocate()
    }
}
