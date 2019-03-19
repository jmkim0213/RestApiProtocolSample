//
//  RestApiResult.swift
//  RestApiProtocolSample
//
//  Created by 김정무 on 19/03/2019.
//  Copyright © 2019 김정무. All rights reserved.
//

import Foundation

public enum RestResult<R: Decodable> {
    case success(R)
    case failure(Error)
    case nothing
}
