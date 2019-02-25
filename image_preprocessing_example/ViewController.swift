//
//  ViewController.swift
//  image_preprocessing_example
//
//  Created by 이대승 on 2019. 2. 4..
//  Copyright © 2019년 이대승. All rights reserved.
//

import UIKit
import SocketIO
import AVKit

class ViewController: UIViewController {
    let picker = UIImagePickerController()
    var processing = false
    
    let manager = SocketManager(socketURL: URL(string: "http://166.104.248.216:5000")!, config: [.log(true), .compress])
    lazy var socket = manager.defaultSocket
    
    override func viewDidLoad() {
        super.viewDidLoad()
        picker.delegate = self
        socket.on("active") {data, ack in
            guard let classname = data[0] as? String else {return}
            self.Result.text = classname
            print(1)
            self.processing = true
            print(2)
        }
    }
    @IBOutlet weak var testImage: UIImageView!
    
    @IBOutlet weak var Result: UITextView!
    
    @IBAction func addAction(_ sender: Any) {
        let alert =  UIAlertController(title: "원하는 타이틀", message: "원하는 메세지", preferredStyle: .actionSheet)
        
        let library =  UIAlertAction(title: "사진앨범", style: .default) { (action) in self.openLibrary()
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
    
    @IBAction func serverConnect(_ sender: Any) {
        socket.connect()
    }
    
    @IBAction func cameraStartButton(_ sender: Any) {
        self.initializeCaptureSession()
    }
    
    func openLibrary(){
        picker.sourceType = .photoLibrary
        present(picker, animated: false, completion: nil)
    }
    
    func openCamera(){
        picker.sourceType = .camera
        present(picker, animated: false, completion: nil)
    }
    
    func initializeCaptureSession(){
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {return}
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {return}
        captureSession.addInput(input)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
 
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
        captureSession.startRunning()
     }
}


extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return  }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return  }
        
        let image = UIImage(cgImage: cgImage)
        let newimage = resizeImage(image: image, targetSize: CGSize(width: 224.0, height: 224.0))
        // self.testImage.image = newimage
        // let imageData = UIImagePNGRepresentation(image) as! NSData
        
        let imageData = UIImagePNGRepresentation(newimage)
        let base64image = imageData?.base64EncodedData()
        
        socket.on("result") {data, ack in
            guard let classname = data[0] as? String else {return}
            self.Result.text = classname
            self.processing = true
        }
        
        if self.processing {
            socket.emit("images", base64image!)
            self.processing = false
        }
        
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect.init(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}

extension ViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage{
            socket.emit("test", "test message")
            let newimage = resizeimage(image: image, targetSize: CGSize(width: 224.0, height: 224.0))
            self.testImage.image = newimage
            let imageData = UIImagePNGRepresentation(newimage)
            let base64image = imageData?.base64EncodedData()
            socket.emit("images", base64image!)
        }
        
        dismiss(animated: true, completion: nil)
        
    }
    
    func resizeimage(image: UIImage, targetSize: CGSize) -> UIImage {
        
        //var newSize: CGSize
        //newSize = CGSize(width: targetSize.width, height: targetSize.height)
        
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect.init(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}
