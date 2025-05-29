//
//  dnabuf.swift
//  Runner
//
//  Created by 방경식 on 5/29/25.
//

import Foundation

let bufLen = 500

// C 함수 바인딩: void __pcm_to_dna(int16_t*, uint8_t*)
typealias PcmToDnaFunction = @convention(c) (UnsafePointer<Int16>, UnsafeMutablePointer<UInt8>) -> Void
let __pcm_to_dna: PcmToDnaFunction = unsafeBitCast(dlsym(dlopen(nil, RTLD_NOW), "__pcm_to_dna"), to: PcmToDnaFunction.self)

class DnaBuf {
    private var cur = 0
    private var H: [UInt8] = [UInt8](repeating: 0, count: bufLen * 8)
    private var F: [UInt8] = [UInt8](repeating: 0, count: bufLen * 16)
    private var frame: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: 24)

    var length: Int {
        return cur
    }

    func clear() {
        cur = 0
    }

    func push(pcm: UnsafeMutablePointer<UInt8>) {
        __pcm_to_dna(pcm.withMemoryRebound(to: Int16.self, capacity: 2048) { $0 }, frame)

        for i in 0..<8 {
            H[cur * 8 + i] = frame[i]
        }
        for i in 0..<16 {
            F[cur * 16 + i] = frame[8 + i]
        }

        cur += 1
    }

    func pop(_ n: Int) {
        let n = min(n, cur)
        let r = cur - n
        for i in 0..<(r * 8) {
            H[i] = H[i + n * 8]
        }
        for i in 0..<(r * 16) {
            F[i] = F[i + n * 16]
        }
        cur = r
    }

    func pack() -> [UInt8] {
        var result = [UInt8](repeating: 0, count: cur * 24)
        for i in 0..<(cur * 8) {
            result[i] = H[i]
        }
        for i in 0..<(cur * 16) {
            result[cur * 8 + i] = F[i]
        }
        return result
    }

    deinit {
        frame.deallocate()
    }
}
