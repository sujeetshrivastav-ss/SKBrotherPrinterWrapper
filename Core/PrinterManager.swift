//
//  PrinterManager.swift
//  BrotherPrinterWrapper
//
//  ⭐ THE ONLY CLASS YOUR APP USES.
//
//  Usage:
//
//      // 1. Search (opens a screen, stores the picked printer, flips dot green)
//      PrinterManager.shared.searchPrinter(from: self)
//
//      // 2. Reflect connection state on your red/green dot
//      dotView.backgroundColor = PrinterManager.shared.isConnected ? .systemGreen : .systemRed
//      // (or observe PrinterManager.connectionDidChange)
//
//      // 3. Print (opens a preview screen with a Print button)
//      let request = PrintRequest(barcode: voter.barcode,
//                                 name: voter.name,
//                                 address: voter.address,
//                                 precinct: voter.precinct,
//                                 ballotStyle: voter.ballotStyle)
//      PrinterManager.shared.print(request: request, from: self)
//

import UIKit

public final class PrinterManager {

    public static let shared = PrinterManager()
    private init() {}

    /// One-time tweakable settings (model, paper, copies, search duration).
    public let configuration = BrotherConfiguration()

    private let engine = BrotherPrinterEngine()

    // MARK: - Connection state

    /// `true` once a printer has been picked. Drive your dot from this.
    public var isConnected: Bool { PrinterSession.shared.isConnected }

    /// The currently connected printer, if any.
    public var connectedPrinter: PrinterInfo? { PrinterSession.shared.connectedPrinter }

    /// Observe this to repaint the dot the moment the connection changes.
    public static let connectionDidChange = PrinterSession.didChangeNotification

    /// Forget the printer (dot goes back to red).
    public func disconnect() {
        PrinterSession.shared.clear()
    }

    // MARK: - Public actions

    /// Presents the search screen. When the user picks a printer it is stored
    /// in the shared session (dot turns green) and `completion` fires.
    public func searchPrinter(from presenter: UIViewController,
                              completion: ((PrinterInfo?) -> Void)? = nil) {
        let searchVC = PrinterSearchViewController { printer in
            completion?(printer)
        }
        present(searchVC, from: presenter)
    }

    /// Prints a label. By default this presents the preview screen (QR + details)
    /// and the user confirms with the Print button. When
    /// `configuration.showPrintPreview` is `false`, the preview is skipped and the
    /// label is sent straight to the connected printer. If no printer is connected
    /// the search screen is shown first. `completion` reports the final result.
    public func print(request: PrintRequest,
                      from presenter: UIViewController,
                      completion: ((Result<Void, PrinterError>) -> Void)? = nil) {
        guard configuration.showPrintPreview else {
            printDirectly(request: request, from: presenter, completion: completion)
            return
        }
        let previewVC = PrintPreviewViewController(request: request, completion: completion)
        present(previewVC, from: presenter)
    }

    /// Prints without the preview screen. If no printer is connected yet, the
    /// search screen is shown first and the print runs once one is picked.
    private func printDirectly(request: PrintRequest,
                               from presenter: UIViewController,
                               completion: ((Result<Void, PrinterError>) -> Void)?) {
        guard isConnected else {
            searchPrinter(from: presenter) { [weak self] printer in
                guard let self = self else { return }
                guard printer != nil else {
                    completion?(.failure(.notConnected))
                    return
                }
                self.printDirectly(request: request, from: presenter, completion: completion)
            }
            return
        }

        let loading = LoadingView.show(in: presenter.view, message: "Printing…")
        performPrint(request: request) { result in
            loading.hide()
            completion?(result)
        }
    }

    // MARK: - Internal (used by the preview screen)

    func performPrint(request: PrintRequest,
                      completion: @escaping (Result<Void, PrinterError>) -> Void) {
        guard let printer = PrinterSession.shared.connectedPrinter else {
            completion(.failure(.notConnected))
            return
        }
        engine.print(request: request, to: printer, config: configuration, completion: completion)
    }

    private func present(_ viewController: UIViewController, from presenter: UIViewController) {
        let nav = UINavigationController(rootViewController: viewController)
        nav.modalPresentationStyle = .formSheet
        presenter.present(nav, animated: true)
    }
}
