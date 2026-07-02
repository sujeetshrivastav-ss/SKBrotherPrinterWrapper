//
//  PrinterStatus.swift
//  SKBrotherPrinterWrapper
//
//  Lightweight lifecycle state, surfaced through logging / callbacks.
//

import Foundation

public enum PrinterStatus: Equatable {
    case idle
    case searching
    case connecting
    case printing
    case completed
    case failed(PrinterError)
}
