//
//  main.swift
//  FaceCrop
//
//  Created by Florian Kistner on 12/05/16.
//  Copyright © 2016 Florian Kistner. All rights reserved.
//

import Foundation

let (inURL, outURL, outFormat, outSize, outQuality) = { () -> (URL, URL, String, Int, Float) in
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
        let inURL = URL(fileURLWithPath: (Process.arguments[1] as NSString).expandingTildeInPath, isDirectory: true)
        let outURL = URL(fileURLWithPath: (Process.arguments[2] as NSString).expandingTildeInPath, isDirectory: true)
        return (inURL, outURL, outFormat ?? "jpg", outSize ?? 800, outQuality ?? 0.95)
    default:
        print("Usage: \(Process.arguments[0]) inPath outPath [outFormat] [outSize] [outQuality]")
        exit(-1)
    }
}()

let numFormat = NumberFormatter()
numFormat.numberStyle = .decimal
numFormat.localizesFormat = true

let targetFaceHeight: CGFloat = 0.618

let imageURLEnumerator = FileManager.default()
    .enumerator(at: inURL, includingPropertiesForKeys: [URLResourceKey.isDirectoryKey.rawValue], options: .skipsHiddenFiles, errorHandler: nil)

let actions = imageURLEnumerator?.reduce([(imageURL: URL, outImageURL: URL, options: ArraySlice<String>)]()) { actions,imageURL in
    if let imageURL = imageURL as? URL where !imageURL.hasDirectoryPath {
        let action = Workflow.determineAction(imageURL)
        
        let specificOutURL = try! action.outImageURL.deletingLastPathComponent()
        try! FileManager.default()
            .createDirectory(at: specificOutURL, withIntermediateDirectories: true, attributes: nil)
        
        var newActions = actions
        newActions.append(action)
        return newActions
    }
    return actions
} ?? []

print("\(actions.count) pictures:")

DispatchQueue.global(attributes: .qosUtility).apply(applier: actions.count) { i in
    autoreleasepool {
        try! ImageProcessor.process(imageURL: actions[i].imageURL, outImageURL: actions[i].outImageURL, forIndex: i, withOptions: actions[i].options)
    }
}

print("Success")
