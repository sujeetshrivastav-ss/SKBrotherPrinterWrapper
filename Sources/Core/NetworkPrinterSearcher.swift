//
//  NetworkPrinterSearcher.swift
//  SKBrotherPrinterWrapper
//
//  De-duplicating wrapper around `Wrapper_Search`, used by the search screen.
//

import Foundation

final class NetworkPrinterSearcher {

    private let wrapper = Wrapper_Search()
    private(set) var found: [PrinterInfo] = []

    func start(onUpdate: @escaping ([PrinterInfo]) -> Void,
               completion: @escaping (PrinterError?) -> Void) {
        found = []
        let config = PrinterManager.shared.configuration
        wrapper.searchNetwork(
            modelNames: config.searchModelNames,
            duration: config.searchDuration,
            onFound: { [weak self] info in
                guard let self = self else { return }
                guard !self.found.contains(where: { $0.ipAddress == info.ipAddress }) else { return }
                self.found.append(info)
                onUpdate(self.found)
            },
            completion: completion
        )
    }

    func cancel() {
        wrapper.cancel()
    }
}
