//
//  PrinterSearchViewController.swift
//  SKBrotherPrinterWrapper
//
//  Auto-searches the network, lists what it finds, and on selection stores the
//  printer in the shared session (turning the dot green) then dismisses.
//

import UIKit

final class PrinterSearchViewController: UITableViewController {

    private let searcher = NetworkPrinterSearcher()
    private var printers: [PrinterInfo] = []
    private let onSelect: (PrinterInfo?) -> Void
    private var loading: LoadingView?
    private var didFinish = false

    /// A full-size, non-scrolling host for the overlay. `self.view` is the
    /// UITableView (a scroll view), so pinning the loader to it collapses it
    /// into the top-left corner — use the nav controller's view instead.
    private var loaderHost: UIView { navigationController?.view ?? view }

    init(onSelect: @escaping (PrinterInfo?) -> Void) {
        self.onSelect = onSelect
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Select Printer"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                           target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh,
                                                            target: self, action: #selector(startSearch))
        startSearch()
    }

    @objc private func startSearch() {
        searcher.cancel()
        printers = []
        tableView.reloadData()
        loading?.hide()
        loading = LoadingView.show(in: loaderHost, message: "Searching for printers…")

        searcher.start(
            onUpdate: { [weak self] list in
                guard let self = self else { return }
                self.printers = list
                self.loading?.hide()      // show results as they arrive
                self.loading = nil
                self.tableView.reloadData()
            },
            completion: { [weak self] error in
                guard let self = self else { return }
                self.loading?.hide()
                self.loading = nil
                if self.printers.isEmpty {
                    self.showEmptyOrError(error)
                }
            }
        )
    }

    private func showEmptyOrError(_ error: PrinterError?) {
        let message = error?.errorDescription ?? PrinterError.noPrinterFound.errorDescription
        let alert = UIAlertController(title: "No Printer Found", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in self?.startSearch() })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in self?.cancelTapped() })
        present(alert, animated: true)
    }

    @objc private func cancelTapped() {
        finish(with: nil)
    }

    private func finish(with printer: PrinterInfo?) {
        guard !didFinish else { return }
        didFinish = true
        searcher.cancel()
        if let printer = printer {
            PrinterSession.shared.setConnected(printer)
        }
        dismiss(animated: true) { [weak self] in
            self?.onSelect(printer)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        searcher.cancel()
    }

    // MARK: - Table

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        printers.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let printer = printers[indexPath.row]
        let isCurrent = (printer == PrinterSession.shared.connectedPrinter)

        var config = cell.defaultContentConfiguration()
        config.text = printer.displayName
        config.secondaryText = isCurrent ? "\(printer.ipAddress) • Connected" : printer.ipAddress
        // Dim the already-connected printer so it reads as unavailable.
        config.textProperties.color = isCurrent ? .secondaryLabel : .label
        cell.contentConfiguration = config

        // The connected printer isn't tappable; other printers can be selected
        // to switch. Reset both branches since cells are reused.
        cell.accessoryType = isCurrent ? .checkmark : .disclosureIndicator
        cell.selectionStyle = isCurrent ? .none : .default
        cell.isUserInteractionEnabled = !isCurrent
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let printer = printers[indexPath.row]
        // Ignore taps on the already-connected printer.
        guard printer != PrinterSession.shared.connectedPrinter else { return }
        finish(with: printer)
    }
}
