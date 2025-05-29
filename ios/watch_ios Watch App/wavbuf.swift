
//
//  wbuf.swift
//  Runner
//
//  Created by 방경식 on 5/29/25.
//

import Foundation

class WaveBuf {
    private var buf: [UInt8]
    private var cur: Int = 0
    private let capacity: Int

    init(size: Int = 48000 * 2) {
        self.capacity = size
        self.buf = [UInt8](repeating: 0, count: size)
    }

    /// 데이터 삽입
    func push(_ data: [UInt8]) -> Bool {
        if cur + data.count > capacity {
            return false
        }
        for byte in data {
            buf[cur] = byte
            cur += 1
        }
        return true
    }

    /// 앞에서 n개 제거 (선택적으로 dst로 복사)
    @discardableResult
    func pop(_ n: Int, dst: UnsafeMutablePointer<UInt8>? = nil) -> Int {
        let len = min(n, cur)
        if let d = dst {
            for i in 0..<len {
                d[i] = buf[i]
            }
        }

        let remaining = cur - len
        for i in 0..<remaining {
            buf[i] = buf[len + i]
        }

        cur = remaining
        return len
    }

    /// Pointer로 복사 (C 코드와 연동할 때)
    @discardableResult
    func read(_ n: Int, to ptr: UnsafeMutablePointer<UInt8>) -> Int {
        let len = min(n, cur)
        for i in 0..<len {
            ptr[i] = buf[i]
        }
        return len
    }

    /// Swift 배열로 복사
    @discardableResult
    func copy(_ n: Int, to dst: inout [UInt8]) -> Int {
        let len = min(n, cur)
        for i in 0..<len {
            dst[i] = buf[i]
        }
        return len
    }

    var length: Int {
        return cur
    }

    func clear() {
        cur = 0
    }
}
