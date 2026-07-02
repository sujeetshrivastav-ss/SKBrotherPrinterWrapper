//
//  LabelView.swift
//  BrotherPrinterWrapper
//
//  The visual layout of a label: QR code on top, details underneath. The same
//  view is used both for the on-screen preview and for rendering the bitmap
//  that is sent to the printer, so what you see is what you print.
//

import UIKit

final class LabelView: UIView {

    init(request: PrintRequest, widthPx: CGFloat) {
        super.init(frame: CGRect(x: 0, y: 0, width: widthPx, height: 100))
        backgroundColor = .white
        build(request: request, widthPx: widthPx)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func build(request: PrintRequest, widthPx: CGFloat) {
        let inset: CGFloat = 16
        let contentWidth = widthPx - inset * 2

        // Barcode / QR. Use the image you supplied; otherwise generate a QR
        // from the string. Aspect ratio is preserved so wide 1D barcodes and
        // square QR codes both look correct.
        let codeImage = request.barcodeImage ?? request.barcode.flatMap { QRCodeGenerator.generate(from: $0) }
        let qrImageView = UIImageView(image: codeImage)
        qrImageView.contentMode = .scaleAspectFit
        qrImageView.translatesAutoresizingMaskIntoConstraints = false
        if let size = codeImage?.size, size.width > 0 {
            let aspect = size.height / size.width
            // Square-ish codes (QR) are capped so they don't dominate the label;
            // wide codes (1D barcodes) span the full content width.
            let targetWidth = aspect > 0.8 ? min(contentWidth, 260) : contentWidth
            qrImageView.widthAnchor.constraint(equalToConstant: targetWidth).isActive = true
            qrImageView.heightAnchor.constraint(equalTo: qrImageView.widthAnchor,
                                                multiplier: aspect).isActive = true
        }

        // Text
        let nameLabel     = makeLabel(request.name, font: .boldSystemFont(ofSize: 30), width: contentWidth)
        let addressLabel  = makeLabel(request.address, font: .systemFont(ofSize: 22), width: contentWidth)
        let precinctLabel = makeLabel("Precinct: \(request.precinct)", font: .systemFont(ofSize: 22), width: contentWidth)
        let ballotLabel   = makeLabel("Ballot Style: \(request.ballotStyle)", font: .systemFont(ofSize: 22), width: contentWidth)

        var arranged: [UIView] = [qrImageView, nameLabel, addressLabel, precinctLabel, ballotLabel]

        // Footer: election code | poll code | time, on one pipe-separated line.
        let footer = request.footerLine
        if !footer.isEmpty {
            arranged.append(makeLabel(footer, font: .systemFont(ofSize: 18), width: contentWidth))
        }

        let stack = UIStackView(arrangedSubviews: arranged)
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: inset),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset)
        ])

        // Size the view to fit its content at the fixed width.
        let fitting = systemLayoutSizeFitting(
            CGSize(width: widthPx, height: 0),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        frame = CGRect(x: 0, y: 0, width: widthPx, height: ceil(fitting.height))
        layoutIfNeeded()
    }

    private func makeLabel(_ text: String, font: UIFont, width: CGFloat) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = .black
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.widthAnchor.constraint(equalToConstant: width).isActive = true
        return label
    }
}
