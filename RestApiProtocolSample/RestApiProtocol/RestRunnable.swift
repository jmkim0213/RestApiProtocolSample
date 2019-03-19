//
//  RestRunnable.swift
//  RestApiProtocolSample
//
//  Created by 김정무 on 19/03/2019.
//  Copyright © 2019 김정무. All rights reserved.
//

import Foundation

typealias RestRunnable = () -> ()

func runConcurrent(runnable: @escaping RestRunnable) {
    DispatchQueue(label: "RestConcurrentQueue", qos: .background, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil).async(execute: runnable)
}
