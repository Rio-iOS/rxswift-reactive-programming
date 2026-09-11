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

/// 1 つのリポジトリの表示データと条件付き取得用の更新日時を保持する境界。
protocol RepositoryActivityCaching: AnyObject {
    var repositories: [Chapter08Repository] { get set }
    var lastModified: String? { get set }
}

/// JSON と更新日時を指定ディレクトリへ同期的に保存するキャッシュ。
///
/// ディレクトリは呼び出し側で用意します。読み込み失敗は空配列または `nil`、書き込み失敗は無視します。
/// 同時アクセスの排他制御や、2 ファイルをまとめた原子的な更新は行いません。
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

/// 条件付きで取得した結果をキャッシュへ反映し、保存されている一覧を返します。
final class RefreshRepositoryActivityUseCase {
    private let service: RepositoryActivityFetching
    private let cache: RepositoryActivityCaching

    init(service: RepositoryActivityFetching, cache: RepositoryActivityCaching) {
        self.service = service
        self.cache = cache
    }

    var cachedRepositories: [Chapter08Repository] { cache.repositories }

    /// 更新があれば保存し、HTTP 304 なら既存キャッシュを返します。取得時のエラーはそのまま通知します。
    ///
    /// - Parameter repositoryPath: `owner/name` 形式のパス。同じキャッシュを別のパスと共有しないでください。
    /// - Returns: 更新後にキャッシュから読み直した一覧。通知スケジューラは変更しません。
    func execute(repositoryPath: String) -> Observable<[Chapter08Repository]> {
        // クロージャには必要なキャッシュだけを渡し、UseCase 自体の保持を避けます。
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

/// キャッシュの初期表示と、メインスレッドへ通知する更新処理を提供します。
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
