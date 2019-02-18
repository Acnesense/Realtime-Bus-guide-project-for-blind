//
//  ViewController.swift
//  image_preprocessing_example
//
//  Created by 이대승 on 2019. 2. 4..
//  Copyright © 2019년 이대승. All rights reserved.
//

import UIKit
import SocketIO
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    let picker = UIImagePickerController()
    let manager = SocketManager(socketURL: URL(string: "http://166.104.248.216:5000")!, config: [.log(true), .compress])
    
    lazy var socket = manager.defaultSocket

    
    override func viewDidLoad() {
        picker.delegate = self
        initializeCaptureSession()
        socket.on("result") {data, ack in
            print(data[0])
            self.result.text = data[0] as? String
        }
        
        
    }
    
    func initializeCaptureSession(){
        let captureSession = AVCaptureSession()
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {return}
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {return}
        captureSession.addInput(input)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
     }
    /*
        session.sessionPreset = AVCaptureSession.Preset.high
        camera = AVCaptureDevice.default(for: AVMediaType.video)
        
        do {
            let cameraCaptureInput = try AVCaptureDeviceInput(device: camera!)
            cameraCaptureOutput = AVCapturePhotoOutput()
            
            session.addInput(cameraCaptureInput)
            session.addOutput(cameraCaptureOutput!)
            
        } catch {
            print(error.localizedDescription)
        }
        
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraPreviewLayer?.frame = view.bounds
        cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        
        view.layer.insertSublayer(cameraPreviewLayer!, at: 0)
        
        session.startRunning()
    }
    */
    
    
    @IBOutlet weak var result: UITextView!
    @IBOutlet weak var imageVIew: UIImageView!
    @IBAction func addAction(_ sender: Any) {
        let alert =  UIAlertController(title: "원하는 타이틀", message: "원하는 메세지", preferredStyle: .actionSheet)
        let library =  UIAlertAction(title: "사진앨범", style: .default) { (action) in
            self.openLibrary()
        }
        
        let camera =  UIAlertAction(title: "카메라", style: .default) { (action) in
            self.openCamera()
        }
        let cancel = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        alert.addAction(library)
        alert.addAction(camera)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func connect(_ sender: Any) {
        socket.connect()
    }
    
    @IBAction func message(_ sender: Any) {
        socket.emit("test", "test message")
    }
    
    func openLibrary(){
        picker.sourceType = .photoLibrary
        present(picker, animated: false, completion: nil)
    }
    
    func openCamera(){
        if(UIImagePickerController .isSourceTypeAvailable(.camera)){
            picker.sourceType = .camera
            present(picker, animated: false, completion: nil)
        }
        else{
            print("Camera not available")
        }
    }
}



extension ViewController : UIImagePickerControllerDelegate,
UINavigationControllerDelegate{
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info:[String: Any]){
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage{
            imageVIew.image = image
            let imageData = UIImagePNGRepresentation(image) as NSData?
            let base64encoding = imageData?.base64EncodedString()
            socket.emit("images", base64encoding!)
        }
        dismiss(animated: true, completion: nil)
    }
}
