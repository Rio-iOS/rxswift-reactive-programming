//
//  Chapter04ViewController.swift
//  RxSwiftExample
//
//  Created by 藤門莉生 on 2024/09/08.
//

import Foundation
import UIKit
import RxSwift
import RxRelay

final class Chapter04ViewController: UIViewController {
    private let disposeBag = DisposeBag()
    private let images = BehaviorRelay<[UIImage]>(value: [])
    
    @IBOutlet private weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }
    
    @IBAction func actionClear(_ sender: Any) {
        images.accept([])
    }
    
    @IBAction func actionSave(_ sender: Any) {
    }
    
    @IBAction func actionAdd(_ sender: Any) {
        let newImages = images.value + [UIImage(named: "IMG_1907.jpg")!]
        images.accept(newImages)
    }
}

private extension Chapter04ViewController {
    func showMessage(_ title: String, description: String? = nil) {
        let alert = UIAlertController(
            title: title,
            message: description,
            preferredStyle: .alert
        )
        
        alert.addAction(
            .init(
                title: "Close",
                style: .default,
                handler: { [weak self] _ in
                    self?.dismiss(animated: true, completion: nil)
                }
            )
        )
        
        present(alert, animated: true)
    }
}

private extension Chapter04ViewController {
    func bind() {
        images
            .subscribe(with: self, onNext: { owner, images in
                owner.imageView.image = images.collage(size: owner.imageView.frame.size)
            })
            .disposed(by: disposeBag)
    }
}
