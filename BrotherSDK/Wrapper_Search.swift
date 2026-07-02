//
//  Wrapper_Search.swift
//  BrotherPrinterWrapper
//
//  Direct, minimal wrapper around the SDK's network search. Mirrors
//  `NetPrinterSearcher` from the reference demo.
//

import BRLMPrinterKit
import Foundation

final class Wrapper_Search {

    /// Starts an mDNS/SNMP network search. `onFound` is called on the main
    /// thread for each printer; `completion` once the search finishes.
    func searchNetwork(modelNames: [String],
                       duration: Int,
                       onFound: @escaping (PrinterInfo) -> Void,
                       completion: @escaping (PrinterError?) -> Void) {
        DispatchQueue.global().async {
            let option = BRLMNetworkSearchOption()
            option.searchDuration = TimeInterval(duration)
            option.printerList = modelNames

            let result = BRLMPrinterSearcher.startNetworkSearch(option) { channel in
                let model = channel.extraInfo?.value(forKey: BRLMChannelExtraInfoKeyModelName) as? String ?? ""
                let info = PrinterInfo(modelName: model, ipAddress: channel.channelInfo)
                DispatchQueue.main.async { onFound(info) }
            }

            DispatchQueue.main.async {
                switch result.error.code {
                case .noError, .canceled:
                    completion(nil)
                default:
                    completion(.searchFailed("\(result.error.code.rawValue)"))
                }
            }
        }
    }

    func cancel() {
        BRLMPrinterSearcher.cancelNetworkSearch()
    }
}
