//
//  BrotherPrinterEngine.swift
//  SKBrotherPrinterWrapper
//
//  Renders the label, connects to the QL-820NWB over Wi-Fi, prints, and
//  reports back on the main thread. Combines the three SDK wrappers.
//

import BRLMPrinterKit
import UIKit

final class BrotherPrinterEngine {

    private let connect = Wrapper_Connect()
    private let output  = Wrapper_Print()
    private let formatter = LabelFormatter()

    /// Render (main thread) → connect + print (background) → completion (main).
    func print(request: PrintRequest,
               to printer: PrinterInfo,
               config: BrotherConfiguration,
               completion: @escaping (Result<Void, PrinterError>) -> Void) {

        // Rendering touches UIKit, so do it on the calling (main) thread.
        guard let cgImage = formatter.makeLabelImage(for: request, paper: config.paper)?.cgImage else {
            completion(.failure(.renderingFailed))
            return
        }

        DispatchQueue.global().async {
            PrinterLogger.log("Connecting to \(printer.ipAddress) ...")
            switch self.connect.openDriver(ipAddress: printer.ipAddress) {
            case .failure(let error):
                DispatchQueue.main.async { completion(.failure(error)) }

            case .success(let driver):
                guard let settings = self.output.makeSettings(model: config.printerModel,
                                                              paper: config.paper,
                                                              copies: config.numberOfCopies,
                                                              autoCut: config.autoCut) else {
                    driver.closeChannel()
                    DispatchQueue.main.async { completion(.failure(.printFailed("Unsupported settings"))) }
                    return
                }
                // Surface any settings/media mismatch before sending the job.
                self.output.validate(settings)

                PrinterLogger.log("Printing ...")
                let printError = self.output.print(image: cgImage, driver: driver, settings: settings)
                DispatchQueue.main.async {
                    if let printError = printError {
                        completion(.failure(printError))
                    } else {
                        completion(.success(()))
                    }
                }
            }
        }
    }
}
