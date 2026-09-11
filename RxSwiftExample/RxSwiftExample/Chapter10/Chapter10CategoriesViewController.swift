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
    private let viewModel = EventCategoriesViewModel(fetchCategories: FetchEventCategoriesUseCase(repository: EONETCategoriesRepository()))
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
        viewModel.load()
            .subscribe(onNext: { [weak self] categories in
                self?.categories.accept(categories)
                self?.tableView.reloadData()
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.activityIndicator.stopAnimating()
                let alert = UIAlertController(title: "Could not load categories", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }, onCompleted: { [weak self] in
                self?.activityIndicator.stopAnimating()
            })
            .disposed(by: disposeBag)
    }
}

extension Chapter10CategoriesViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.value.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath)
        let category = categories.value[indexPath.row]
        var contentConfiguration = cell.defaultContentConfiguration()
        // contentConfiguration.text = category.name
        contentConfiguration.text = "\(category.name) (\(category.events.count))"
        contentConfiguration.secondaryText = category.description
        cell.accessoryType = (category.events.count > 0) ? .disclosureIndicator : .none
        cell.contentConfiguration = contentConfiguration
        return cell
    }

}

extension Chapter10CategoriesViewController: UITableViewDelegate {
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
