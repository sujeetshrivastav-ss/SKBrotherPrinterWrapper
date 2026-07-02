//
//  QRCodeGenerator.swift
//  BrotherPrinterWrapper
//
//  Crisp, non-blurry QR codes via Core Image.
//

import UIKit
import CoreImage.CIFilterBuiltins

enum QRCodeGenerator {

    /// Builds a black-on-white QR `UIImage` from any string.
    /// `scale` enlarges the raw CIImage so it prints sharp (no interpolation).
    static func generate(from string: String, scale: CGFloat = 14) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
