//
//  Workflow.swift
//  FaceCrop
//
//  Created by Florian Kistner on 04/08/16.
//  Copyright © 2016 Florian Kistner. All rights reserved.
//

class Workflow {
    class func determineAction(imageURL: NSURL) -> (imageURL: NSURL, outImageURL: NSURL, options: ArraySlice<String>) {
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
        
        return (imageURL: imageURL, outImageURL: outImageURL, options: options)
    }
}