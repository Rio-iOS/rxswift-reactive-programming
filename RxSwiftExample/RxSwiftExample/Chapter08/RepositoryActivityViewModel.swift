import Foundation
import RxSwift
import RxCocoa

struct RepositoryActivityResponse {
    let repository: Chapter08Repository?
    let lastModified: String?
}

protocol RepositoryActivityFetching {
    func fetch(repositoryPath: String, lastModified: String?) -> Observable<RepositoryActivityResponse>
}

final class GitHubRepositoryActivityService: RepositoryActivityFetching {
    private let session: URLSession

    init(session: URLSession = .shared) { self.session = session }

    func fetch(repositoryPath: String, lastModified: String?) -> Observable<RepositoryActivityResponse> {
        guard let url = URL(string: "https://api.github.com/repos/\(repositoryPath)") else {
            return .error(URLError(.badURL))
        }
        var request = URLRequest(url: url)
        request.setValue(lastModified, forHTTPHeaderField: "If-Modified-Since")
        return session.rx.response(request: request).map { response, data in
            if response.statusCode == 304 {
                return RepositoryActivityResponse(repository: nil, lastModified: lastModified)
            }
            guard (200..<300).contains(response.statusCode) else { throw URLError(.badServerResponse) }
            return RepositoryActivityResponse(
                repository: try JSONDecoder().decode(Chapter08Repository.self, from: data),
                lastModified: response.value(forHTTPHeaderField: "Last-Modified")
            )
        }
    }
}

protocol RepositoryActivityCaching: AnyObject {
    var repositories: [Chapter08Repository] { get set }
    var lastModified: String? { get set }
}

final class FileRepositoryActivityCache: RepositoryActivityCaching {
    private let directory: URL

    init(directory: URL) { self.directory = directory }

    var repositories: [Chapter08Repository] {
        get {
            guard let data = try? Data(contentsOf: directory.appendingPathComponent("repositories.json")) else { return [] }
            return (try? JSONDecoder().decode([Chapter08Repository].self, from: data)) ?? []
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            try? data.write(to: directory.appendingPathComponent("repositories.json"), options: .atomic)
        }
    }

    var lastModified: String? {
        get { try? String(contentsOf: directory.appendingPathComponent("modified.txt"), encoding: .utf8) }
        set {
            let url = directory.appendingPathComponent("modified.txt")
            if let newValue = newValue {
                try? newValue.write(to: url, atomically: true, encoding: .utf8)
            } else {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
}

final class RefreshRepositoryActivityUseCase {
    private let service: RepositoryActivityFetching
    private let cache: RepositoryActivityCaching

    init(service: RepositoryActivityFetching, cache: RepositoryActivityCaching) {
        self.service = service
        self.cache = cache
    }

    var cachedRepositories: [Chapter08Repository] { cache.repositories }

    func execute(repositoryPath: String) -> Observable<[Chapter08Repository]> {
        // Capture dependencies, not the owner of the subscription.
        let cache = cache
        return service.fetch(repositoryPath: repositoryPath, lastModified: cache.lastModified)
            .map { response in
                if let repository = response.repository {
                    cache.repositories = [repository]
                    cache.lastModified = response.lastModified
                }
                return cache.repositories
            }
    }
}

final class RepositoryActivityViewModel {
    private let refreshActivity: RefreshRepositoryActivityUseCase
    private let repositoryPath: String

    init(repositoryPath: String, refreshActivity: RefreshRepositoryActivityUseCase) {
        self.repositoryPath = repositoryPath
        self.refreshActivity = refreshActivity
    }

    var cachedRepositories: [Chapter08Repository] { refreshActivity.cachedRepositories }

    func refresh() -> Observable<[Chapter08Repository]> {
        refreshActivity.execute(repositoryPath: repositoryPath).observe(on: MainScheduler.instance)
    }
}
