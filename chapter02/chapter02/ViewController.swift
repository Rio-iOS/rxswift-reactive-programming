//
//  ViewController.swift
//  chapter02
//
//  Created by 藤門莉生 on 2024/09/01.
//

import UIKit
import RxSwift

final class ViewController: UIViewController {
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        exampleRxSwift()
    }
}

private extension ViewController {
    func exampleRxSwift() {
        print("✅ \(#function)")
        let observable = Observable<Int>.of(1, 2, 3, 4, 5)
        observable
            .map { $0 + 10 }
            .subscribe(with: self) { owner, number in
                print("✅ \(number)")
            }
            .disposed(by: disposeBag)
    }
}
