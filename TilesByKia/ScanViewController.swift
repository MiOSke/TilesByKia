//
//  ScanViewController.swift
//  TilesByKia
//
//  Created by Michael Kampouris on 5/7/22.
//

import UIKit
import AVFoundation

class ScanViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var cancelImageView: UIImageView!
    @IBOutlet weak var spinnerView: UIActivityIndicatorView!
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var barcode: String = ""
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        setupQRScanner()
    }
    
    @IBAction func dismiss() {
        self.dismiss(animated: true)
    }
    
    
    //MARK: - QR Scanner Methods
    
    func setupQRScanner() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.code128, .code39, .code93, .ean13, .ean8]
        } else {
            failed()
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = self.view.layer.bounds
        previewLayer.frame.origin.x = self.view.frame.origin.x
        previewLayer.frame.origin.y = self.view.frame.origin.y
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        view.bringSubviewToFront(cancelImageView)
        view.bringSubviewToFront(dismissButton)
        view.bringSubviewToFront(spinnerView)
        
        captureSession.startRunning()
    }
    
    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            barcode = stringValue
            found(code: stringValue)
        }
    }
    
    func found(code: String) {
        print(code)
        self.barcode = code
        self.performSegue(withIdentifier: "toItemDetailVC", sender: Any?.self)
    }
    
    func startLoading() {
        DispatchQueue.main.async {
            self.spinnerView.alpha = 1
            self.spinnerView.startAnimating()
        }
    }
    
    func stopLoading() {
        DispatchQueue.main.async {
            self.spinnerView.alpha = 0
            self.spinnerView.stopAnimating()
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toItemDetailVC" {
            guard let destinationVC = segue.destination as? ItemDetailViewController else { return }
            destinationVC.barcode = barcode
        }
    }
    

}

