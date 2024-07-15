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
        let qrcode = try QRCode(from: [
            .bytes("Golden ratio \(0xCF)\(0x86) = 1.".data(using: .utf8)!),
            .numeric("6180339887498948482045868343656381177203091798057628621354486227052604628189024497072072041893911374"),
            .alphanumeric("......")
        ], ecl: .low)
        print(qrcode.asciiImage)
    }
}
