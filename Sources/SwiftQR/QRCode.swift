import Foundation
import Cqr

public struct QRCode: Sendable {

    public let qrcodeData: [[Bool]]

    private static func bufferLenForVersion(_ n: Int32) -> Int {
        (((Int(n) * 4 + 17) * (Int(n) * 4 + 17) + 7) / 8 + 1)
    }

    enum QRCodeGenError: Error {
        case encodeTextFailed
        case encodeDataFailed
        case encodeSegmentFailed
        case bufferAllocationFailed
    }

    public init(
        from segments: [QRCodeGenSegment],
        ecl: ErrorCorrectionLevel = .medium, 
        minVersion: Int32 = 1,
        maxVersion: Int32 = 40,
        maskPattern: MaskPattern = .auto,
        boostEcl: Bool = false
    ) throws {

        let bufferSize = Self.bufferLenForVersion(40)
        let tempBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        let qrcode = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)

        defer {
            tempBuffer.deallocate()
        }

        guard qrcodegen_encodeSegments(
            segments, 
            segments.count, 
            ecl, 
            tempBuffer, 
            qrcode
        ) else {
            throw QRCodeGenError.encodeSegmentFailed
        }

        segments.forEach { segment in
            segment.data.deallocate()
        }

        let size = qrcodegen_getSize(qrcode)
        self.qrcodeData = (0..<size).map { y in
            (0..<size).map { x in
                qrcodegen_getModule(qrcode, x, y)
            }
        }
    }

    public init(
        from data: Data,
        ecl: ErrorCorrectionLevel = .medium, 
        minVersion: Int32 = 1,
        maxVersion: Int32 = 40,
        maskPattern: MaskPattern = .auto,
        boostEcl: Bool = false
    ) throws {
        let bufferSize = Self.bufferLenForVersion(maxVersion)
        let dataAndTempBufferPtr = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: bufferSize)
        guard let dataAndTempBufferBasePointer = dataAndTempBufferPtr.baseAddress else { throw QRCodeGenError.bufferAllocationFailed }
        let qrcode = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)

        data.withUnsafeBytes { bytes in
            let count = min(data.count, bufferSize)
            dataAndTempBufferBasePointer.initialize(from: bytes.bindMemory(to: UInt8.self).baseAddress!, count: count)
        }

        defer {
            dataAndTempBufferBasePointer.deinitialize(count: data.count)
            dataAndTempBufferBasePointer.deallocate()
            qrcode.deallocate()
        }

        guard qrcodegen_encodeBinary(
            dataAndTempBufferBasePointer, 
            data.count, 
            qrcode, 
            ecl, 
            minVersion, 
            maxVersion, 
            maskPattern, 
            boostEcl
        ) else {
            throw QRCodeGenError.encodeDataFailed
        }

        let size = qrcodegen_getSize(qrcode)
        self.qrcodeData = (0..<size).map { y in
            (0..<size).map { x in
                qrcodegen_getModule(qrcode, x, y)
            }
        }
    }

    public init(
        from text: String, 
        ecl: ErrorCorrectionLevel = .medium, 
        minVersion: Int32 = 1,
        maxVersion: Int32 = 40,
        maskPattern: MaskPattern = .auto,
        boostEcl: Bool = false
    ) throws {
        let bufferSize = Self.bufferLenForVersion(maxVersion)
        let temp = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        let qrcode = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)

        defer {
            temp.deallocate()
            qrcode.deallocate()
        }

        guard qrcodegen_encodeText(
            text, 
            temp, 
            qrcode,
            ecl, 
            minVersion, 
            maxVersion, 
            maskPattern, 
            boostEcl
        ) else {
            throw QRCodeGenError.encodeTextFailed
        }
        
        let size = qrcodegen_getSize(qrcode)
        self.qrcodeData = (0..<size).map { y in
            (0..<size).map { x in
                qrcodegen_getModule(qrcode, x, y)
            }
        }
    }
}