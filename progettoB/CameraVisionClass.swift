//
//  CameraVisionClass.swift
//  progettoB
//
//  Created by Stefano Palumbo on 15/05/21.
//

import Foundation
import AVKit
import Vision

class CameraVisionClass: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let captureSession = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    var resultsCount = 0 {
        didSet {
            if(Date() - time > 15){
                if(resultsCount > 15){player?.reduceScore()}
                time = Date()
            }
        }
    }
    var player: Delegate?
    var timer: Timer?
    var time = Date()
    let model = try! VNCoreMLModel(for: CNNEmotions().model)

    func openCam() {
        switch AVCaptureDevice.authorizationStatus(for: .video){
        case .authorized:
            self.addCameraInput()
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                if granted {
                    print("Access to camera Granted")
                    DispatchQueue.main.async {self.addCameraInput()}
                } else {
                    print("Access Denied")
                    self.handleDismiss()
                }
            }
            
        case .denied:
            print("Access was already Denied")
            self.handleDismiss()
            
        case .restricted:
            print("Access was restricted")
            self.handleDismiss()
            
        default:
            print("an Error Occurred")
            self.handleDismiss()
        }
    }
    
    func handleDismiss(){   }
    
    private func addCameraInput() {
        guard let device = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
                mediaType: .video,
                position: .front).devices.first else {
            fatalError("No back camera device found, please make sure to run the app in an iOS device and not a simulator")
        }
        
        timer = Timer(timeInterval: 15, repeats: true) { _ in
            if(self.resultsCount > 2){self.player?.reduceScore()}
            print("Prova ciao")
            self.resultsCount = 0
        }
        
        let cameraInput = try! AVCaptureDeviceInput(device: device)
        print("\(cameraInput.device.activeVideoMaxFrameDuration)")
        self.captureSession.addInput(cameraInput)
        try! device.lockForConfiguration()
        device.activeVideoMaxFrameDuration = CMTimeMake(value: Int64(1), timescale: Int32(2))
        device.activeVideoMinFrameDuration = CMTimeMake(value: Int64(1), timescale: Int32(2))
        device.unlockForConfiguration()
    }
    
    func getCameraFrames() {
        self.videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
        self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))
        self.captureSession.addOutput(self.videoDataOutput)
        guard let connection = self.videoDataOutput.connection(with: AVMediaType.video),
              connection.isVideoOrientationSupported else { return }
        connection.videoOrientation = .portrait
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        connection.videoOrientation = AVCaptureVideoOrientation.portrait
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            debugPrint("unable to get image from sample buffer")
            return
        }
        let ciimage : CIImage = CIImage(cvPixelBuffer: frame)
        let image : UIImage = self.convert(cmage: ciimage)
        self.classification(for: image, complete: {comp in
            if let comp = comp, comp == "Happy" || comp == "Surprise" {
                self.resultsCount += 1
                print("Appended")
                print(self.resultsCount)
            }
        })
    }
    
    
    
    func convert(cmage:CIImage) -> UIImage {
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage)
        return image
    }
    
    
    func classification(for image: UIImage, complete: @escaping (String?) -> Void){
        let request = VNCoreMLRequest(model: self.model){(request,error) in
            guard error == nil else {complete("Error"); return}
            guard let results = request.results as? [VNClassificationObservation], let firstResult = results.first else{complete("No Results"); return}
            if(firstResult.confidence > 0.92){print(firstResult.identifier); complete(String(firstResult.identifier))}
            else {complete(nil)}
        }
        request.imageCropAndScaleOption = .centerCrop
        
        guard let ciImage = CIImage(image: image) else {complete("error creating image"); return}
        let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue))
        
        
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation!)
            do {
                try handler.perform([request])
                
            } catch {
                complete("Failed to perform classification.")
            }
        }
    }
}
