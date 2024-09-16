//
//  Chapter06PhotoWriter.swift
//  RxSwiftExample
//
//  Created by 藤門莉生 on 2024/09/16.
//

import Foundation
import UIKit
import Photos
import RxSwift

final class Chapter06PhotoWriter {
    enum Errors: Error {
        case couldNotSavePhoto
    }
    
    static func save(_ image: UIImage) -> Observable<String> {
        Observable.create { observer in
            var savedAssetId: String?
            PHPhotoLibrary.shared().performChanges({
                // PHAssetChangeRequest.creationRequestForAsset(from:)を使用して、
                // 新しいフォトセットを作成し、その識別子をsavedAssetIdに保存する。
                let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                savedAssetId = request.placeholderForCreatedAsset?.localIdentifier
                },
                completionHandler: { isSuccess, error in
                DispatchQueue.main.async {
                    if isSuccess, let id = savedAssetId {
                        observer.onNext(id)
                        observer.onCompleted()
                    } else {
                        observer.onError(error ?? Errors.couldNotSavePhoto)
                    }
                }
                }
            )
            return Disposables.create()
        }
    }
   
    // Challenge1
    static func save(_ image: UIImage) -> Single<String> {
        Single.create { observer in
            var savedAssetId: String?
            PHPhotoLibrary.shared().performChanges({
                // PHAssetChangeRequest.creationRequestForAsset(from:)を使用して、
                // 新しいフォトセットを作成し、その識別子をsavedAssetIdに保存する。
                let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                savedAssetId = request.placeholderForCreatedAsset?.localIdentifier
                },
                completionHandler: { isSuccess, error in
                DispatchQueue.main.async {
                    if isSuccess, let id = savedAssetId {
                        observer(.success(id))
                    } else {
                        observer(.failure(Errors.couldNotSavePhoto))
                    }
                }
                }
            )
            return Disposables.create()
        }
    }
}
