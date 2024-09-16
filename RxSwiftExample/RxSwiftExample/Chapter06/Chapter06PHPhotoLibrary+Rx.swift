//
//  Chapter06PHPhotoLibrary+Rx.swift
//  RxSwiftExample
//
//  Created by 藤門莉生 on 2024/09/16.
//

import Foundation
import Photos
import RxSwift

extension PHPhotoLibrary {
    static var authorized: Observable<Bool> {
        Observable.create { observer in
            DispatchQueue.main.async {
                if authorizationStatus(for: .readWrite) == .authorized {
                    observer.onNext(true)
                    observer.onCompleted()
                } else {
                    observer.onNext(false)
                    requestAuthorization(for: .readWrite) { newStatus in
                        observer.onNext(newStatus == .authorized)
                        observer.onCompleted()
                    }
                }
            }
            return Disposables.create()
        }
    }
}
