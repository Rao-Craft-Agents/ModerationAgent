//  WHAT: A new object's id in an Xcode project: 24 hex digits made from what the object is, so the same link makes
//        the same ids, and never an id the file already holds.

import Foundation

enum ObjectID {
    /// An id for the object `seed` describes that `text` does not hold yet.
    static func fresh(_ seed: String, avoiding text: PBXText) -> String {
        var attempt = 0
        while true {
            let id = make(attempt == 0 ? seed : "\(seed)#\(attempt)")
            if !text.contains(id) { return id }
            attempt += 1
        }
    }

    /// 24 uppercase hex digits from two FNV-1a hashes of `seed`.
    static func make(_ seed: String) -> String {
        var long: UInt64 = 0xcbf2_9ce4_8422_2325
        var short: UInt32 = 0x811c_9dc5
        for byte in seed.utf8 {
            long = (long ^ UInt64(byte)) &* 0x0000_0100_0000_01b3
            short = (short ^ UInt32(byte)) &* 0x0100_0193
        }
        let high = String(long, radix: 16, uppercase: true)
        let low = String(short, radix: 16, uppercase: true)
        return String(repeating: "0", count: 16 - high.count) + high + String(repeating: "0", count: 8 - low.count) + low
    }
}
