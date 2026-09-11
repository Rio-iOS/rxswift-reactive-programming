import XCTest
import RxSwift
@testable import RepositoryActivityCore

final class RepositoryActivityTests: XCTestCase {
    private let path = "owner/repo"

    func testRefreshReplacesBodyAndValidatorTogether() throws {
        let cache = MemoryCache()
        cache.snapshot = snapshot("old", validator: "old-date")
        let service = ServiceStub()
        let useCase = RefreshRepositoryActivityUseCase(service: service, cache: cache)
        let subscription = useCase.execute(repositoryPath: path).subscribe()
        service.response.onNext(RepositoryActivityResponse(repository: Chapter08Repository(name: "new", owner: nil), lastModified: "new-date"))
        XCTAssertEqual(cache.snapshot?.repositories.map(\.name), ["new"])
        XCTAssertEqual(cache.snapshot?.lastModified, "new-date")
        XCTAssertEqual(cache.snapshot?.repositoryPath, path)
        subscription.dispose()
    }

    func testUnmodifiedResponseUsesMatchingSnapshot() {
        let cache = MemoryCache()
        cache.snapshot = snapshot("cached", validator: "original")
        let service = ServiceStub()
        var names: [String] = []
        let subscription = RefreshRepositoryActivityUseCase(service: service, cache: cache).execute(repositoryPath: path)
            .subscribe(onNext: { names = $0.map(\.name) })
        service.response.onNext(RepositoryActivityResponse(repository: nil, lastModified: "original"))
        XCTAssertEqual(names, ["cached"])
        XCTAssertEqual(service.lastModified, "original")
        subscription.dispose()
    }

    func testUnmatchedRepositoryNeverUsesAnotherRepositoriesValidator() {
        let cache = MemoryCache()
        cache.snapshot = snapshot("cached", validator: "original")
        let service = ServiceStub()
        var failed = false
        let subscription = RefreshRepositoryActivityUseCase(service: service, cache: cache).execute(repositoryPath: "another/repo")
            .subscribe(onError: { _ in failed = true })
        XCTAssertNil(service.lastModified)
        service.response.onNext(RepositoryActivityResponse(repository: nil, lastModified: nil))
        XCTAssertTrue(failed)
        subscription.dispose()
    }

    func testPersistenceFailureKeepsPreviousSnapshotAndReachesCaller() {
        let cache = MemoryCache()
        cache.snapshot = snapshot("old", validator: "old-date")
        cache.shouldFailSaving = true
        let service = ServiceStub()
        var failed = false
        let subscription = RefreshRepositoryActivityUseCase(service: service, cache: cache).execute(repositoryPath: path)
            .subscribe(onError: { _ in failed = true })
        service.response.onNext(RepositoryActivityResponse(repository: Chapter08Repository(name: "new", owner: nil), lastModified: "new-date"))
        XCTAssertTrue(failed)
        XCTAssertEqual(cache.snapshot?.lastModified, "old-date")
        XCTAssertEqual(cache.snapshot?.repositories.map(\.name), ["old"])
        subscription.dispose()
    }

    func testDiskSnapshotSurvivesNewCacheInstanceAndIsScopedToRepository() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileRepositoryActivityCache(directory: directory).save(snapshot("saved", validator: "date"))
        let restored = FileRepositoryActivityCache(directory: directory)
        XCTAssertEqual(try restored.load(for: path)?.repositories.map(\.name), ["saved"])
        XCTAssertEqual(try restored.load(for: path)?.lastModified, "date")
        XCTAssertNil(try restored.load(for: "other/repo"))
    }

    func testCorruptCacheTriggersUnconditionalFetch() {
        let cache = MemoryCache()
        cache.shouldFailLoading = true
        let service = ServiceStub()
        let subscription = RefreshRepositoryActivityUseCase(service: service, cache: cache).execute(repositoryPath: path).subscribe()
        XCTAssertNil(service.lastModified)
        service.response.onNext(RepositoryActivityResponse(repository: Chapter08Repository(name: "fresh", owner: nil), lastModified: "fresh-date"))
        XCTAssertEqual(cache.snapshot?.repositories.map(\.name), ["fresh"])
        subscription.dispose()
    }

    func testErrorAndDisposalDoNotUpdateCache() {
        let cache = MemoryCache()
        cache.snapshot = snapshot("old", validator: "date")
        let service = ServiceStub()
        var failed = false
        let useCase = RefreshRepositoryActivityUseCase(service: service, cache: cache)
        let subscription = useCase.execute(repositoryPath: path).subscribe(onError: { _ in failed = true })
        service.response.onError(URLError(.notConnectedToInternet))
        XCTAssertTrue(failed)
        XCTAssertEqual(cache.snapshot?.repositories.map(\.name), ["old"])
        subscription.dispose()
        let otherService = ServiceStub()
        let disposable = RefreshRepositoryActivityUseCase(service: otherService, cache: cache).execute(repositoryPath: path).subscribe()
        disposable.dispose()
        otherService.response.onNext(RepositoryActivityResponse(repository: Chapter08Repository(name: "late", owner: nil), lastModified: nil))
        XCTAssertEqual(cache.snapshot?.repositories.map(\.name), ["old"])
    }

    func testSubscriptionDoesNotRetainViewModel() {
        let service = ServiceStub()
        var viewModel: RepositoryActivityViewModel? = RepositoryActivityViewModel(repositoryPath: path, refreshActivity: RefreshRepositoryActivityUseCase(service: service, cache: MemoryCache()))
        weak var reference = viewModel
        let subscription = viewModel?.refresh().subscribe()
        viewModel = nil
        XCTAssertNil(reference)
        subscription?.dispose()
    }

    private func snapshot(_ name: String, validator: String) -> RepositoryActivitySnapshot {
        RepositoryActivitySnapshot(repositoryPath: path, repositories: [Chapter08Repository(name: name, owner: nil)], lastModified: validator)
    }
}

private final class MemoryCache: RepositoryActivityCaching {
    var snapshot: RepositoryActivitySnapshot?
    var shouldFailSaving = false
    var shouldFailLoading = false
    func load(for repositoryPath: String) throws -> RepositoryActivitySnapshot? {
        if shouldFailLoading { throw CocoaError(.fileReadCorruptFile) }
        return snapshot?.repositoryPath == repositoryPath ? snapshot : nil
    }
    func save(_ snapshot: RepositoryActivitySnapshot) throws {
        if shouldFailSaving { throw CocoaError(.fileWriteNoPermission) }
        self.snapshot = snapshot
    }
}

private final class ServiceStub: RepositoryActivityFetching {
    let response = PublishSubject<RepositoryActivityResponse>()
    private(set) var lastModified: String?
    func fetch(repositoryPath: String, lastModified: String?) -> Observable<RepositoryActivityResponse> {
        self.lastModified = lastModified
        return response
    }
}
