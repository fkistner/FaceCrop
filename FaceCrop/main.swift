//
//  main.swift
//  FaceCrop
//
//  Created by Florian Kistner on 12/05/16.
//  Copyright © 2016 Florian Kistner. All rights reserved.
//

import Foundation

let inPath: String
let outPath: NSString
let outFormat: String

switch Process.arguments.count {
case 3...4:
    inPath = Process.arguments[1]
    outPath = Process.arguments[2]
    outFormat = Process.arguments.count >= 4
        ? Process.arguments[3]
        : "jpg"
    break
default:
    print("Usage: \(Process.arguments[0]) inPath outPath [outFormat]")
    exit(-1)
}

let numFormat = NSNumberFormatter()
numFormat.numberStyle = .DecimalStyle
numFormat.localizesFormat = true

let targetFaceHeight: CGFloat = 0.55

let inURL = NSURL(fileURLWithPath: inPath, isDirectory: true)
let imageURLEnumerator = NSFileManager.defaultManager()
    .enumeratorAtURL(inURL, includingPropertiesForKeys: [NSURLIsDirectoryKey], options: .SkipsHiddenFiles, errorHandler: nil)

let imageURLs = imageURLEnumerator?.reduce([NSURL]()) { imageURLs,imageURL in
    if let imageURL = imageURL as? NSURL where !imageURL.hasDirectoryPath {
        var newImageURLs = imageURLs
        newImageURLs.append(imageURL)
        return newImageURLs
    }
    return imageURLs
} ?? []

print("\(imageURLs.count) pictures:")

let queue = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)

dispatch_apply(imageURLs.count, queue) { i in
    let imageURL = imageURLs[i]
    
    autoreleasepool {
        var components = imageURL.pathComponents!
        components.removeFirst(inURL.pathComponents!.count)
        let fileName: NSString = components.last!
        let baseFileName: NSString = fileName.stringByDeletingPathExtension
        components[components.count - 1] = baseFileName.stringByAppendingPathExtension(outFormat)!
        let outFileName = NSString.pathWithComponents(components)
        //let outLogName = outPath.stringByAppendingPathExtension("log")
        
        var mgIm: MagickImage!
        var cvIm: OpenCVImage!
        
        mgIm = try! MagickImage(fromFile: imageURL.path!)
        mgIm.setDepth(16)
        mgIm.convertToColorspace(Colorspace_LAB, ignoreMissingProfile: true)
        
        let size = mgIm.size
        let square = min(size.width, size.height)
        var crop = CGRectMake((size.width - square) / 2, (size.height - square) / 2, square, square)
        
        mgIm.withData { data,cols,rows in
            cvIm = OpenCVImage(data: data, cols: Int32(cols), rows: Int32(rows))
        }
        
        let face = cvIm.faceDetect()
        if face != CGRectNull {
            let th = face.size.height / targetFaceHeight
            let ts = min(th, square)
            
            let fcx = face.origin.x + face.size.width / 2.0
            let fcy = face.origin.y + face.size.height / 2.0
            
            var tx = max((fcx - ts / 2.0), 0.0)
            var ty = max((fcy - ts / 2.0), 0.0)
            tx -= max(tx + ts - size.width, 0.0)
            ty -= max(ty + ts - size.height, 0.0)
            
            crop = CGRectMake(tx, ty, ts, ts)
            
            let posX = numFormat.stringFromNumber(tx / size.width)!
            let posY = numFormat.stringFromNumber(ty / size.height)!
            let ratio = numFormat.stringFromNumber(face.size.height / size.height)!
            print("\(i);\(outFileName);1;\(posX);\(posY);\(ratio)")
        } else {
            print("\(i);\(outFileName);-1;0;0;1")
        }
        
        mgIm.crop(crop)
        mgIm.resize(CGSizeMake(800, 800))
        mgIm.withData { data,cols,rows in
            cvIm = OpenCVImage(data: data, cols: Int32(cols), rows: Int32(rows))
        }
        
        let tileSize: CGFloat = 8// 16 // / 800.0 * square
        let clipLimit = 1//0.5 // / 800 * square
        cvIm.claheWithClipLimit(Double(clipLimit), tileGridSize: CGSizeMake(tileSize, tileSize))
        
        cvIm.withData { data,cols,rows in
            mgIm = MagickImage(data: data, cols: UInt(cols), rows: UInt(rows))
        }
        //mgIm.resize(CGSizeMake(800, 800))
        mgIm.convertToColorspace(Colorspace_sRGB)
        mgIm.setDepth(8)
        
        let outFile = outPath.stringByAppendingPathComponent(outFileName)
        let specificOutPath = (outFile as NSString).stringByDeletingLastPathComponent
        try! NSFileManager.defaultManager()
            .createDirectoryAtPath(specificOutPath, withIntermediateDirectories: true, attributes: nil)
        try! mgIm.writeToFile(outFile, withQuality: 0.75)
    }
}

print("Success")
