//
//  LabelFormatter.swift
//  BrotherPrinterWrapper
//
//  Turns a `PrintRequest` into a 1:1 pixel bitmap (no Retina scaling) sized to
//  the loaded paper. For a die-cut label the content is centred on a canvas of
//  the exact label size; for continuous roll the bitmap grows to fit.
//

import UIKit

final class LabelFormatter {

    /// Renders the label as a `UIImage`. Returns `nil` only if drawing fails.
    func makeLabelImage(for request: PrintRequest, paper: PrinterPaper) -> UIImage? {
        let width = paper.printableWidthPx
        let view = LabelView(request: request, widthPx: width)

        // Die-cut => fixed canvas height; continuous => fit content.
        let canvasHeight = paper.printableHeightPx ?? view.bounds.height
        let canvasBounds = CGRect(x: 0, y: 0, width: width, height: canvasHeight)
        let offsetY = max(0, (canvasHeight - view.bounds.height) / 2)   // vertical centring

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1            // 1 point == 1 pixel
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(bounds: canvasBounds, format: format)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(canvasBounds)
            context.cgContext.translateBy(x: 0, y: offsetY)
            view.layer.render(in: context.cgContext)
        }
    }
}
