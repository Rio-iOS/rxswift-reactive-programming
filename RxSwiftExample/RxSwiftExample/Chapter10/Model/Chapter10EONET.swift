//
//  Chapter10EONET.swift
//  RxSwiftExample
//
//  Created by 藤門莉生 on 2024/09/23.
//

import Foundation
import RxSwift
import RxRelay

class Chapter10EONET {
    static let API = "https://eonet.sci.gsfc.nasa.gov/api/v2.1"
    static let categoriesEndpoint = "/categories"
    static let eventsEndpoint = "/events"
    
    static var categories: Observable<[Chapter10EOCategory]> = {
        let request: Observable<[Chapter10EOCategory]> = Chapter10EONET.request(endpoint: categoriesEndpoint, contentIdentifier: "categories")
        
        return request
            .map { categories in
                categories.sorted { $0.name < $1.name }
            }
            .catchAndReturn([])
            .share(replay: 1, scope: .forever)
    }()
    
    static func events(forLast days: Int = 360, category: Chapter10EOCategory) -> Observable<[Chapter10EOEvent]> {
        let openEvents = events(forLast: days, closed: false, endpoint: category.endpoint)
        let closedEvents = events(forLast: days, closed: true, endpoint: category.endpoint)
        
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
