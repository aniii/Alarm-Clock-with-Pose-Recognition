//
//  YogaPoseViewController.swift
//  smart-alarm
//
//  Created by Peter Sun
//  Copyright © 2022 Peter Sun. All rights reserved.
//

import UIKit
import AVFoundation
import SwiftUI

class YogaPoseViewController: UIViewController   {
    
    //@IBOutlet weak var faceLabel: UILabel!
    
    var facialExpression:(Bool, Bool, Bool)? {
        didSet{
            DispatchQueue.main.async {
                
                //self.faceLabel.text = "\(self.facialExpression!.0 ? "[smiling]":"") \(self.facialExpression!.1 ? "[left blink]":"") \(self.facialExpression!.1 ? "[right blink]":"")"
                print("\(self.facialExpression!.0 ? "[smiling]":"") \(self.facialExpression!.1 ? "[left blink]":"") \(self.facialExpression!.1 ? "[right blink]":"")")
                
            }
        }
    }
    //MARK: Class Properties
    var filters : [CIFilter]! = nil
    lazy var videoManager:VideoAnalgesic! = {
        let tmpManager = VideoAnalgesic(mainView: self.view)
        tmpManager.setCameraPosition(position: .back)
        return tmpManager
    }()
    
    lazy var detector:CIDetector! = {
        // create dictionary for face detection
        // HINT: you need to manipulate these properties for better face detection efficiency
        let optsDetector = [CIDetectorAccuracy:CIDetectorAccuracyHigh,
                            CIDetectorTracking:true,
                            CIDetectorMaxFeatureCount: 255] as [String : Any]
        
        // setup a face detector in swift
        let detector = CIDetector(ofType: CIDetectorTypeFace,
                                  context: self.videoManager.getCIContext(), // perform on the GPU is possible
                                  options: (optsDetector as [String : AnyObject]))
        
        return detector
    }()
    
    //MARK: ViewController Hierarchy
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // no background needed
        self.view.backgroundColor = nil
        self.setupFilters()
        
        self.videoManager.setCameraPosition(position: .front)
        self.videoManager.setProcessingBlock(newProcessBlock: self.processImage)
        
        if !videoManager.isRunning{
            videoManager.start()
        }
        
    }
    
    //MARK: Setup filtering
    func setupFilters(){
        filters = []
        
        //filters.append(CIFilter(name:"CIGaussianBlur")!)
        //filters.append(CIFilter(name:"CICrop")!)
        //filters.append(CIFilter(name: "CIAdditionCompositing")!)
    }
    
    //MARK: Apply filters and apply feature detectors
    func applyFiltersToFaces(inputImage:CIImage,features:[CIFaceFeature])->CIImage{
        var retImage = inputImage
        
        for f in features { // for each face
            
            self.facialExpression = (f.hasSmile, f.leftEyeClosed, f.rightEyeClosed)
            if f.hasSmile {
                print("SMILLING")
                AlarmModel.shared.audioPlayer?.stop()
                videoManager.shutdown()
                DispatchQueue.main.async {
                    self.dismiss(animated: true)
                }
                
            }
        }
        
        return retImage
    }
    
    func getFaces(img:CIImage) -> [CIFaceFeature]{
        // this ungodly mess makes sure the image is the correct orientation
        let optsFace = [CIDetectorImageOrientation:self.videoManager.ciOrientation,
                                   CIDetectorSmile: true,
                                CIDetectorEyeBlink: true] as [String: Any]
        // get Face Features
        return self.detector.features(in: img, options: optsFace) as! [CIFaceFeature]
        
    }
    
    //MARK: Process image output
    func processImage(inputImage:CIImage) -> CIImage{
        
        // detect faces
        let faces = getFaces(img: inputImage)
        
        // if no faces, just return original image
        if faces.count == 0 { return inputImage }
        
        //otherwise apply the filters to the faces
        return applyFiltersToFaces(inputImage: inputImage, features: faces)
    }
    
    
    
    
}

