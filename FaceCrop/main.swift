//
//  main.swift
//  FaceCrop
//
//  Created by Florian Kistner on 12/05/16.
//  Copyright © 2016 Florian Kistner. All rights reserved.
//

import Foundation

let (inPath, outPath, outFormat, outSize, outQuality) = { () -> (String, NSString, String, Int, Float) in
    var outFormat: String?
    var outSize: Int?
    var outQuality: Float?
    switch Process.arguments.count {
    case 6:
        outQuality = Float(Process.arguments[5])
        fallthrough
    case 5:
        outSize = Int(Process.arguments[4])
        fallthrough
    case 4:
        outFormat = Process.arguments[3]
        fallthrough
    case 3:
        return (Process.arguments[1], Process.arguments[2], outFormat ?? "jpg", outSize ?? 800, outQuality ?? 0.95)
    default:
        print("Usage: \(Process.arguments[0]) inPath outPath [outFormat] [outSize] [outQuality]")
        exit(-1)
    }
}()

let numFormat = NSNumberFormatter()
numFormat.numberStyle = .DecimalStyle
numFormat.localizesFormat = true

let targetFaceHeight: CGFloat = 0.618

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
    autoreleasepool {
        try! ImageProcessor.processImage(imageURLs[i], forIndex: i)
    }
}

print("Success")
