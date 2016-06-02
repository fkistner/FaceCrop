//
//  ImageProcessor.swift
//  FaceCrop
//
//  Created by Florian Kistner on 02/06/16.
//  Copyright © 2016 Florian Kistner. All rights reserved.
//

import Foundation

class ImageProcessor {
    
    static func processImage(imageURL: NSURL, forIndex i: Int) throws {
        var components = imageURL.pathComponents!
        components.removeFirst(inURL.pathComponents!.count)
        let relImageURL = NSURL(fileURLWithPath: NSString.pathWithComponents(components), relativeToURL: outURL)
        let baseImageURL = relImageURL.URLByDeletingPathExtension!
        let fileNameComponents = baseImageURL.lastPathComponent!.componentsSeparatedByString("^")
        let options = fileNameComponents.dropFirst()
        let outImageURL = baseImageURL
            .URLByDeletingLastPathComponent!
            .URLByAppendingPathComponent(fileNameComponents.first!, isDirectory: false)
            .URLByAppendingPathExtension(outFormat)
        //let outLogName = outPath.stringByAppendingPathExtension("log")
        
        var mgIm: MagickImage!
        var cvIm: OpenCVImage!
        
        mgIm = try MagickImage(fromFile: imageURL.path!)
        mgIm.setDepth(16)
        mgIm.convertToColorspace(Colorspace_LAB, ignoreMissingProfile: true)
        
        let size = mgIm.size
        let square = min(size.width, size.height)
        var crop = CGRectMake((size.width - square) / 2, (size.height - square) / 2, square, square)
        
        mgIm.withData { data,cols,rows in
            cvIm = OpenCVImage(data: data, cols: Int32(cols), rows: Int32(rows))
        }
        
        let face = !options.contains("nocrop")
            ? cvIm.faceDetect()
            : CGRectNull
        if face != CGRectNull {
            let th = face.size.height / targetFaceHeight
            let ts = min(th, square)
            
            let fcx = face.origin.x + face.size.width / 2.0
            let fcy = face.origin.y + face.size.height / 2.0
            
            var tx = max((fcx - ts * 0.5),   0.0)
            var ty = max((fcy - ts * 0.556), 0.0)
            tx -= max(tx + ts - size.width,  0.0)
            ty -= max(ty + ts - size.height, 0.0)
            
            crop = CGRectMake(tx, ty, ts, ts)
            
            let posX = numFormat.stringFromNumber(tx / size.width)!
            let posY = numFormat.stringFromNumber(ty / size.height)!
            let ratio = numFormat.stringFromNumber(face.size.height / size.height)!
            print("\(i);\(outImageURL.relativePath!);1;\(posX);\(posY);\(ratio)")
        } else {
            print("\(i);\(outImageURL.relativePath!);-1;0;0;1")
        }
        
        mgIm.crop(crop)
        mgIm.resize(CGSizeMake(800, 800))
        mgIm.withData { data,cols,rows in
            cvIm = OpenCVImage(data: data, cols: Int32(cols), rows: Int32(rows))
        }
        
        let tileSize: CGFloat = 16 // / 800.0 * square
        let clipLimit = 0.5 // / 800 * square
        cvIm.claheWithClipLimit(Double(clipLimit), tileGridSize: CGSizeMake(tileSize, tileSize))
        
        cvIm.withData { data,cols,rows in
            mgIm = MagickImage(data: data, cols: UInt(cols), rows: UInt(rows))
        }
        if (outSize < 800) {
            mgIm.resize(CGSizeMake(CGFloat(outSize), CGFloat(outSize)))
        }
        mgIm.convertToColorspace(Colorspace_sRGB)
        mgIm.setDepth(8)
        
        let specificOutURL = outImageURL.URLByDeletingLastPathComponent!
        try NSFileManager.defaultManager()
            .createDirectoryAtURL(specificOutURL, withIntermediateDirectories: true, attributes: nil)
        try mgIm.writeToFile(outImageURL.path!, withQuality: outQuality)
    }
}