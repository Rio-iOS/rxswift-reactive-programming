//
//  Chapter04CollectionViewDataSource.swift
//  RxSwiftExample
//
//  Created by 藤門莉生 on 2024/09/08.
//

import UIKit

final class Chapter04CollectionViewDataSource: NSObject, UICollectionViewDataSource {
    
    private let photoRepository: Chapter04PhotoRepository
    
    init(photoManager: Chapter04PhotoRepository) {
        self.photoRepository = photoManager
        super.init()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        photoRepository.photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let asset = photoRepository.photos.object(at: indexPath.item)
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Chapter04PhotoCell.reuseIdentifier, for: indexPath) as! Chapter04PhotoCell
        
        cell.representedAssetIdentifier = asset.localIdentifier
        
        photoRepository.imageManager.requestImage(
            for: asset,
            targetSize: photoRepository.thumnailSize,
            contentMode: .aspectFill,
            options: nil) { image, _ in
                if cell.representedAssetIdentifier == asset.localIdentifier {
                    cell.imageView.image = image
                }
            }
        
        return cell
    }
}
