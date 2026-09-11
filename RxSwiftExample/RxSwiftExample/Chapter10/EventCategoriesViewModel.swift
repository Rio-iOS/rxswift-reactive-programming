import RxSwift

protocol EventCategoriesRepository {
    func fetchCategories() -> Observable<[Chapter10EOCategory]>
    func fetchEvents(in category: Chapter10EOCategory) -> Observable<[Chapter10EOEvent]>
}

struct EONETCategoriesRepository: EventCategoriesRepository {
    func fetchCategories() -> Observable<[Chapter10EOCategory]> { Chapter10EONET.categories }
    func fetchEvents(in category: Chapter10EOCategory) -> Observable<[Chapter10EOEvent]> {
        Chapter10EONET.events(forLast: 360, category: category)
    }
}

struct FetchEventCategoriesUseCase {
    let repository: EventCategoriesRepository

    func execute() -> Observable<[Chapter10EOCategory]> {
        let repository = repository
        return repository.fetchCategories().flatMap { categories in
            Observable.from(categories.map { repository.fetchEvents(in: $0) })
                .merge(maxConcurrent: 2)
                .scan(categories) { updated, events in
                    updated.map { category in
                        var category = category
                        category.events += events.filter { event in
                            event.categories.contains { $0.id == category.id } && !category.events.contains { $0.id == event.id }
                        }.sorted(by: Chapter10EOEvent.compareDates)
                        return category
                    }
                }
                .startWith(categories)
        }
    }
}

final class EventCategoriesViewModel {
    private let fetchCategories: FetchEventCategoriesUseCase

    init(fetchCategories: FetchEventCategoriesUseCase) { self.fetchCategories = fetchCategories }

    func load() -> Observable<[Chapter10EOCategory]> {
        fetchCategories.execute().observe(on: MainScheduler.instance)
    }
}
