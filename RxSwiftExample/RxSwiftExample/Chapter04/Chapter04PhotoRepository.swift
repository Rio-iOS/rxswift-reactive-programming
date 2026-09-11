import Photos

final class Chapter04PhotoRepository {
    lazy var photos = Self.loadPhotos()
    lazy var imageManager = PHCachingImageManager()
    let thumbnailSize: CGSize

    init(thumbnailSize: CGSize) {
        self.thumbnailSize = thumbnailSize
    }
}

private extension Chapter04PhotoRepository {
    static func loadPhotos() -> PHFetchResult<PHAsset> {
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        return PHAsset.fetchAssets(with: allPhotosOptions)
    }
}
