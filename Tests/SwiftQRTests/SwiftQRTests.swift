import XCTest
@testable import SwiftQR

final class SwiftQRTests: XCTestCase {
    func testData() throws {
        let qrcode = try QRCode(from: "https://www.google.com/ncr".data(using: .utf8)!, ecl: .high)
        print(qrcode.asciiImage)
    }
    func testText() throws {
        let qrcode = try QRCode(from: "6180339887498948482045868343656381177203091798057628621354486227052604628189024497072072041893911374", ecl: .high)
        print(qrcode.asciiImage)
    }
    func testSegments() throws {

        // Byte array representing the C string
        let byteArray: [UInt8] = [
            0x47, 0x6f, 0x6c, 0x64, 0x65, 0x6e, 0x20, 0x72, 0x61, 0x74, 0x69, 0x6f, 0x20,
            0xCF, 0x86, 0x20, 0x3d, 0x20, 0x31, 0x2e
        ]

        // Create Data from the byte array
        let data = Data(byteArray)

        let qrcode = try QRCode(from: [
            .bytes(data),
            .numeric("6180339887498948482045868343656381177203091798057628621354486227052604628189024497072072041893911374"),
            .alphanumeric("......")
        ], ecl: .low)
        print(qrcode.asciiImage)
    }
}
