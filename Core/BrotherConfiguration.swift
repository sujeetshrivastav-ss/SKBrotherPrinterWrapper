//
//  BrotherConfiguration.swift
//  BrotherPrinterWrapper
//
//  Fixed setup for this app: Brother QL-820NWB over Wi-Fi, 54mm continuous film.
//  Tweak via `PrinterManager.shared.configuration` if needed.
//

import BRLMPrinterKit
import Foundation

public final class BrotherConfiguration {

    /// This app targets the Brother QL-820NWB.
    public var printerModel: BRLMPrinterModel = .QL_820NWB

    /// Brother DK-N5224 — 54mm continuous film, non-adhesive.
    public var paper: PrinterPaper = .continuous54mm

    public var numberOfCopies: UInt = 1
    public var autoCut: Bool = true

    /// When `true` (default), `PrinterManager.print(request:from:)` shows the
    /// preview screen with a Print button. Set to `false` to skip the preview
    /// and print straight to the connected printer.
    public var showPrintPreview: Bool = true

    /// How long (seconds) a network search runs.
    public var searchDuration: Int = 15

    /// Only the QL-820NWB is searched for on the network.
    public var searchModelNames: [String] = ["Brother QL-820NWB"]

    public init() {}
}
