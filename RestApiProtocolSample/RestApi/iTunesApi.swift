//
//  iTunesApi.swift
//  RestApiProtocolSample
//
//  Created by 김정무 on 19/03/2019.
//  Copyright © 2019 김정무. All rights reserved.
//

import Foundation

enum iTunesApi {
    case search(keyword: String)
}

extension iTunesApi: RestApiProtocol {
    var basePath: String {
        return ""
    }
    
    var subPath: String {
        switch self {
        case .search:
            return "/search"
        }
    }
    
    var method: RestMethod {
        switch self {
        case .search:
            return .get
        }
    }
    
    var params: [String : String] {
        switch self {
        case .search(let keyword):
            return ["term":keyword, "lang":"ko-kr", "country":"KR", "entity":"software"]
        }
    }
}
