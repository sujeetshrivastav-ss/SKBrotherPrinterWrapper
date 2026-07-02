//
//  PrinterError.swift
//  SKBrotherPrinterWrapper
//
//  Every failure the wrapper can produce, with a user-ready message.
//

import Foundation

public enum PrinterError: LocalizedError, Equatable {
    case notConnected
    case noPrinterFound
    case searchFailed(String)
    case channelCreationFailed
    case connectionFailed(String)
    case renderingFailed
    case printFailed(String)
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .notConnected:
            return "No printer is connected. Tap the status dot to search for one."
        case .noPrinterFound:
            return "No printer was found on the network."
        case .searchFailed(let reason):
            return "Printer search failed (\(reason))."
        case .channelCreationFailed:
            return "Could not create a connection channel to the printer."
        case .connectionFailed(let reason):
            return "Could not connect to the printer (\(reason))."
        case .renderingFailed:
            return "Could not render the label image."
        case .printFailed(let reason):
            return "Printing failed (\(reason))."
        case .cancelled:
            return "The operation was cancelled."
        }
    }
}
