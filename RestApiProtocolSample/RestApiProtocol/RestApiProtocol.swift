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
}

extension RestApiProtocol {
    var host: String { return kRestApiURL }
    var url: String { return self.host + self.basePath + self.subPath }
    var uploadFile: RestUploadFile? { return nil }
    
    public func request<R: Decodable>(_ type: R.Type) -> Single<R> {
        self.printFullUrl()
        switch self.method {
        case .multipart:
            return self._upload(type)

        default:
            return self._request(type)
        }
    }
    
    private func _request<R: Decodable>(_ type: R.Type) -> Single<R> {
        return Single<R>.create { observer -> Disposable in
            if let reachabilityManager = NetworkReachabilityManager(), !reachabilityManager.isReachable {
                let error = self.newError(code: -1, message: "네트워크 연결을 확인해주세요.")
                observer(.error(error))
            }
            
            let url = self.url
            let method = HTTPMethod(rawValue: self.method.rawValue) ?? .get
            let parameters = self.params
            
            let request = Alamofire.request(url, method: method, parameters: parameters, encoding: URLEncoding.queryString, headers: nil)
                .validate(statusCode: 200..<300)
                .responseData { response in
                    runConcurrent {
                        do {
                            let responseModel: R = try self.handleResponse(response)
                            observer(.success(responseModel))
                        } catch (let error) {
                            observer(.error(error))
                        }
                    }
                }
            return Disposables.create {
                request.cancel()
            }
        }.observeOn(MainScheduler.instance)
    }
    
    private func _upload<R: Decodable>(_ type: R.Type) -> Single<R> {
        return Single<R>.create { observer -> Disposable in
            var dataRequest: DataRequest?
            
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
                    dataRequest = request
                    request.responseData { response in
                        runConcurrent {
                            do {
                                let responseModel: R = try self.handleResponse(response)
                                observer(.success(responseModel))
                            } catch (let error) {
                                observer(.error(error))
                            }
                        }
                    }
                case .failure(let error):
                    print("encording failure")
                    observer(.error(error))
                }
            })
            return Disposables.create {
                dataRequest?.cancel()
            }
        }
    }

    private func handleResponse<R: Decodable>(_ response: DataResponse<Data>) throws -> R {
        switch response.result {
        case .success:
            if let responseData = response.data {
                let jsonDecoder = JSONDecoder()
                jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
                return try jsonDecoder.decode(R.self, from: responseData)
            } else {
                // Throw error
                throw self.newError(code: -1, message: "서버에서 응답을 받을 수 없습니다.")
            }
        case .failure(let error):
            throw error
        }
    }
    
    private func newError(code: Int, message: String) -> Error {
        return NSError(domain: "RestApiProtocol",
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
