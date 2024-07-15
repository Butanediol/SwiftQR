// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import Cqr

typealias ErrorCorrectionLevel = qrcodegen_Ecc
extension ErrorCorrectionLevel {
    static let low: Self = qrcodegen_Ecc_LOW
    static let medium: Self = qrcodegen_Ecc_MEDIUM
    static let qwuartile: Self = qrcodegen_Ecc_QUARTILE
    static let high: Self = qrcodegen_Ecc_HIGH
}

typealias MaskPattern = qrcodegen_Mask
extension qrcodegen_Mask {
    static let auto = qrcodegen_Mask_AUTO
    static let mask0 = qrcodegen_Mask_0
    static let mask1 = qrcodegen_Mask_1
    static let mask2 = qrcodegen_Mask_2
    static let mask3 = qrcodegen_Mask_3
    static let mask4 = qrcodegen_Mask_4
    static let mask5 = qrcodegen_Mask_5
    static let mask6 = qrcodegen_Mask_6
    static let mask7 = qrcodegen_Mask_7
}

typealias QRCodeGenMode = qrcodegen_Mode
extension QRCodeGenMode {
	static let numeric = qrcodegen_Mode_NUMERIC
	static let alphanumeric = qrcodegen_Mode_ALPHANUMERIC
	static let byte = qrcodegen_Mode_BYTE
	static let kanji = qrcodegen_Mode_KANJI
	static let eci = qrcodegen_Mode_ECI
}

typealias QRCodeGenSegment = qrcodegen_Segment
extension QRCodeGenSegment {

    init(mode: QRCodeGenMode, numChars: Int32, data: Data, bitLength: Int32) {

        let dataMutablePtr = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        guard let dataPtr = data.withUnsafeBytes({ $0.assumingMemoryBound(to: UInt8.self).baseAddress }) else {
            fatalError("")
        }
        dataMutablePtr.initialize(from: dataPtr, count: data.count)
        defer {
            dataMutablePtr.deinitialize(count: data.count)
            dataMutablePtr.deallocate()
        }
        
        self.init(
            mode: mode, 
            numChars: numChars, 
            data: dataMutablePtr, 
            bitLength: bitLength
        )
    }

     // Returns a segment representing the given string of decimal digits encoded in numeric mode.
    static func numeric(_ digits: String) -> Self {
        guard digits.allSatisfy(\.isNumber) else { fatalError("Input should be a number") }
        let bufferSize = qrcodegen_calcSegmentBufferSize(.numeric, digits.count)
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        return qrcodegen_makeNumeric(digits, buffer)
    }

    static func alphanumeric(_ text: String) -> Self {
        guard text.allSatisfy ({
            $0.isNumber || 
            ($0.isLetter && $0.isUppercase) || 
            [" ", "$", "%", "*", "+", "-", ".", "/", ";"].contains($0)
        }) else { fatalError("Input should be alphanumeric*") }
        let bufferSize = qrcodegen_calcSegmentBufferSize(.alphanumeric, text.count)
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        return qrcodegen_makeAlphanumeric(text, buffer)
    }

    static func eci(_ assignValue: Int) -> Self {
        let bufferSize = qrcodegen_calcSegmentBufferSize(.eci, 0)
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        return qrcodegen_makeEci(assignValue, buffer)
    }

    static func bytes(_ data: Data) -> Self {
        guard let dataPtr = data.withUnsafeBytes({ rawBufferPointer in
            rawBufferPointer.assumingMemoryBound(to: UInt8.self).baseAddress
        }) else {
            fatalError("Failed to get data pointer")
        }
        let bufferSize = qrcodegen_calcSegmentBufferSize(.byte, data.count)
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        return qrcodegen_makeBytes(dataPtr, bufferSize, buffer)
    }
}

public struct QRCode: Sendable {

    private let qrcodeData: [[Bool]]

    private static func bufferLenForVersion(_ n: Int32) -> Int {
        (((Int(n) * 4 + 17) * (Int(n) * 4 + 17) + 7) / 8 + 1)
    }

    enum QRCodeGenError: Error {
        case encodeTextFailed
        case encodeDataFailed
        case encodeSegmentFailed
        case bufferAllocationFailed
    }

    public var asciiImage: String {
        let N = qrcodeData.count
        guard qrcodeData.allSatisfy({ $0.count == N}) else {
            fatalError("QRCode is not square")
        }

        var paddedMatrix = qrcodeData
        if (N % 2 != 0) {
            paddedMatrix.append([Bool](repeating: false, count: N))
        }
        
        return stride(from: 0, to: paddedMatrix.count, by: 2).map { row in
            (0..<N).map { col in
                switch (paddedMatrix[row][col], paddedMatrix[row + 1][col]) {
                    case (false, false): " " 
                    case (false, true): "▄"
                    case (true, false): "▀"
                    case (true, true): "█"
                }
            }.joined()
        }.joined(separator: "\n")
    }

    init(
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

    init(
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

    init(
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