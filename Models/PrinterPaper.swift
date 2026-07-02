//
//  PrinterPaper.swift
//  BrotherPrinterWrapper
//
//  Label sizes for the QL-820NWB. `dieCut29x90` is the 1.1" x 3.5" label this
//  app uses. Pixel sizes are the printable area at 300 dpi and drive how large
//  the rendered bitmap is.
//

import UIKit
import BRLMPrinterKit

public enum PrinterPaper {
    /// 1.1" x 3.5" die-cut (29mm x 90mm) — the label this app prints.
    case dieCut29x90
    /// 2.4" x 3.9" die-cut (62mm x 100mm).
    case dieCut62x100
    /// 62mm continuous roll (length varies with content).
    case continuous62mm
    /// 54mm continuous film — Brother DK-N5224, non-adhesive (length varies).
    case continuous54mm
    /// 29mm continuous roll (length varies with content).
    case continuous29mm

    /// SDK label size used when building `BRLMQLPrintSettings`.
    var qlLabelSize: BRLMQLPrintSettingsLabelSize {
        switch self {
        case .dieCut29x90:    return .dieCutW29H90
        case .dieCut62x100:   return .dieCutW62H100
        case .continuous62mm: return .rollW62
        case .continuous54mm: return .rollW54
        case .continuous29mm: return .rollW29
        }
    }

    /// Printable width in pixels (~300 dpi) — the dimension across the print head.
    var printableWidthPx: CGFloat {
        switch self {
        case .dieCut29x90, .continuous29mm: return 306   // 29mm
        case .continuous54mm: return 590                 // 54mm (DK-N5224)
        case .dieCut62x100, .continuous62mm: return 696  // 62mm
        }
    }

    /// Fixed printable length in pixels for die-cut labels (`nil` = continuous,
    /// so the bitmap grows to fit the content).
    var printableHeightPx: CGFloat? {
        switch self {
        case .dieCut29x90:  return 991   // 90mm
        case .dieCut62x100: return 1109  // 100mm
        case .continuous62mm, .continuous54mm, .continuous29mm: return nil
        }
    }
}
