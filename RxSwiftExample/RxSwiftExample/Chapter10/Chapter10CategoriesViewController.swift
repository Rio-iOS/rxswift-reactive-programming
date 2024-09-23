//
//  Chapter10CategoriesViewController.swift
//  RxSwiftExample
//
//  Created by 藤門莉生 on 2024/09/22.
//

import UIKit
import RxSwift
import RxRelay

final class Chapter10CategoriesViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!
    private var activityIndicator: UIActivityIndicatorView!
    
    private let categories = BehaviorRelay<[Chapter10EOCategory]>(value: [])
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        // challenge1
        activityIndicator = UIActivityIndicatorView()
        activityIndicator.color = .black
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        activityIndicator.startAnimating()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        startDownload()
    }
}

private extension Chapter10CategoriesViewController {
    func startDownload() {
//        let eoCategories = Chapter10EONET.categories
//        eoCategories.bind(to: categories)
//            .disposed(by: disposeBag)
//        
//        categories
//            .asObservable()
//            .subscribe(with: self, onNext: { owner, _ in
//                DispatchQueue.main.async {
//                    owner.tableView.reloadData()
//                }
//            })
//            .disposed(by: disposeBag)
       
        // 以下に書き換える
        let eoCategories = Chapter10EONET.categories
        // let downloadedEvents = Chapter10EONET.events(forLast: 360)
        let downloadedEvents = eoCategories
            .flatMap { categories in
                return Observable.from(categories.map({ category in
                    Chapter10EONET.events(forLast: 360, category: category)
                }))
            }
            .merge(maxConcurrent: 2)
        
//        let updatedCategories = Observable.combineLatest(eoCategories, downloadedEvents) { categories, events -> [Chapter10EOCategory] in
//            return categories.map { category in
//                var cat = category
//                cat.events = events.filter({
//                    $0.categories.contains {
//                        $0.id == category.id
//                    }
//                })
//                
//                return cat
//            }
//        }
        
        let updatedCategories = eoCategories.flatMap { categories in
            downloadedEvents.scan(categories) { updated, events in
                return updated.map { category in
                    let eventsForCategory = Chapter10EONET.filteredEvents(events: events, forCategory: category)
                    
                    if !eventsForCategory.isEmpty {
                        var cat = category
                        cat.events = cat.events + eventsForCategory
                        return cat
                    }
                    
                    return category
                }
            }
        }
            .do(onCompleted: { [weak self] in
                // challenge1
                DispatchQueue.main.async {
                    self?.activityIndicator.stopAnimating()
                }
            })
        
        eoCategories
            .concat(updatedCategories)
            .bind(to: categories)
            .disposed(by: disposeBag)
    }
}

extension Chapter10CategoriesViewController: UITableViewDelegate {
    
}

extension Chapter10CategoriesViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath)
        let category = categories.value[indexPath.row]
        var contentcConfiguration = cell.defaultContentConfiguration()
        // contentcConfiguration.text = category.name
        contentcConfiguration.text = "\(category.name) (\(category.events.count)"
        contentcConfiguration.secondaryText = category.description
        cell.accessoryType = (category.events.count > 0) ? .disclosureIndicator : .none
        cell.contentConfiguration = contentcConfiguration
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let category = categories.value[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard !category.events.isEmpty else {
            return
        }
        
        guard let eventsController = UIStoryboard(name: "Chapter10EventsView", bundle: nil).instantiateInitialViewController() as? Chapter10EventsViewController else {
            return
        }
        
        eventsController.title = category.name
        eventsController.events.accept(category.events)
        navigationController?.pushViewController(eventsController, animated: true)
    }
}
