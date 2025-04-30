import Foundation

class WavBuf {
    private var buf: [UInt8]
    private var cur: Int
    
    init(bufferSize: Int = 48000 * 2) {
        self.buf = [UInt8](repeating: 0, count: bufferSize)
        self.cur = 0
    }
    
    func push(v: [UInt8]) -> Bool {
        if cur + v.count > buf.count {
            return false
        }
        
        for i in 0..<v.count {
            buf[cur] = v[i]
            cur += 1
        }
        return true
    }
    
    func pop(n: Int, dst: inout [UInt8]?) -> Int {
        let n = min(n, cur)
        
        if dst != nil {
            dst?.replaceSubrange(0..<n, with: buf[0..<n])
        }
        
        let r = cur - n
        for i in 0..<r {
            buf[i] = buf[n + i]
        }
        cur = r
        return n
    }
    
    func read(n: Int, p: UnsafeMutablePointer<UInt8>) -> Int {
        let n = min(n, cur)
        for i in 0..<n {
            p[i] = buf[i]
        }
        return n
    }
    
    func copy(n: Int, dst: inout [UInt8]) -> Int {
        let n = min(n, cur)
        dst.replaceSubrange(0..<n, with: buf[0..<n])
        return n
    }
    
    var length: Int {
        return cur
    }
    
    func clear() {
        cur = 0
    }
}
