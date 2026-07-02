//
//  PrintRequest.swift
//  SKBrotherPrinterWrapper
//
//  The data you hand to `PrinterManager.shared.print(request:from:)`.
//
//  Two ways to supply the code:
//   • Pass the `barcodeImage` you already rendered in your UIImageView, OR
//   • Pass a `barcode` string and let the wrapper generate a QR for you.
//  If both are given, `barcodeImage` wins.
//

import UIKit

public struct PrintRequest {

    /// A barcode/QR image you already generated (e.g. your UIImageView's image).
    /// Used as-is, with its aspect ratio preserved.
    public var barcodeImage: UIImage?

    /// Raw value. Only used to auto-generate a QR when `barcodeImage` is nil.
    public var barcode: String?

    public var name: String
    public var address: String
    public var precinct: String
    public var ballotStyle: String

    public var electionCode: String
    public var pollCode: String
    /// Defaults to the device's current time when the request is created.
    public var time: Date

    /// `DateFormatter` format string used to render `time` in the footer.
    /// Defaults to time-only, e.g. "3:42 PM". Set this to customise, e.g.
    /// `PrintRequest.timeFormat = "MMM d, h:mm a"`.
    public static var timeFormat: String = "yyyy-MM-dd HH:mm:ss"

    /// The election code, poll code and time joined for the footer line,
    /// e.g. "E-2024 | P-07 | 3:42 PM". Empty codes are skipped.
    public var footerLine: String {
        [electionCode, pollCode, PrintRequest.formattedTime(time)]
            .filter { !$0.isEmpty }
            .joined(separator: " | ")
    }

    private static let timeFormatter = DateFormatter()

    private static func formattedTime(_ date: Date) -> String {
        timeFormatter.dateFormat = timeFormat
        return timeFormatter.string(from: date)
    }

    /// Primary initialiser: print the barcode image you already have.
    public init(barcodeImage: UIImage,
                name: String,
                address: String,
                precinct: String,
                ballotStyle: String,
                electionCode: String,
                pollCode: String,
                time: Date = Date()) {
        self.barcodeImage = barcodeImage
        self.barcode = nil
        self.name = name
        self.address = address
        self.precinct = precinct
        self.ballotStyle = ballotStyle
        self.electionCode = electionCode
        self.pollCode = pollCode
        self.time = time
    }

    /// Convenience: pass a string and the wrapper renders a QR code for it.
    public init(barcode: String,
                name: String,
                address: String,
                precinct: String,
                ballotStyle: String,
                electionCode: String,
                pollCode: String,
                time: Date = Date()) {
        self.barcodeImage = nil
        self.barcode = barcode
        self.name = name
        self.address = address
        self.precinct = precinct
        self.ballotStyle = ballotStyle
        self.electionCode = electionCode
        self.pollCode = pollCode
        self.time = time
    }
}
