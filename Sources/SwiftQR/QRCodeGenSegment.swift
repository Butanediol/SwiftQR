import Foundation
import Cqr

public typealias QRCodeGenSegment = qrcodegen_Segment
public extension QRCodeGenSegment {

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
