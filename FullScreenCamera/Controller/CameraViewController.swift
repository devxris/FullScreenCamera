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
					view.addGestureRecognizer(toggleCameraSwipeRecognizer)
					view.addGestureRecognizer(zoomInRecognizer)
					view.addGestureRecognizer(zoomOutRecognizer)
					
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
	
	lazy var toggleCameraSwipeRecognizer: UISwipeGestureRecognizer = {
		let recognizer = UISwipeGestureRecognizer()
		recognizer.direction = .up
		recognizer.addTarget(self, action: #selector(toggleCameras(recogizer:)))
		return recognizer
	}()
	
	lazy var zoomInRecognizer: UISwipeGestureRecognizer = {
		let recognizer = UISwipeGestureRecognizer()
		recognizer.direction = .right
		recognizer.addTarget(self, action: #selector(zoomIn(recognier:)))
		return recognizer
	}()
	
	lazy var zoomOutRecognizer: UISwipeGestureRecognizer = {
		let recognizer = UISwipeGestureRecognizer()
		recognizer.direction = .left
		recognizer.addTarget(self, action: #selector(zoomOut(recognier:)))
		return recognizer
	}()
	
	private var toggledCamera = false
	
	@objc func toggleCameras(recogizer: UISwipeGestureRecognizer) {
		
		captureSession.beginConfiguration()
		// Change the device based on the current camera
		currentDevice = toggledCamera ? backCamera : frontCamera
		toggledCamera = !toggledCamera
		
		// Remove all inputs from the session
		captureSession.inputs.forEach { captureSession.removeInput($0) }
		
		// Change to the new input
		do {
			let newInput = try AVCaptureDeviceInput(device: currentDevice!)
			if captureSession.canAddInput(newInput) {
				captureSession.addInput(newInput)
			}
		} catch {
			print(error)
		}
		captureSession.commitConfiguration()
	}
	
	@objc func zoomIn(recognier: UISwipeGestureRecognizer) {
		if let zoomInFactor = currentDevice?.videoZoomFactor {
			if zoomInFactor < 5.0 {
				let newZoomInFactor = min(zoomInFactor + 1.0, 5.0)
				do {
					try currentDevice?.lockForConfiguration()
					currentDevice?.ramp(toVideoZoomFactor: newZoomInFactor, withRate: 1.0)
					currentDevice?.unlockForConfiguration()
				} catch {
					print(error)
				}
			}
		}
	}
	
	@objc func zoomOut(recognier: UISwipeGestureRecognizer) {
		if let zoomOutFactor = currentDevice?.videoZoomFactor {
			if zoomOutFactor > 1.0 {
				let newZoomOutFactor = max(zoomOutFactor - 1.0, 1.0)
				do {
					try currentDevice?.lockForConfiguration()
					currentDevice?.ramp(toVideoZoomFactor: newZoomOutFactor, withRate: 1.0)
					currentDevice?.unlockForConfiguration()
				} catch {
					print(error)
				}
			}
		}
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
