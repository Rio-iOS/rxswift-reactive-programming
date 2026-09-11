import Foundation
import RxSwift
import RxRelay

/// EONET API v2.1 の取得・デコードを扱う教材用アダプタ。
class Chapter10EONET {
    static let API = "https://eonet.sci.gsfc.nasa.gov/api/v2.1"
    static let categoriesEndpoint = "/categories"
    static let eventsEndpoint = "/events"
    
    /// 名前順のカテゴリ一覧。取得エラーは空配列に変換し、直近の結果を購読間で保持します。
    static var categories: Observable<[Chapter10EOCategory]> = {
        let request: Observable<[Chapter10EOCategory]> = Chapter10EONET.request(endpoint: categoriesEndpoint, contentIdentifier: "categories")
        
        return request
            .map { categories in
                categories.sorted { $0.name < $1.name }
            }
            .catchAndReturn([])
            .share(replay: 1, scope: .forever)
    }()
    
    /// open・closed の結果を結合します。現実装は共通の `/events` を取得し、カテゴリでの絞り込みは呼び出し側が行います。
    static func events(forLast days: Int = 360, category: Chapter10EOCategory) -> Observable<[Chapter10EOEvent]> {
        let openEvents = events(forLast: days, closed: false, endpoint: category.endpoint)
        let closedEvents = events(forLast: days, closed: true, endpoint: category.endpoint)
        
        // 比較例（未実行）: concat なら open の完了後に closed を購読します。
        // return openEvents.concat(closedEvents)
        return Observable.of(openEvents, closedEvents)
            .merge()
            .reduce([]) { running, new in
                running + new
            }
    }
    
    private static func events(forLast days: Int, closed: Bool, endpoint: String) -> Observable<[Chapter10EOEvent]> {
        let query: [String: Any] = [
            "days": days,
            "status": (closed ? "closed" : "open")
        ]
        let request: Observable<[Chapter10EOEvent]> = Chapter10EONET.request(
            endpoint: eventsEndpoint,
            query: query,
            contentIdentifier: "events"
        )
        return request.catchAndReturn([])
    }
    
    static func jsonDecoder(contentIdentifier: String) -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.userInfo[.contentIdentifier] = contentIdentifier
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
    
    static func filteredEvents(events: [Chapter10EOEvent], forCategory category: Chapter10EOCategory) -> [Chapter10EOEvent] {
        return events.filter { event in
            return event
                .categories
                .contains(where: { $0.id == category.id }) && !category.events.contains(where: { $0.id == event.id })
        }
        .sorted(by: Chapter10EOEvent.compareDates)
    }
    
    /// 指定したキーの JSON をデコードします。URL・パラメータの構築失敗は値を通知せず完了します。
    /// 通信とデコードのエラーは Observable に流します。HTTP ステータスの独自検証は行いません。
    static func request<T: Decodable>(endpoint: String, query: [String: Any] = [:], contentIdentifier: String) -> Observable<T> {
        
        do {
            guard
                let url = URL(string: API)?.appending(path: endpoint),
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
            
            return URLSession
                .shared
                .rx
                .response(request: request)
                .map { (result: (response: HTTPURLResponse, data: Data)) -> T in
                    let decoder = self.jsonDecoder(contentIdentifier: contentIdentifier)
                    let envelope = try decoder.decode(Chapter10EOEnvelope<T>.self, from: result.data)
                    return envelope.content
                }
        } catch {
            return Observable<T>.empty()
        }
    }
}
