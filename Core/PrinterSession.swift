//
//  PrinterSession.swift
//  BrotherPrinterWrapper
//
//  Holds the connected printer for the whole app. The red/green dot reads
//  `isConnected`; observe `didChangeNotification` to repaint it.
//

import Foundation

final class PrinterSession {

    static let shared = PrinterSession()
    private init() {}

    /// Posted on the main thread whenever the connection changes.
    static let didChangeNotification = Notification.Name("BrotherPrinterWrapper.sessionDidChange")

    private(set) var connectedPrinter: PrinterInfo?

    var isConnected: Bool { connectedPrinter != nil }

    func setConnected(_ printer: PrinterInfo) {
        connectedPrinter = printer
        PrinterLogger.log("Connected printer stored: \(printer.displayName) @ \(printer.ipAddress)")
        notifyChanged()
    }

    func clear() {
        connectedPrinter = nil
        notifyChanged()
    }

    private func notifyChanged() {
        if Thread.isMainThread {
            NotificationCenter.default.post(name: PrinterSession.didChangeNotification, object: nil)
        } else {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: PrinterSession.didChangeNotification, object: nil)
            }
        }
    }
}
