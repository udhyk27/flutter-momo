import Foundation

// 네이티브 라이브러리 로딩
let nativeLib = {
    if #available(iOS 13.0, *) {
        return dlopen("libnative.dylib", RTLD_NOW)
    } else {
        return dlopen("libnative.dylib", RTLD_NOW)
    }
}()

// 네이티브 함수 로드
typealias PcmToDnaFunction = @convention(c) (UnsafeMutablePointer<Int16>, UnsafeMutablePointer<UInt8>) -> Void

var __pcm_to_dna: PcmToDnaFunction? = {
    guard let ptr = dlsym(nativeLib, "__pcm_to_dna") else {
        return nil
    }
    return unsafeBitCast(ptr, to: PcmToDnaFunction.self)
}()

// 버퍼 크기
let bufLen = 500

class DnaBuf {
    private var cur = 0
    private var H = [UInt8](repeating: 0, count: bufLen * 8)
    private var F = [UInt8](repeating: 0, count: bufLen * 16)
    private var frame = [UInt8](repeating: 0, count: 24)
    
    var length: Int {
        return cur
    }
    
    func clear() {
        cur = 0
    }
    
    func push(pcm: UnsafeMutablePointer<UInt8>) {
        // 네이티브 함수 호출
        if let pcmToDna = __pcm_to_dna {
            // pcm을 직접 Int16로 변환하여 사용
            let pcmInt16 = pcm.withMemoryRebound(to: Int16.self, capacity: bufLen) { ptr in
                pcmToDna(ptr, &frame)
            }
        }
        
        // H, F에 데이터 복사
        for i in 0..<8 {
            H[cur * 8 + i] = frame[i]
        }
        
        for i in 0..<16 {
            F[cur * 16 + i] = frame[8 + i]
        }
        
        cur += 1
    }
    
    func pop(n: Int) {
        let n = min(n, cur)
        let r = cur - n
        
        // H, F에서 데이터를 이동
        for i in 0..<r * 8 {
            H[i] = H[i + n * 8]
        }
        
        for i in 0..<r * 16 {
            F[i] = F[i + n * 16]
        }
        
        cur = r
    }
    
    func pack() -> [UInt8] {
        var dna32 = [UInt8](repeating: 0, count: cur * 24)
        
        // H 복사
        for i in 0..<cur * 8 {
            dna32[i] = H[i]
        }
        
        // F 복사
        var p = cur * 8
        for i in 0..<cur * 16 {
            dna32[p + i] = F[i]
        }
        
        return dna32
    }
}
