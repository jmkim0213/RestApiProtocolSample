//
//  ViewController.swift
//  RestApiProtocolSample
//
//  Created by 김정무 on 19/03/2019.
//  Copyright © 2019 김정무. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {
    @IBOutlet weak var resultLabel: UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        iTunesApi.search(keyword: "토스").request(SoftwareListInfo.self) { progress in
            print("totalUnitCount!: \(progress.totalUnitCount)")
            print("completedUnitCount!: \(progress.completedUnitCount)")
        }.subscribe(onSuccess: { [weak self] listInfo in
            guard let self = self else { return }            
            self.resultLabel?.text = "\(listInfo.results)"

        }) { [weak self] (error) in
            self?.resultLabel?.text = error.localizedDescription
        }.ignoreDisposed()
    }
}
