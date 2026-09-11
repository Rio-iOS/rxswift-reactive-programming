import RxSwift

/// カテゴリとイベントの取得を、画面や UseCase から切り離す境界。
protocol EventCategoriesRepository {
    func fetchCategories() -> Observable<[Chapter10EOCategory]>
    func fetchEvents(in category: Chapter10EOCategory) -> Observable<[Chapter10EOEvent]>
}

/// EONET のカテゴリと直近 360 日間のイベントを取得します。
///
/// 元の取得処理は通信・デコードのエラーを空配列へ変換するため、取得失敗とデータなしを区別しません。
struct EONETCategoriesRepository: EventCategoriesRepository {
    func fetchCategories() -> Observable<[Chapter10EOCategory]> { Chapter10EONET.categories }
    func fetchEvents(in category: Chapter10EOCategory) -> Observable<[Chapter10EOEvent]> {
        Chapter10EONET.events(forLast: 360, category: category)
    }
}

/// カテゴリ一覧を先に通知し、取得できたイベントを ID の重複を除いて順次追加します。
struct FetchEventCategoriesUseCase {
    let repository: EventCategoriesRepository

    /// 最大 2 カテゴリの取得を並行して購読し、各取得結果を反映した一覧を通知します。
    ///
    /// この上限はカテゴリ単位です。Repository が内部で行う HTTP リクエスト数は制限しません。
    /// Repository が通知したエラーはそのまま伝播し、通知スケジューラも変更しません。
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

/// カテゴリ一覧の更新をメインスレッドで画面へ通知します。
final class EventCategoriesViewModel {
    private let fetchCategories: FetchEventCategoriesUseCase

    init(fetchCategories: FetchEventCategoriesUseCase) { self.fetchCategories = fetchCategories }

    func load() -> Observable<[Chapter10EOCategory]> {
        fetchCategories.execute().observe(on: MainScheduler.instance)
    }
}
