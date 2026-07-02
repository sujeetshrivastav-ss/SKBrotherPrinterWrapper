//
//  Wrapper_Print.swift
//  SKBrotherPrinterWrapper
//
//  Builds QL print settings and sends one image to the driver. Mirrors
//  `PrintImageFacade.printImageWithImage` from the reference demo, and reports
//  the SDK's full error detail (code name + `allLogs`) so failures are clear.
//

import BRLMPrinterKit
import UIKit

final class Wrapper_Print {

    /// Default QL print settings for the given model + paper.
    func makeSettings(model: BRLMPrinterModel,
                      paper: PrinterPaper,
                      copies: UInt,
                      autoCut: Bool) -> BRLMPrintSettingsProtocol? {
        guard let settings = BRLMQLPrintSettings(defaultPrintSettingsWith: model) else { return nil }
        settings.labelSize = paper.qlLabelSize
        settings.numCopies = max(1, copies)
        settings.autoCut = autoCut
        // Scale our generated bitmap to fit the label (forgiving if the image
        // dimensions don't exactly equal the label's dot count).
        settings.scaleMode = .fitPageAspect
        return settings
    }

    /// Runs the SDK's own settings validation (same check as the demo's
    /// "Validate" screen). Logs the report; returns a message if invalid.
    @discardableResult
    func validate(_ settings: BRLMPrintSettingsProtocol) -> String {
        let report = BRLMValidatePrintSettings.validate(settings)
        let text = report.description()
        PrinterLogger.log("Validate report:\n\(text)")
        return text
    }

    /// Prints the image and always closes the channel. Returns `nil` on success,
    /// or a `.printFailed` carrying the SDK code name + detailed log on failure.
    func print(image: CGImage,
               driver: BRLMPrinterDriver,
               settings: BRLMPrintSettingsProtocol) -> PrinterError? {
        let printError = driver.printImage(with: image, settings: settings)
        driver.closeChannel()

        // The SDK's per-step log – this is where the *real* reason lives.
        let logs = printError.allLogs
            .map { $0.errorDescription }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")

        let codeName = Wrapper_Print.name(for: printError.code)
        PrinterLogger.log("""
            Print result: code=\(printError.code.rawValue) (\(codeName))
            \(logs.isEmpty ? "(no extra logs)" : logs)
            """)

        guard printError.code == .noError else {
            var detail = codeName
            if !logs.isEmpty { detail += "\n\(logs)" }
            return .printFailed(detail)
        }
        return nil
    }

    // MARK: - Error code → readable name (mirrors the reference demo)

    private static func name(for code: BRLMPrintErrorCode) -> String { // swiftlint:disable:this cyclomatic_complexity function_body_length
        switch code {
        case .noError:                                    return "No error"
        case .printSettingsError:                         return "Print settings error"
        case .filepathURLError:                           return "File path / URL error"
        case .pdfPageError:                               return "PDF page error"
        case .printSettingsNotSupportError:               return "Print setting not supported by this model"
        case .dataBufferError:                            return "Data buffer error"
        case .printerModelError:                          return "Printer model mismatch"
        case .canceled:                                   return "Cancelled"
        case .channelTimeout:                             return "Connection timed out"
        case .setModelError:                              return "Set model error"
        case .unsupportedFile:                            return "Unsupported file"
        case .setMarginError:                             return "Set margin error"
        case .setLabelSizeError:                          return "Label size error (does the loaded label match the settings?)"
        case .customPaperSizeError:                       return "Custom paper size error"
        case .setLengthError:                             return "Set length error"
        case .tubeSettingError:                           return "Tube setting error"
        case .channelErrorStreamStatusError:              return "Channel stream status error"
        case .channelErrorUnsupportedChannel:             return "Unsupported channel"
        case .printerStatusErrorPaperEmpty:               return "Out of paper / no label"
        case .printerStatusErrorCoverOpen:                return "Cover is open"
        case .printerStatusErrorBusy:                     return "Printer is busy"
        case .printerStatusErrorPrinterTurnedOff:         return "Printer is turned off"
        case .printerStatusErrorBatteryWeak:              return "Battery weak"
        case .printerStatusErrorExpansionBufferFull:      return "Expansion buffer full"
        case .printerStatusErrorCommunicationError:       return "Communication error"
        case .printerStatusErrorPaperJam:                 return "Paper jam"
        case .printerStatusErrorMediaCannotBeFed:         return "Media cannot be fed (wrong/empty label?)"
        case .printerStatusErrorOverHeat:                 return "Printer overheated"
        case .printerStatusErrorHighVoltageAdapter:       return "High voltage adapter error"
        case .printerStatusErrorUnknownError:             return "Printer status: unknown error"
        case .templatePrintNotSupported:                  return "Template print not supported"
        case .invalidTemplateKey:                         return "Invalid template key"
        case .printerStatusErrorMotorSlow:                return "Motor slow"
        case .unsupportedCharger:                         return "Unsupported charger"
        case .printerStatusErrorIncompatibleOptionalEquipment: return "Incompatible optional equipment"
        case .unknownError:                               return "Unknown error"
        @unknown default:                                 return "Error code \(code.rawValue)"
        }
    }
}
