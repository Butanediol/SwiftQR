import Cqr

public typealias QRCodeGenMode = qrcodegen_Mode
extension QRCodeGenMode {
	public static let numeric = qrcodegen_Mode_NUMERIC
	public static let alphanumeric = qrcodegen_Mode_ALPHANUMERIC
	public static let byte = qrcodegen_Mode_BYTE
	public static let kanji = qrcodegen_Mode_KANJI
	public static let eci = qrcodegen_Mode_ECI
}