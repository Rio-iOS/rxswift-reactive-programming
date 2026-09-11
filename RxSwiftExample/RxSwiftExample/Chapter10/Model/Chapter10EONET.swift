import Foundation
import RxSwift
import RxRelay
import RxCocoa

/// EONET API v2.1 の取得・デコードを扱う教材用アダプタ。
enum Chapter10EONET {
    private static let baseURLString = "https://eonet.gsfc.nasa.gov/api/v2.1"
    static let categoriesEndpoint = "/categories"
    
    /// 名前順のカテゴリ一覧。購読ごとに取得し、通信・デコードの失敗を通知します。
    static var categories: Observable<[Chapter10EOCategory]> {
        let request: Observable<[Chapter10EOCategory]> = Chapter10EONET.request(endpoint: categoriesEndpoint, contentIdentifier: "categories")
        
        return request
            .map { categories in
                categories.sorted { $0.name < $1.name }
            }

    }
    
    /// 指定カテゴリのopen・closedの結果を結合します。どちらかの失敗も呼び出し元へ返します。
    static func events(forLast days: Int = 360, category: Chapter10EOCategory, session: URLSession = .shared) -> Observable<[Chapter10EOEvent]> {
        let openEvents = events(forLast: days, closed: false, endpoint: category.endpoint, session: session)
        let closedEvents = events(forLast: days, closed: true, endpoint: category.endpoint, session: session)
        
        // 比較例（未実行）: concat なら open の完了後に closed を購読します。
        // return openEvents.concat(closedEvents)
        return Observable.of(openEvents, closedEvents)
            .merge()
            .reduce([]) { running, new in
                running + new
            }
    }
    
    private static func events(forLast days: Int, closed: Bool, endpoint: String, session: URLSession) -> Observable<[Chapter10EOEvent]> {
        let query: [String: Any] = [
            "days": days,
            "status": (closed ? "closed" : "open")
        ]
        let request: Observable<[Chapter10EOEvent]> = Chapter10EONET.request(
            endpoint: endpoint,
            query: query,
            contentIdentifier: "events", session: session
        )
        return request
    }
    
    private static func jsonDecoder(contentIdentifier: String) -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.userInfo[.contentIdentifier] = contentIdentifier
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
    
    /// 指定したキーのJSONをデコードします。構築・通信・HTTP・デコードの失敗はエラーとして通知します。
    /// sessionはテストで差し替えられます。購読破棄はURLSessionのリクエストをキャンセルします。
    static func request<T: Decodable>(endpoint: String, query: [String: Any] = [:], contentIdentifier: String, session: URLSession = .shared) -> Observable<T> {
        
        do {
            guard
                let url = URL(string: baseURLString)?.appendingPathComponent(endpoint),
                var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
            else {
                throw Chapter10EOError.invalidURL(endpoint)
            }
            
            components.queryItems = try query.compactMap({ (key, value) in
                guard let v = value as? CustomStringConvertible else {
                    throw Chapter10EOError.invalidParameter(key, value)
                }
                return URLQueryItem(name: key, value: v.description)
            })
            
            guard let finalURL = components.url else {
                throw Chapter10EOError.invalidURL(endpoint)
            }
            
            let request = URLRequest(url: finalURL)
            
            return session
                .rx
                .response(request: request)
                .map { (result: (response: HTTPURLResponse, data: Data)) -> T in
                    guard (200..<300).contains(result.response.statusCode) else { throw Chapter10EOError.httpStatus(result.response.statusCode) }
                    let decoder = self.jsonDecoder(contentIdentifier: contentIdentifier)
                    let envelope = try decoder.decode(Chapter10EOEnvelope<T>.self, from: result.data)
                    return envelope.content
                }
        } catch {
            return Observable<T>.error(error)
        }
    }
}
