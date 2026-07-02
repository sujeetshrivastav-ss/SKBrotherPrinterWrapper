# SKBrotherPrinterWrapper

A small, drop-in UIKit module that wraps the **Brother `BRLMPrinterKit`** SDK so
your app only ever talks to **one class: `PrinterManager`**.

It reuses the exact search / connect / print mechanism from the official
*Brother Print SDK Demo* — just repackaged behind a clean facade.

```
SKBrotherPrinterWrapper
├── Package.swift                      SPM manifest (library + vendored xcframework)
├── BrotherSDK
│   └── BRLMPrinterKit.xcframework     Brother's SDK, vendored as a binary target
└── Sources                            module `SKBrotherPrinterWrapper` (path: "Sources")
    ├── Core
    │   ├── PrinterManager.swift          ⭐ Public API – the only class you use
    │   ├── PrinterSession.swift          singleton holding the connected printer
    │   ├── BrotherPrinterEngine.swift    render → connect → print
    │   ├── NetworkPrinterSearcher.swift  de-duplicating network search
    │   ├── BrotherConfiguration.swift    model / paper / copies / duration
    │   └── PrinterLogger.swift
    ├── Models
    │   ├── PrintRequest.swift            barcode + name + address + precinct + ballotStyle
    │   ├── PrinterInfo.swift
    │   ├── PrinterStatus.swift
    │   ├── PrinterError.swift            user-ready error messages
    │   └── PrinterPaper.swift            label sizes
    ├── Formatter
    │   ├── LabelFormatter.swift          PrintRequest → 1:1 pixel bitmap
    │   ├── QRCodeGenerator.swift
    │   └── LabelView.swift               the on-screen / on-paper layout
    ├── UI
    │   ├── PrinterSearchViewController.swift
    │   ├── PrintPreviewViewController.swift
    │   └── LoadingView.swift
    └── Wrappers
        ├── Wrapper_Search.swift          BRLMPrinterSearcher.startNetworkSearch
        ├── Wrapper_Connect.swift         BRLMPrinterDriverGenerator.open
        └── Wrapper_Print.swift           driver.printImage(with:settings:)
```

## Install (Swift Package Manager)

The Brother `BRLMPrinterKit.xcframework` ships **inside** this package as a binary
target, so you don't link it separately — just add the package.

**Xcode:** File → Add Package Dependencies… → paste the repo URL:

```
https://github.com/sujeetshrivastav-ss/SKBrotherPrinterWrapper.git
```

**Package.swift:**

```swift
dependencies: [
    .package(url: "https://github.com/sujeetshrivastav-ss/SKBrotherPrinterWrapper.git", from: "1.0.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: ["SKBrotherPrinterWrapper"]
    )
]
```

Then in code:

```swift
import SKBrotherPrinterWrapper
```

Requirements: **iOS 14+**.

## Required `Info.plist` keys

Printer discovery uses **Bonjour over the local network**, which iOS gates behind
a permission prompt. Without these keys the search returns **no printers** (and on
iOS 14+ the SDK never even sees the network). Add them to your **app's**
`Info.plist` (the package can't declare them for you):

| Key | Type | Purpose |
|-----|------|---------|
| `NSLocalNetworkUsageDescription` | String | Message shown in the "allow local network access" prompt. |
| `NSBonjourServices` | Array of String | The Bonjour service types used to find printers. |

**Xcode UI:** select your target → **Info** tab → add:
- **Privacy - Local Network Usage Description** → e.g. *"Used to find and connect to your Brother label printer on this network."*
- **Bonjour services** (an Array) with these three items:
  - `_pdl-datastream._tcp`
  - `_printer._tcp`
  - `_ipp._tcp`

**Or paste directly into `Info.plist` (source):**

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Used to find and connect to your Brother label printer on this network.</string>
<key>NSBonjourServices</key>
<array>
    <string>_pdl-datastream._tcp</string>
    <string>_printer._tcp</string>
    <string>_ipp._tcp</string>
</array>
```

> This build is **Wi-Fi / network only** — no Bluetooth. If you later add a
> Bluetooth/BLE searcher, you'll also need `NSBluetoothAlwaysUsageDescription`
> and the MFi `UISupportedExternalAccessoryProtocols` entry
> (`com.brother.ptcbp`); they are **not** required for this network-only setup.

## Use — three calls, that's it

```swift
// 1) Search. Opens a screen, stores the picked printer, flips the dot green.
PrinterManager.shared.searchPrinter(from: self)

// 2) Reflect connection on your red/green dot.
dotView.backgroundColor = PrinterManager.shared.isConnected ? .systemGreen : .systemRed

// Repaint automatically whenever it changes:
NotificationCenter.default.addObserver(
    forName: PrinterManager.connectionDidChange, object: nil, queue: .main
) { [weak self] _ in
    let connected = PrinterManager.shared.isConnected
    self?.dotView.backgroundColor = connected ? .systemGreen : .systemRed
}

// 3) Print. Opens a preview (barcode + details) with a Print button.

// (a) Use the barcode image you already generated in your UIImageView:
let request = PrintRequest(
    barcodeImage: barcodeImageView.image!,   // your pre-rendered barcode/QR
    name: voter.name,
    address: voter.address,
    precinct: voter.precinct,
    ballotStyle: voter.ballotStyle
)
PrinterManager.shared.print(request: request, from: self)

// (b) …or pass a string and let the wrapper draw a QR for you:
let request = PrintRequest(
    barcode: voter.barcode,
    name: voter.name, address: voter.address,
    precinct: voter.precinct, ballotStyle: voter.ballotStyle
)
```

Optional completion handlers are available on both `searchPrinter` and `print`.

## Fixed setup

This build is hard-wired to one configuration — no model picking, no Bluetooth:

- **Printer:** Brother **QL-820NWB**
- **Connection:** **Wi-Fi / network only**
- **Label:** **1.1" × 3.5"** die-cut (29mm × 90mm) → rendered at 306 × 991 px
- **Fields:** Name, Address, Precinct, Ballot Style, Barcode (encoded as a QR code)

Defaults live in `BrotherConfiguration` and rarely need changing, but you can:

```swift
let config = PrinterManager.shared.configuration
config.paper          = .dieCut29x90    // 1.1" x 3.5" (default)
config.numberOfCopies = 1
config.autoCut        = true
```

## How it maps to the reference SDK

| This module          | Reference demo                                   |
|----------------------|--------------------------------------------------|
| `Wrapper_Search`     | `NetPrinterSearcher`                             |
| `Wrapper_Connect`    | `PrinterConnectUtil`                             |
| `Wrapper_Print`      | `PrintImageFacade.printImageWithImage`          |
| `PrinterSession`     | the `savePrinterInfo` delegate flow              |

## "Everything else is private"

Because this ships as its own Swift package (module `SKBrotherPrinterWrapper`),
only the types marked `public` (`PrinterManager`, `PrintRequest`, `PrinterInfo`,
`PrinterError`, `PrinterStatus`, `PrinterPaper`, `BrotherConfiguration`) are
visible to your app. Every other class is module-internal and inaccessible —
**`PrinterManager` is the entry point** you use.

## Notes

- The preview is rendered from the *same* `LabelView` that is printed, so it is
  pixel-accurate. Tweak fonts/spacing in `LabelView.swift`.
- `Barcode` is encoded as a **QR code** (scannable, fits the narrow 29mm label).
  To use a 1D barcode instead, swap the generator call in `LabelView.build(...)`.
- To support other QL labels later, just add a case to `PrinterPaper`.
- This build is network-only by design. Bluetooth/BLE searchers from the
  reference demo can be added as new `Wrapper_Search` variants if ever needed.
```
