import Foundation
import XCTest
import RxSwift
@testable import EventCategoriesCore

final class EventCategoriesTests: XCTestCase {
    func testBatchesAreDeduplicatedAndSortedAcrossResponses() throws {
        let repository = CategoriesStub()
        let older = try decodeEvent(geometry: #"{"type":"Point","date":"2025-01-01T00:00:00Z","coordinates":[139,35]}"#)
        let newerData = Data(#"{"id":"new","title":"New","categories":[{"id":8,"title":"Wildfires"}],"geometries":[{"type":"Point","date":"2026-01-01T00:00:00Z","coordinates":[139,35]}]}"#.utf8)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let newer = try decoder.decode(Chapter10EOEvent.self, from: newerData)
        var ids: [String] = []
        let subscription = FetchEventCategoriesUseCase(repository: repository).execute().subscribe(onNext: { ids = $0.first?.events.map(\.id) ?? [] })
        repository.events.onNext([newer, newer])
        XCTAssertEqual(ids, ["new"])
        repository.events.onNext([older, newer])
        XCTAssertEqual(ids, ["event", "new"])
        subscription.dispose()
    }

    func testOpenEventWithNullClosedDateAndLongitudeLatitudeDecodes() throws {
        let event = try decodeEvent(geometry: #"{"type":"Point","date":"2026-01-01T00:00:00Z","coordinates":[139.7,35.6]}"#)
        XCTAssertNil(event.closeDate)
        XCTAssertNotNil(event.date)
        XCTAssertEqual(event.locations?.first?.coordinates.first?.longitude, 139.7)
        XCTAssertEqual(event.locations?.first?.coordinates.first?.latitude, 35.6)
    }

    func testPolygonCoordinatesAndMalformedGeometry() throws {
        let event = try decodeEvent(geometry: #"{"type":"Polygon","coordinates":[[[139,35],[140,35],[140,36],[139,35]]]}"#)
        XCTAssertEqual(event.locations?.first?.coordinates.count, 4)
        XCTAssertThrowsError(try decodeEvent(geometry: #"{"type":"Point","coordinates":[139]}"#))
    }

    func testHTTPFailureIsNotReportedAsEmptySuccess() {
        RequestStub.handler = { _ in (503, Data(#"{"events":[]}"#.utf8)) }
        let completed = expectation(description: "error")
        let result: Observable<[Chapter10EOEvent]> = Chapter10EONET.request(endpoint: "/events", contentIdentifier: "events", session: session())
        let disposable = result.subscribe(onNext: { _ in XCTFail("Expected HTTP failure") }, onError: { error in
            guard case Chapter10EOError.httpStatus(503) = error else { return XCTFail("Unexpected error: \(error)") }
            completed.fulfill()
        })
        wait(for: [completed], timeout: 3)
        disposable.dispose()
    }

    func testCategoryEndpointAndBothStatusesAreUsed() {
        let lock = NSLock()
        var paths: [String] = []
        var statuses: [String] = []
        RequestStub.handler = { request in
            lock.lock()
            paths.append(request.url?.path ?? "")
            statuses.append(request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "status" }?.value } ?? "")
            lock.unlock()
            return (200, Data(#"{"events":[]}"#.utf8))
        }
        let completed = expectation(description: "empty success")
        let category = Chapter10EOCategory(id: 8, name: "Wildfires", description: "")
        let disposable = Chapter10EONET.events(category: category, session: session()).subscribe(onNext: { events in
            XCTAssertTrue(events.isEmpty)
        }, onError: { XCTFail("\($0)") }, onCompleted: { completed.fulfill() })
        wait(for: [completed], timeout: 3)
        XCTAssertEqual(paths, ["/api/v2.1/categories/8", "/api/v2.1/categories/8"])
        XCTAssertEqual(Set(statuses), ["open", "closed"])
        disposable.dispose()
    }

    func testConstructionFailureReachesSubscriber() {
        var failed = false
        let result: Observable<[Chapter10EOEvent]> = Chapter10EONET.request(endpoint: "/events", query: ["bad": InvalidQueryValue()], contentIdentifier: "events", session: session())
        let disposable = result.subscribe(onError: { _ in failed = true })
        XCTAssertTrue(failed)
        disposable.dispose()
    }

    func testUseCasePropagatesFailureAndDisposalCancelsInnerFetch() {
        let repository = CategoriesStub()
        var failed = false
        let disposable = FetchEventCategoriesUseCase(repository: repository).execute().subscribe(onError: { _ in failed = true })
        repository.events.onError(URLError(.timedOut))
        XCTAssertTrue(failed)
        disposable.dispose()
        let other = CategoriesStub()
        let pending = FetchEventCategoriesUseCase(repository: other).execute().subscribe()
        XCTAssertTrue(other.events.hasObservers)
        pending.dispose()
        XCTAssertFalse(other.events.hasObservers)
    }

    private func session() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [RequestStub.self]
        return URLSession(configuration: configuration)
    }

    private func decodeEvent(geometry: String) throws -> Chapter10EOEvent {
        let data = Data("{\"id\":\"event\",\"title\":\"Event\",\"description\":null,\"link\":null,\"closed\":null,\"categories\":[{\"id\":8,\"title\":\"Wildfires\"}],\"geometries\":[\(geometry)]}".utf8)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Chapter10EOEvent.self, from: data)
    }
}

private final class CategoriesStub: EventCategoriesRepository {
    let events = PublishSubject<[Chapter10EOEvent]>()
    func fetchCategories() -> Observable<[Chapter10EOCategory]> { .just([Chapter10EOCategory(id: 8, name: "Wildfires", description: "")]) }
    func fetchEvents(in category: Chapter10EOCategory) -> Observable<[Chapter10EOEvent]> { events }
}

private struct InvalidQueryValue {}

private final class RequestStub: URLProtocol {
    static var handler: (URLRequest) -> (Int, Data) = { _ in (500, Data()) }
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let (status, data) = Self.handler(request)
        client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
