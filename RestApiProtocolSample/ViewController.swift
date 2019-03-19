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
    private let disposeBag: DisposeBag = DisposeBag()
    @IBOutlet weak var resultLabel: UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()
        iTunesApi.search(keyword: "토스").request(SoftwareListInfo.self, "requestId").bind { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let listInfo):
                self.resultLabel?.text = "\(listInfo.results)"
            case .failure(let error):
                self.resultLabel?.text = "\(error.localizedDescription)"
            case .nothing:
                break
            }
            
        }.disposed(by: self.disposeBag)
    }
}
