//
//  ImageProcessor.swift
//  FaceCrop
//
//  Created by Florian Kistner on 02/06/16.
//  Copyright © 2016 Florian Kistner. All rights reserved.
//

import Foundation
import CoreImage

class ImageProcessor {
    
    static func process(imageURL: URL, outImageURL: URL, forIndex i: Int, withOptions options: ArraySlice<String> = []) throws {
        let context = CIContext()
        var image = CIImage(contentsOf: imageURL)!
        let detector = CIDetector(ofType: CIDetectorTypeFace, context: context, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])!
        let features = detector.features(in: image) ?? []
        
        let size = image.extent.size
        let square = min(size.width, size.height)
        var crop = CGRect(x: (size.width - square) / 2, y: (size.height - square) / 2, width: square, height: square)
        
        if !options.contains("nocrop"),
            let face = features.first?.bounds {
            let th = face.size.height / targetFaceHeight
            let ts = min(th, square)
            
            let fcx = face.origin.x + face.size.width / 2.0
            let fcy = face.origin.y + face.size.height / 2.0
            
            var tx = max((fcx - ts * 0.5),   0.0)
            var ty = max((fcy - ts * 0.444), 0.0)
            tx -= max(tx + ts - size.width,  0.0)
            ty -= max(ty + ts - size.height, 0.0)
            
            crop = CGRect(x: tx, y: ty, width: ts, height: ts)
            
            let posX = numFormat.string(from: tx / size.width)!
            let posY = numFormat.string(from: ty / size.height)!
            let ratio = numFormat.string(from: face.size.height / size.height)!
            print("\(i);\(outImageURL.relativePath!);1;\(posX);\(posY);\(ratio)")
        } else {
            print("\(i);\(outImageURL.relativePath!);-1;0;0;1")
        }
        
        image = image.cropping(to: crop)
        
        for filter in image.autoAdjustmentFilters(options: [kCIImageAutoAdjustRedEye: false]) {
            filter.setValue(image, forKey: kCIInputImageKey)
            image = filter.outputImage!
        }
        
        let cgimage = context.createCGImage(image, from: image.extent)!
        let destination = CGImageDestinationCreateWithURL(outImageURL, kUTTypeJPEG, 1, nil)!
        let properties: NSDictionary = [kCGImageDestinationLossyCompressionQuality as String: outQuality]
        CGImageDestinationAddImage(destination, cgimage, properties)
        CGImageDestinationFinalize(destination)
    }
}
