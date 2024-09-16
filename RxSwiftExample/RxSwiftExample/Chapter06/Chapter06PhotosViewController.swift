//
//  Chapter06PhotosViewController.swift
//  RxSwiftExample
//
//  Created by 藤門莉生 on 2024/09/16.
//

import UIKit
import Photos
import RxSwift

final class Chapter06PhotosViewController: UIViewController {
    private let disposeBag = DisposeBag()
    private var collectionView: UICollectionView!
    private var dataSource: Chapter06CollectionViewDataSource!
    private var photoRepository: Chapter06PhotoRepository!
    private let selectedImagesSubject = PublishSubject<UIImage>()
    
    var selectedImages: Observable<UIImage> {
        selectedImagesSubject.asObserver()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        let authorized = PHPhotoLibrary.authorized.share()
       
        // .observe(on: MainScheduler.instance)がない場合、
        // Mainスレッドで実行されなくなり、アプリが落ちる
        authorized
            .skip(while: { !$0 })
            .take(1)
            .observe(on: MainScheduler.instance)
            .subscribe(
                with: self,
                onNext: { owner, _ in
                    owner.setupCollectionView()
                }
            )
            .disposed(by: disposeBag)
        
        authorized
            .skip(1)
            .takeLast(1)
            .filter { !$0 }
            .observe(on: MainScheduler.instance)
            .subscribe(
                with: self,
                onNext: { owner, _ in
                    owner.errorMessage()
                }
            )
            .disposed(by: disposeBag)
       
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        selectedImagesSubject.onCompleted()
    }
}

extension Chapter06PhotosViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? Chapter06PhotoCell {
            cell.flash()
        }
        
        let asset = photoRepository.photos.object(at: indexPath.item)
        photoRepository.imageManager.requestImage(
            for: asset,
            targetSize: view.frame.size,
            contentMode: .aspectFill,
            options: nil) { [weak self] image, info in
                guard let image, let info else {
                    return
                }
                if let isThumnail = info[PHImageResultIsDegradedKey as NSString] as? Bool, !isThumnail {
                    self?.selectedImagesSubject.onNext(image)
                }
            }
    }
}

private extension Chapter06PhotosViewController {
    func makeCollectionViewLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 80, height: 80)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        return layout
    }
    
    func setupCollectionView() {
        // UICollectionViewを生成
        collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: makeCollectionViewLayout()
        )
        
        // Custom Cellの登録
        collectionView.register(Chapter06PhotoCell.self, forCellWithReuseIdentifier: Chapter06PhotoCell.reuseIdentifier)
      
        // サムネイル画像のサイズを取得
        let thumnailSize: CGSize = {
            let cellSize = (self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize
            return CGSize(
                width: cellSize.width * UIScreen.main.scale,
                height: cellSize.height * UIScreen.main.scale
            )
        }()
        
        // Repositoryの生成
        photoRepository = Chapter06PhotoRepository(thumnailSize: thumnailSize)
        
        // Chapter06CollectionViewDataSourceを生成
        dataSource = Chapter06CollectionViewDataSource(
            photoManager: photoRepository
        )
       
        // UICollectionViewのDataSourceを設定
        collectionView.dataSource = dataSource
       
        // UICollectionViewのデリゲートを設定
        collectionView.delegate = self
       
        // UIViewControllerのViewにUICollectionViewを設定
        // view = collectionViewだとエラーになるため、
        // view.addSubview(collectionView)を利用
        view.addSubview(collectionView)
        
        // コレクションビューのレイアウトを設定
        collectionView.translatesAutoresizingMaskIntoConstraints = false
       
        // 制約を設定
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
        
        self.collectionView.reloadData()
    }
    
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
    
    func errorMessage() {
        alert(
            "No access to Camera Roll",
            description: "You can grant access to Combinestagram from the Setting app"
        )
        .asObservable()
        .take(for: .seconds(5), scheduler: MainScheduler.instance)
        .subscribe(
            with: self,
            onCompleted: { owner in
                owner.dismiss(animated: true) {
                    owner.navigationController?.popViewController(animated: true)
                }
            }
        )
        .disposed(by: disposeBag)
        
    }
}
