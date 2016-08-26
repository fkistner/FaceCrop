//
//  ImageProcessor.swift
//  FaceCrop
//
//  Created by Florian Kistner on 02/06/16.
//  Copyright © 2016 Florian Kistner. All rights reserved.
//

import Foundation

class ImageProcessor {
    
    static func process(imageURL: URL, outImageURL: URL, forIndex i: Int, withOptions options: ArraySlice<String> = []) throws {
        var mgIm: MagickImage!
        var cvIm: OpenCVImage!
        
        mgIm = try MagickImage(fromFile: imageURL.path!)
        mgIm.setDepth(16)
        mgIm.convert(to: Colorspace_LAB, ignoreMissingProfile: true)
        
        let size = mgIm.size
        let square = min(size.width, size.height)
        var crop = CGRect(x: (size.width - square) / 2, y: (size.height - square) / 2, width: square, height: square)
        
        mgIm.withData { data,cols,rows in
            cvIm = OpenCVImage(data: data, cols: Int32(cols), rows: Int32(rows))
        }
        
        let face = !options.contains("nocrop")
            ? cvIm.faceDetect()
            : CGRect.null
        if face != CGRect.null {
            let th = face.size.height / targetFaceHeight
            let ts = min(th, square)
            
            let fcx = face.origin.x + face.size.width / 2.0
            let fcy = face.origin.y + face.size.height / 2.0
            
            var tx = max((fcx - ts * 0.5),   0.0)
            var ty = max((fcy - ts * 0.556), 0.0)
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
        
        mgIm.crop(crop)
        mgIm.resize(CGSize(width: 800, height: 800))
        mgIm.withData { data,cols,rows in
            cvIm = OpenCVImage(data: data, cols: Int32(cols), rows: Int32(rows))
        }
        
        let tileSize: CGFloat = 16 // / 800.0 * square
        let clipLimit = 0.5 // / 800 * square
        cvIm.clahe(withClipLimit: Double(clipLimit), tileGridSize: CGSize(width: tileSize, height: tileSize))
        
        cvIm.withData { data,cols,rows in
            mgIm = MagickImage(data: data, cols: UInt(cols), rows: UInt(rows))
        }
        if (outSize < 800) {
            mgIm.resize(CGSize(width: CGFloat(outSize), height: CGFloat(outSize)))
        }
        mgIm.convert(to: Colorspace_sRGB)
        mgIm.setDepth(8)
        
        try mgIm.write(toFile: outImageURL.path!, withQuality: outQuality)
    }
}
