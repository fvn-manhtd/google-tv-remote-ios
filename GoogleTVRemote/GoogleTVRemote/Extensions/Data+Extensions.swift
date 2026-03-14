import Foundation

extension Data {
    var hexString: String {
        map { String(format: "%02X", $0) }.joined()
    }

    init?(hexString: String) {
        let cleaned = hexString.replacingOccurrences(of: " ", with: "")
        guard cleaned.count % 2 == 0 else { return nil }

        var data = Data(capacity: cleaned.count / 2)
        var index = cleaned.startIndex
        while index < cleaned.endIndex {
            let nextIndex = cleaned.index(index, offsetBy: 2)
            guard let byte = UInt8(cleaned[index..<nextIndex], radix: 16) else { return nil }
            data.append(byte)
            index = nextIndex
        }
        self = data
    }

    static func parseMACAddress(_ string: String) -> String? {
        let cleaned = string
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "-", with: "")
            .uppercased()

        guard cleaned.count == 12,
              cleaned.allSatisfy({ $0.isHexDigit })
        else { return nil }

        // Format as AA:BB:CC:DD:EE:FF
        var formatted = ""
        var index = cleaned.startIndex
        for i in 0..<6 {
            let nextIndex = cleaned.index(index, offsetBy: 2)
            formatted += cleaned[index..<nextIndex]
            if i < 5 { formatted += ":" }
            index = nextIndex
        }
        return formatted
    }
}
