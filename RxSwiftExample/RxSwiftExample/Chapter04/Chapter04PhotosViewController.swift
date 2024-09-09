//
//  Chapter04PhotosViewController.swift
//  RxSwiftExample
//
//  Created by 藤門莉生 on 2024/09/08.
//

import UIKit
import Photos
import RxSwift

final class Chapter04PhotosViewController: UIViewController {
    private var collectionView: UICollectionView!
    private var dataSource: Chapter04CollectionViewDataSource!
    private var photoRepository: Chapter04PhotoRepository!
    private let selectedImagesSubject = PublishSubject<UIImage>()
    
    var selectedImages: Observable<UIImage> {
        selectedImagesSubject.asObserver()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        // UICollectionViewを生成
        collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: makeCollectionViewLayout()
        )
       
        // Custom Cellの登録
        collectionView.register(Chapter04PhotoCell.self, forCellWithReuseIdentifier: Chapter04PhotoCell.reuseIdentifier)
      
        // サムネイル画像のサイズを取得
        let thumnailSize: CGSize = {
            let cellSize = (self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize
            return CGSize(
                width: cellSize.width * UIScreen.main.scale,
                height: cellSize.height * UIScreen.main.scale
            )
        }()
        
        photoRepository = Chapter04PhotoRepository(thumnailSize: thumnailSize)
        // Chapter04CollectionViewDataSourceを生成
        dataSource = Chapter04CollectionViewDataSource(
            photoManager: photoRepository
        )
       
        // UICollectionViewのDataSourceを設定
        collectionView.dataSource = dataSource
       
        // UICollectionViewのデリゲートを設定
        collectionView.delegate = self
       
        // UIViewControllerのViewにUICollectionViewを設定
        view = collectionView
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        selectedImagesSubject.onCompleted()
    }
}

extension Chapter04PhotosViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? Chapter04PhotoCell {
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

private extension Chapter04PhotosViewController {
    func makeCollectionViewLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 80, height: 80)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        return layout
    }
}
