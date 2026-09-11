import XCTest
import RxSwift
@testable import RepositoryActivityCore

final class RepositoryActivityTests: XCTestCase {
    func testRefreshReplacesCachedSnapshotAndValidator() {
        let cache = MemoryCache()
        cache.repositories = [Chapter08Repository(name: "old", owner: nil)]
        let service = ServiceStub()
        let useCase = RefreshRepositoryActivityUseCase(service: service, cache: cache)
        let subscription = useCase.execute(repositoryPath: "ReactiveX/RxSwift").subscribe()
        service.response.onNext(RepositoryActivityResponse(repository: Chapter08Repository(name: "new", owner: nil), lastModified: "updated"))
        XCTAssertEqual(cache.repositories.map(\.name), ["new"])
        XCTAssertEqual(cache.lastModified, "updated")
        subscription.dispose()
    }

    func testUnmodifiedResponseKeepsCachedSnapshot() {
        let cache = MemoryCache()
        cache.repositories = [Chapter08Repository(name: "cached", owner: nil)]
        cache.lastModified = "original"
        let service = ServiceStub()
        let useCase = RefreshRepositoryActivityUseCase(service: service, cache: cache)
        var names: [String] = []
        let subscription = useCase.execute(repositoryPath: "owner/repo").subscribe(onNext: { names = $0.map(\.name) })
        service.response.onNext(RepositoryActivityResponse(repository: nil, lastModified: "original"))
        XCTAssertEqual(names, ["cached"])
        XCTAssertEqual(service.lastModified, "original")
        XCTAssertEqual(service.repositoryPath, "owner/repo")
        subscription.dispose()
    }

    func testErrorDoesNotReplaceCachedData() {
        let cache = MemoryCache()
        cache.repositories = [Chapter08Repository(name: "cached", owner: nil)]
        let service = ServiceStub()
        let useCase = RefreshRepositoryActivityUseCase(service: service, cache: cache)
        var receivedError = false
        let subscription = useCase.execute(repositoryPath: "owner/repo").subscribe(onError: { _ in receivedError = true })
        service.response.onError(URLError(.notConnectedToInternet))
        XCTAssertTrue(receivedError)
        XCTAssertEqual(cache.repositories.map(\.name), ["cached"])
        subscription.dispose()
    }

    func testSubscriptionDoesNotRetainViewModel() {
        let service = ServiceStub()
        var viewModel: RepositoryActivityViewModel? = RepositoryActivityViewModel(repositoryPath: "owner/repo", refreshActivity: RefreshRepositoryActivityUseCase(service: service, cache: MemoryCache()))
        weak var reference = viewModel
        let subscription = viewModel?.refresh().subscribe()
        viewModel = nil
        XCTAssertNil(reference)
        subscription?.dispose()
    }
}

private final class MemoryCache: RepositoryActivityCaching {
    var repositories: [Chapter08Repository] = []
    var lastModified: String?
}

private final class ServiceStub: RepositoryActivityFetching {
    let response = PublishSubject<RepositoryActivityResponse>()
    private(set) var repositoryPath: String?
    private(set) var lastModified: String?
    func fetch(repositoryPath: String, lastModified: String?) -> Observable<RepositoryActivityResponse> {
        self.repositoryPath = repositoryPath
        self.lastModified = lastModified
        return response
    }
}
