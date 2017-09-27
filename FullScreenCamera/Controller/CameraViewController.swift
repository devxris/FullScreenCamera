//
//  CameraViewController.swift
//  FullScreenCamera
//
//  Created by Chris Huang on 27/09/2017.
//  Copyright © 2017 Chris Huang. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {

	@IBOutlet weak var cameraButton: UIButton!
	
	// Configure AVCaptureSession
	lazy var captureSession: AVCaptureSession = {
		let capture = AVCaptureSession()
		// Preset the session for taking photo in full resolution
		capture.sessionPreset = AVCaptureSession.Preset.photo
		return capture
	}()
	
	// Input Devices, a physical device is abstracted by an AVCaptureDevice
	var backCamera: AVCaptureDevice?
	var frontCamera: AVCaptureDevice?
	var currentDevice: AVCaptureDevice?
	
	// Output Image
	var stillImageOutput = AVCapturePhotoOutput()
	var stillImage: UIImage?
	
	// Creating a Preview Layer
	var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Selecting input device
		backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
		frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
		currentDevice = backCamera // default using back camera
		
		do {
			// Initialize AVCaptureDeviceInput
			let captureDeviceInput = try AVCaptureDeviceInput(device: currentDevice!)
			
			// Add AVCaptureDeviceInput to captureSession
			if captureSession.canAddInput(captureDeviceInput) {
				captureSession.addInput(captureDeviceInput)
				
				// Add AVCaptureDeviceOutput to captureSession
				if captureSession.canAddOutput(stillImageOutput) {
					captureSession.addOutput(stillImageOutput)
					
					// Configure camera preview layer
					cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
					view.layer.addSublayer(cameraPreviewLayer!)
					cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
					cameraPreviewLayer?.frame = view.layer.frame
					
					// Bring the camera button to front
					view.bringSubview(toFront: cameraButton)
					
					// start captureSession
					captureSession.startRunning()
				} else {
					print("captureSession can't add output")
				}
			} else {
				print("captureSession can't add input")
			}
		} catch {
			print(error)
		}
	}
	
	@IBAction func capture(_ sender: UIButton) {
		let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
		stillImageOutput.capturePhoto(with: settings, delegate: self)
	}
	
	@IBAction func unwind(segue: UIStoryboardSegue) { dismiss(animated: true, completion: nil) }
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "ShowPhoto" {
			guard let photoViewController = segue.destination as? PhotoViewController else { return }
			photoViewController.image = stillImage
		}
	}
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {

	func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
		if let error = error { print(error.localizedDescription) }
		guard let imageData = photo.fileDataRepresentation() else { return }
		stillImage = UIImage(data: imageData)
		performSegue(withIdentifier: "ShowPhoto", sender: self)
	}
}
