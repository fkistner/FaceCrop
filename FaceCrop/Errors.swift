//
//  Errors.swift
//  FaceCrop
//
//  Created by Florian Kistner on 13/05/16.
//  Copyright © 2016 Florian Kistner. All rights reserved.
//

import Foundation

public enum ErrorCode: Int {
    case Exception
}

public class ExceptionError: NSError {
    public let ErrorDomain = "OrgChartGen"
    
    init(info dict: [String: String]?) {
        super.init(domain: ErrorDomain, code: ErrorCode.Exception.rawValue, userInfo: dict)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
