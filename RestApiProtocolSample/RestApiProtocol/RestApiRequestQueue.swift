//
//  RestApiQueue.swift
//  RestApiProtocolSample
//
//  Created by 김정무 on 19/03/2019.
//  Copyright © 2019 김정무. All rights reserved.
//

import Alamofire

public class RestApiQueue {
    private static var queueMap: [String: RestApiQueue] = [:]
    
    public let `id`: String
    
    private var requestMap: [String: DataRequest] = [:]
    
    static let `default`: RestApiQueue = {
        return RestApiQueue("RestApiQueue.default")
    }()
    
    private init(_ id: String) {
        self.id = id
    }
    
    deinit {
        self.removeAll()
    }
    
    public func addRequest(_ id: String, request: DataRequest) {
        self.requestMap[id]?.cancel()
        self.requestMap[id] = request
    }
    
    public func removeRequest(_ id: String) {
        self.requestMap[id]?.cancel()
        self.requestMap[id] = nil
    }
    
    public func removeAll() {
        for (id, request) in self.requestMap {
            request.cancel()
            self.requestMap[id] = nil
        }
    }
}

extension RestApiQueue {
    public static func getQueue(_ id: String) -> RestApiQueue {
        if let queue = RestApiQueue.queueMap[id] {
            return queue
        }
        
        let queue = RestApiQueue(id)
        RestApiQueue.queueMap[id] = queue
        return queue
    }
}
