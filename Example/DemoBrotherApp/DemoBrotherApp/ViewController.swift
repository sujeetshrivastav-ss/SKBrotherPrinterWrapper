//
//  ViewController.swift
//  DemoBrotherApp
//
//  Created by Sujeet Shrivastav on 30/06/26.
//

import UIKit
import SKBrotherPrinterWrapper

class ViewController: UIViewController {

    @IBOutlet weak var qrImageView: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var printButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(
                 self,
                 selector: #selector(connectionChanged),
                 name: PrinterManager.connectionDidChange,
                 object: nil
             )
    }
    
    @objc private func connectionChanged() {
        updateDot()
    }
    
    private func updateDot() {
        statusLabel.text = PrinterManager.shared.isConnected ? "Connected" : "Not Connected"
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @IBAction func connectTapped(_ sender: Any) {
        selectPrinterButtonDidTap()
    }
    
    @IBAction func printTapped(_ sender: Any) {
        let qrImage = UIImage(named: "qr")!
        qrImageView.image = qrImage
        
        let request = PrintRequest(barcodeImage: qrImage,
                                   name: "Naimil Gadani",
                                   address: "Test Address",
                                   precinct: "0001",
                                   ballotStyle: "01",
                                   electionCode: "CAGE",
                                   pollCode: "SRD001C")
    
        PrinterManager.shared.print(request: request, from: self) { result in
            print(result)
        }
    }
    
}

private extension ViewController {
    func selectPrinterButtonDidTap() {
        PrinterManager.shared.searchPrinter(from: self)
    }
}

