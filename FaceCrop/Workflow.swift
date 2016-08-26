//
//  Workflow.swift
//  FaceCrop
//
//  Created by Florian Kistner on 04/08/16.
//  Copyright © 2016 Florian Kistner. All rights reserved.
//

class Workflow {
    class func determineAction(_ imageURL: URL) -> (imageURL: URL, outImageURL: URL, options: ArraySlice<String>) {
        var components = imageURL.pathComponents!
        components.removeFirst(inURL.pathComponents!.count)
        let relImageURL = URL(fileURLWithPath: NSString.path(withComponents: components), relativeTo: outURL as URL)
        let baseImageURL = try! relImageURL.deletingPathExtension()
        let fileNameComponents = baseImageURL.lastPathComponent!.components(separatedBy: "^")
        let options = fileNameComponents.dropFirst()
        let outImageURL = try! baseImageURL.deletingLastPathComponent()
            .appendingPathComponent(fileNameComponents.first!, isDirectory: false)
            .appendingPathExtension(outFormat)
        
        return (imageURL: imageURL, outImageURL: outImageURL, options: options)
    }
}
