//
//  PrintPreviewViewController.swift
//  SKBrotherPrinterWrapper
//
//  Shows exactly what will be printed (QR + details), a red/green connection
//  dot, and a Print button. If no printer is connected, tapping Print opens the
//  search screen first.
//

import UIKit

final class PrintPreviewViewController: UIViewController {

    private let request: PrintRequest
    private let completion: ((Result<Void, PrinterError>) -> Void)?

    private let imageView = UIImageView()
    private let dot = UIView()
    private let statusLabel = UILabel()
    private let printButton = UIButton(type: .system)

    init(request: PrintRequest, completion: ((Result<Void, PrinterError>) -> Void)?) {
        self.request = request
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Print Preview"
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close,
                                                           target: self, action: #selector(closeTapped))
        buildUI()
        renderPreview()

        NotificationCenter.default.addObserver(self, selector: #selector(refreshConnection),
                                               name: PrinterManager.connectionDidChange, object: nil)
        refreshConnection()
    }

    // MARK: - UI

    private func buildUI() {
        // Status row (the red/green dot)
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.layer.cornerRadius = 7
        statusLabel.font = .systemFont(ofSize: 15, weight: .medium)
        let statusRow = UIStackView(arrangedSubviews: [dot, statusLabel])
        statusRow.alignment = .center
        statusRow.spacing = 8
        statusRow.translatesAutoresizingMaskIntoConstraints = false
        let statusTap = UITapGestureRecognizer(target: self, action: #selector(searchTapped))
        statusRow.addGestureRecognizer(statusTap)
        statusRow.isUserInteractionEnabled = true

        // Preview image — shown at the label's true 1.1" x 3.5" proportions,
        // scaled to fit the available space (no scrolling).
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .white
        imageView.layer.borderColor = UIColor.separator.cgColor
        imageView.layer.borderWidth = 1
        imageView.translatesAutoresizingMaskIntoConstraints = false

        // Print button
        printButton.setTitle("Print", for: .normal)
        printButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        printButton.backgroundColor = .systemBlue
        printButton.setTitleColor(.white, for: .normal)
        printButton.layer.cornerRadius = 12
        printButton.translatesAutoresizingMaskIntoConstraints = false
        printButton.addTarget(self, action: #selector(printTapped), for: .touchUpInside)

        view.addSubview(statusRow)
        view.addSubview(imageView)
        view.addSubview(printButton)

        // The label's true aspect ratio (width / height), e.g. 306 / 991.
        let paper = PrinterManager.shared.configuration.paper
        let aspect = paper.printableWidthPx / (paper.printableHeightPx ?? paper.printableWidthPx)

        let guide = view.safeAreaLayoutGuide

        // Fill the available height; let width follow the aspect ratio. Lowered
        // priority so it can shrink to honour the width/height bounds.
        let fillHeight = imageView.heightAnchor.constraint(equalTo: guide.heightAnchor)
        fillHeight.priority = .defaultHigh

        NSLayoutConstraint.activate([
            dot.widthAnchor.constraint(equalToConstant: 14),
            dot.heightAnchor.constraint(equalToConstant: 14),

            statusRow.topAnchor.constraint(equalTo: guide.topAnchor, constant: 12),
            statusRow.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),

            // Centered, aspect-locked, fit within the area above the button.
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: aspect),
            imageView.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
            imageView.topAnchor.constraint(greaterThanOrEqualTo: statusRow.bottomAnchor, constant: 16),
            imageView.bottomAnchor.constraint(lessThanOrEqualTo: printButton.topAnchor, constant: -16),
            imageView.centerYAnchor.constraint(equalTo: guide.centerYAnchor),
            imageView.leadingAnchor.constraint(greaterThanOrEqualTo: guide.leadingAnchor, constant: 16),
            imageView.trailingAnchor.constraint(lessThanOrEqualTo: guide.trailingAnchor, constant: -16),
            fillHeight,

            printButton.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
            printButton.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),
            printButton.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -16),
            printButton.heightAnchor.constraint(equalToConstant: 52)
        ])
    }

    private func renderPreview() {
        imageView.image = LabelFormatter().makeLabelImage(for: request,
                                                          paper: PrinterManager.shared.configuration.paper)
    }

    // MARK: - Actions

    @objc private func refreshConnection() {
        let connected = PrinterManager.shared.isConnected
        dot.backgroundColor = connected ? .systemGreen : .systemRed
        statusLabel.text = connected
            ? (PrinterManager.shared.connectedPrinter?.displayName ?? "Connected")
            : "No printer – tap to search"
        printButton.setTitle(connected ? "Print" : "Connect & Print", for: .normal)
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func searchTapped() {
        PrinterManager.shared.searchPrinter(from: self)
    }

    @objc private func printTapped() {
        guard PrinterManager.shared.isConnected else {
            PrinterManager.shared.searchPrinter(from: self)
            return
        }

        let loading = LoadingView.show(in: view, message: "Printing…")
        PrinterManager.shared.performPrint(request: request) { [weak self] result in
            loading.hide()
            guard let self = self else { return }
            switch result {
            case .success:
                self.showResult(title: "Printed", message: "The label was sent to the printer.", dismissAfter: true)
            case .failure(let error):
                self.showResult(title: "Print Failed",
                                message: error.errorDescription ?? "Unknown error",
                                dismissAfter: false)
            }
            self.completion?(result)
        }
    }

    private func showResult(title: String, message: String, dismissAfter: Bool) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            if dismissAfter { self?.dismiss(animated: true) }
        })
        present(alert, animated: true)
    }
}
