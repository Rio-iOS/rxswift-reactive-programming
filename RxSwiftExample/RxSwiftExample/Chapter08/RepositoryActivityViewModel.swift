import Foundation
import RxSwift
import RxCocoa

/// リポジトリの取得結果。HTTP 304 の場合は `repository` が `nil` になります。
struct RepositoryActivityResponse {
    let repository: Chapter08Repository?
    let lastModified: String?
}

/// 更新日時を使った条件付き取得を、通信実装から切り離す境界。
protocol RepositoryActivityFetching {
    func fetch(repositoryPath: String, lastModified: String?) -> Observable<RepositoryActivityResponse>
}

/// GitHub REST API からリポジトリを取得し、通信・HTTP・デコードの失敗をエラーとして通知します。
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

/// 本文と更新日時を同じリポジトリに結び付ける保存単位。
struct RepositoryActivitySnapshot: Codable {
    let repositoryPath: String
    let repositories: [Chapter08Repository]
    let lastModified: String?
}

protocol RepositoryActivityCaching: AnyObject {
    func load(for repositoryPath: String) throws -> RepositoryActivitySnapshot?
    func save(_ snapshot: RepositoryActivitySnapshot) throws
}

/// 本文と更新日時を1つのJSONへ原子的に保存します。保存失敗は呼び出し元へ返します。
final class FileRepositoryActivityCache: RepositoryActivityCaching {
    private let directory: URL
    private let lock = NSLock()
    private var fileURL: URL { directory.appendingPathComponent("repository-activity-v2.json") }

    init(directory: URL) { self.directory = directory }

    func load(for repositoryPath: String) throws -> RepositoryActivitySnapshot? {
        lock.lock()
        defer { lock.unlock() }
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        let snapshot = try JSONDecoder().decode(RepositoryActivitySnapshot.self, from: Data(contentsOf: fileURL))
        return snapshot.repositoryPath == repositoryPath ? snapshot : nil
    }

    func save(_ snapshot: RepositoryActivitySnapshot) throws {
        lock.lock()
        defer { lock.unlock() }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(snapshot).write(to: fileURL, options: .atomic)
    }
}

/// 破損したキャッシュは使わず再取得し、通信または保存の失敗は呼び出し元へ通知します。
final class RefreshRepositoryActivityUseCase {
    private let service: RepositoryActivityFetching
    private let cache: RepositoryActivityCaching

    init(service: RepositoryActivityFetching, cache: RepositoryActivityCaching) {
        self.service = service
        self.cache = cache
    }

    func cachedRepositories(for repositoryPath: String) -> [Chapter08Repository] {
        (try? cache.load(for: repositoryPath))?.repositories ?? []
    }

    func execute(repositoryPath: String) -> Observable<[Chapter08Repository]> {
        let cache = cache
        let service = service
        return Observable.deferred {
            let snapshot = try? cache.load(for: repositoryPath)
            return service.fetch(repositoryPath: repositoryPath, lastModified: snapshot?.lastModified)
                .map { response in
                    guard let repository = response.repository else {
                        guard let snapshot = snapshot else { throw URLError(.badServerResponse) }
                        return snapshot.repositories
                    }
                    let updated = RepositoryActivitySnapshot(repositoryPath: repositoryPath, repositories: [repository], lastModified: response.lastModified)
                    try cache.save(updated)
                    return updated.repositories
                }
        }
    }
}

/// キャッシュの初期表示と、メインスレッドへ通知する更新処理を提供します。
final class RepositoryActivityViewModel {
    private let refreshActivity: RefreshRepositoryActivityUseCase
    private let repositoryPath: String

    init(repositoryPath: String, refreshActivity: RefreshRepositoryActivityUseCase) {
        self.repositoryPath = repositoryPath
        self.refreshActivity = refreshActivity
    }

    var cachedRepositories: [Chapter08Repository] { refreshActivity.cachedRepositories(for: repositoryPath) }

    func refresh() -> Observable<[Chapter08Repository]> {
        refreshActivity.execute(repositoryPath: repositoryPath).observe(on: MainScheduler.instance)
    }
}
