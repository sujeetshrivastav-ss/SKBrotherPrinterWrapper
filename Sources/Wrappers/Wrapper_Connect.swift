//
//  Wrapper_Connect.swift
//  SKBrotherPrinterWrapper
//
//  Opens a live printer driver over Wi-Fi. Mirrors `PrinterConnectUtil`
//  from the reference demo (a fresh channel is built from the IP each time).
//

import BRLMPrinterKit
import Foundation

final class Wrapper_Connect {

    /// Returns an open `BRLMPrinterDriver` ready to print, or a failure.
    /// The caller is responsible for calling `closeChannel()` when done.
    func openDriver(ipAddress: String) -> Result<BRLMPrinterDriver, PrinterError> {
        let channel = BRLMChannel(wifiIPAddress: ipAddress)
        let generated = BRLMPrinterDriverGenerator.open(channel)

        guard generated.error.code == BRLMOpenChannelErrorCode.noError,
              let driver = generated.driver else {
            return .failure(.connectionFailed("\(generated.error.code.rawValue)"))
        }
        return .success(driver)
    }
}
