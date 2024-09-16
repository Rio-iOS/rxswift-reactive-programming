//
//  Chapter06PhotoRepository.swift
//  RxSwiftExample
//
//  Created by 藤門莉生 on 2024/09/16.
//

import Photos

final class Chapter06PhotoRepository {
    lazy var photos = Self.loadPhotos()
    lazy var imageManager = PHCachingImageManager()
    let thumnailSize: CGSize
    
    init(thumnailSize: CGSize) {
        self.thumnailSize = thumnailSize
    }
}

private extension Chapter06PhotoRepository {
    static func loadPhotos() -> PHFetchResult<PHAsset> {
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        return PHAsset.fetchAssets(with: allPhotosOptions)
    }
}
