public extension QRCode {
    var asciiImage: String {
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
}