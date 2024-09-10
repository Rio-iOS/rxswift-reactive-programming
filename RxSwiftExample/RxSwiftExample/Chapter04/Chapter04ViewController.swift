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
    @IBOutlet private weak var saveButton: UIButton!
    @IBOutlet private weak var clearButton: UIButton!
    @IBOutlet private weak var itemAddButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }
    
    @IBAction func actionClear(_ sender: Any) {
        images.accept([])
    }
    
    @IBAction func actionSave(_ sender: Any) {
        guard let image = imageView.image else {
            return
        }
        
//        Chapter04PhotoWriter
//            .save(image)
//            .asSingle()
//            .subscribe(
//                with: self,
//                onSuccess: { owner, id in
//                    owner.showMessage("Saved with id: \(id)")
//                    owner.actionClear()
//                },
//                onFailure: { owner, error in
//                    owner.showMessage("Error", description: error.localizedDescription)
//                }
//            )
//            .disposed(by: disposeBag)
        
        Chapter04PhotoWriter
            .save(image)
            .subscribe(
                with: self,
                onSuccess: { owner, id in
                    owner.showMessage("Saved with id: \(id)")
                    owner.actionClear()
                },
                onFailure: { owner, error in
                    owner.showMessage("Error", description: error.localizedDescription)
                }
            )
            .disposed(by: disposeBag)
        
    }
    
    @IBAction func actionAdd(_ sender: Any) {
//        let newImages = images.value + [UIImage(named: "IMG_1907.jpg")!]
//        images.accept(newImages)
        
        let photosViewController = Chapter04PhotosViewController()
        
        photosViewController
            .selectedImages
            .subscribe(
                with: self,
                onNext: { owner, image in
                    owner.images.accept(owner.images.value + [image])
                },
                onDisposed: { _ in
                    print("Cmpleted photo selection")
                }
            )
            .disposed(by: disposeBag)
        
        navigationController?.pushViewController(photosViewController, animated: true)
    }
}

private extension Chapter04ViewController {
    func showMessage(_ title: String, description: String? = nil) {
//        let alert = UIAlertController(
//            title: title,
//            message: description,
//            preferredStyle: .alert
//        )
//        
//        alert.addAction(
//            .init(
//                title: "Close",
//                style: .default,
//                handler: { [weak self] _ in
//                    self?.dismiss(animated: true, completion: nil)
//                }
//            )
//        )
//        
//        present(alert, animated: true)
        
        // challenge2
        alert(title, description: description)
            .subscribe()
            .disposed(by: disposeBag)
    }
   
    // challenge2
    func alert(_ title: String, description: String? = nil) -> Completable {
        return Completable.create { observer in
            let alert = UIAlertController(
                title: title,
                message: description,
                preferredStyle: .alert
            )
            
            alert.addAction(
                .init(
                    title: "Close",
                    style: .default,
                    handler: { _ in
                        observer(.completed)
                    }
                )
            )
            
            self.present(alert, animated: true)
           
            // disposeされた際にアラートが閉じることが保障される
            return Disposables.create {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }

    func bind() {
        images
            .subscribe(with: self, onNext: { owner, images in
                owner.imageView.image = images.collage(size: owner.imageView.frame.size)
                owner.updateUI(images: images)
            })
            .disposed(by: disposeBag)
    }
    
    func updateUI(images: [UIImage]) {
        saveButton.isEnabled = (images.count > 0) && (images.count % 2 == 0)
        clearButton.isEnabled = images.count > 0
        itemAddButton.isEnabled = images.count < 6
        title = images.count > 0 ? "\(images.count) photos" : "Collage"
    }
    
    func actionClear() {
        images.accept([])
    }
}
