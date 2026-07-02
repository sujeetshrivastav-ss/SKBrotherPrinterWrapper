//
//  PrinterInfo.swift
//  BrotherPrinterWrapper
//
//  A discovered printer. Only the data we need to reconnect later (the IP
//  address) is kept, exactly like the reference SDK which rebuilds a fresh
//  channel from the stored `channelInfo` each time it prints.
//

import Foundation

public struct PrinterInfo: Equatable {

    /// Human readable model, e.g. "Brother QL-820NWB".
    public let modelName: String
    /// Wi-Fi IP address used to open the channel.
    public let ipAddress: String
    public let serialNumber: String?

    public init(modelName: String, ipAddress: String, serialNumber: String? = nil) {
        self.modelName = modelName
        self.ipAddress = ipAddress
        self.serialNumber = serialNumber
    }

    /// What to show in a list / status label.
    public var displayName: String {
        modelName.isEmpty ? ipAddress : modelName
    }

    public static func == (lhs: PrinterInfo, rhs: PrinterInfo) -> Bool {
        lhs.ipAddress == rhs.ipAddress
    }
}
