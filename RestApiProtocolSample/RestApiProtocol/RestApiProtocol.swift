//
//  RestApiProtocol.swift
//  RestApiProtocolSample
//
//  Created by 김정무 on 19/03/2019.
//  Copyright © 2019 김정무. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import Alamofire

#if DEBUG
private let kRestApiURL = "https://itunes.apple.com"
#else
private let kRestApiURL = "https://itunes.apple.com"
#endif

public protocol RestApiProtocol {
    var host        : String { get }
    var basePath    : String { get }
    var subPath     : String { get }
    var method      : RestMethod { get }
    var params      : [String:String] { get }
    var uploadFile  : RestUploadFile? { get }
    var url         : String { get }
    var apiQueue    : RestApiQueue { get }
}

extension RestApiProtocol {
    var host: String { return kRestApiURL }
    var url: String { return self.host + self.basePath + self.subPath }
    var uploadFile: RestUploadFile? { return nil }
    var apiQueue: RestApiQueue { return RestApiQueue.default }
    
    public func request<R>(_ type: R.Type, _ requestId: String? = nil) -> Observable<RestResult<R>> {
        self.printFullUrl()
        
        let responseRelay = PublishRelay<RestResult<R>>()
        if let reachabilityManager = NetworkReachabilityManager(), !reachabilityManager.isReachable {
            responseRelay.accept(.failure(self.newError(code: -1, message: "네트워크 연결을 확인해주세요.")))
        }
        
        if let requestId = requestId {
            self.apiQueue.removeRequest(requestId)
        }
        
        switch self.method {
        case .multipart:
            self._update(type, requestId, responseRelay)
        default:
            self._request(type, requestId, responseRelay)
        }
        return responseRelay.retry(3).take(1).observeOn(MainScheduler.instance)
    }
    
    public func cancel(requestId: String) {
        self.apiQueue.removeRequest(requestId)
    }
    
    private func _request<R>(_ type: R.Type, _ requestId: String?, _ responseRelay: PublishRelay<RestResult<R>>) {
        let url = self.url
        let method = HTTPMethod(rawValue: self.method.rawValue) ?? .get
        let parameters = self.params
        
        let request = Alamofire.request(url, method: method, parameters: parameters, encoding: URLEncoding.queryString, headers: nil)
        .validate(statusCode: 200..<300)
        .responseData { response in runConcurrent { self.handleResponse(response, requestId, responseRelay) } }
        
        if let requestId = requestId {
            self.apiQueue.addRequest(requestId, request: request)
        }
    }
    
    private func _update<R>(_ type: R.Type, _ requestId: String?, _ responseRelay: PublishRelay<RestResult<R>>) {
        Alamofire.upload(multipartFormData: { formData in
            guard let uploadFile = self.uploadFile else { return }
            self.params.forEach {
                guard let data = $0.value.data(using: .utf8) else { return }
                formData.append(data, withName: $0.key)
            }
            formData.append(uploadFile.data, withName: uploadFile.name, fileName: uploadFile.fileName, mimeType: uploadFile.data.mimeType)
        }, to: self.url, encodingCompletion: { result in
            switch result {
            case .success(let request, _, _):
                print("encording success")
                if let requestId = requestId {
                    self.apiQueue.addRequest(requestId, request: request)
                }
                
                request.responseData { response in runConcurrent { self.handleResponse(response, requestId, responseRelay) } }
            case .failure(let error):
                print("encording failure")
                let error = self.newError(code: -100, message: error.localizedDescription)
                responseRelay.accept(.failure(error))
            }
        })
    }
    
    private func handleResponse<R>(_ response: DataResponse<Data>, _ requestId: String?, _ responseRelay: PublishRelay<RestResult<R>>) {
        defer {
            if let requestId = requestId {
                self.apiQueue.removeRequest(requestId)
            }
        }
        
        do {
            switch response.result {
            case .success:
                if let responseData = response.data {
                    let jsonDecoder = JSONDecoder()
                    jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
                    let responseModel = try jsonDecoder.decode(R.self, from: responseData)
                    responseRelay.accept(.success(responseModel))
                } else {
                    // Throw error
                    throw self.newError(code: -1, message: "서버에서 응답을 받을 수 없습니다.")
                }
            case .failure(let error):
                if let response = response.response {
                    throw self.newError(code: response.statusCode, message: "네트워크 에러가 발생했습니다")
                } else {
                    throw error
                }
            }
        } catch let error {
            responseRelay.accept(.failure(error))
        }
    }
    
    private func newError(code: Int, message: String) -> Error {
        return NSError(domain: self.apiQueue.id,
                       code: code,
                       userInfo: [
                        NSLocalizedDescriptionKey: message,
                        NSLocalizedFailureReasonErrorKey: message])
    }
    
    private func printFullUrl() {
        var fullUrl = self.url
        let params = self.params
        if !params.isEmpty {
            fullUrl.append("?")
            params.forEach { fullUrl.append("\($0.key)=\($0.value)&") }
        }
        print("fullUrl: \(fullUrl)")
    }
}
