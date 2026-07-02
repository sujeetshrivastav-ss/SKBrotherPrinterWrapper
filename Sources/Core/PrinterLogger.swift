//
//  PrinterLogger.swift
//  SKBrotherPrinterWrapper
//

import Foundation

enum PrinterLogger {
    static var isEnabled = true

    static func log(_ message: String) {
        guard isEnabled else { return }
        print("🖨️ [BrotherPrinter] \(message)")
    }
}
