import Cqr

public typealias ErrorCorrectionLevel = qrcodegen_Ecc
extension ErrorCorrectionLevel {
    public static let low: Self = qrcodegen_Ecc_LOW
    public static let medium: Self = qrcodegen_Ecc_MEDIUM
    public static let qwuartile: Self = qrcodegen_Ecc_QUARTILE
    public static let high: Self = qrcodegen_Ecc_HIGH
}