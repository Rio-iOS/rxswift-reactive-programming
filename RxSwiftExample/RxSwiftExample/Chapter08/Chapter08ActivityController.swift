//
//  Chapter08ActivityController.swift
//  RxSwiftExample
//
//  Created by 藤門莉生 on 2024/09/18.
//

import UIKit
import RxSwift
import RxRelay
import RxCocoa
import Kingfisher

final class Chapter08ActivityController: UITableViewController {
    private let repo = "ReactiveX/RxSwift"

private var repositories: [Chapter08Repository] = []
private let refreshDisposable = SerialDisposable()
private lazy var viewModel = RepositoryActivityViewModel(
    repositoryPath: repo,
    refreshActivity: RefreshRepositoryActivityUseCase(
        service: GitHubRepositoryActivityService(),
        cache: FileRepositoryActivityCache(directory: FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0])
    )
)

deinit { refreshDisposable.dispose() }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = repo

        let refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = UIColor(white: 0.98, alpha: 1.0)
        refreshControl.tintColor = .darkGray
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.refreshControl = refreshControl

        repositories = viewModel.cachedRepositories
        self.refresh()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repositories.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let repository = repositories[indexPath.row]

        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        var contentConfiguration = cell.defaultContentConfiguration()
        contentConfiguration.text = repository.owner?.name
        contentConfiguration.secondaryText = repository.name
        contentConfiguration.image = UIImage(named: "blank-avatar")

        cell.contentConfiguration = contentConfiguration

        guard let avatar = repository.owner?.avatar else { return cell }
        // 画像を非同期で読み込み、読み込み完了後に更新
        KingfisherManager.shared.retrieveImage(with: avatar) { result in
            switch result {
            case .success(let value):
                DispatchQueue.main.async {
                    if let text = (cell.contentConfiguration as? UIListContentConfiguration)?.text,
                       text == repository.owner?.name {
                        var contentConfiguration = cell.contentConfiguration as! UIListContentConfiguration
                        contentConfiguration.image = value.image
                        cell.contentConfiguration = contentConfiguration
                    }
                }
            case .failure(let error):
                print("画像の読み込みに失敗しました: \(error)")
            }
        }

        return cell
    }
}

private extension Chapter08ActivityController {
    @objc func refresh() {
        refreshDisposable.disposable = viewModel.refresh()
            .subscribe(onNext: { [weak self] repositories in
                self?.repositories = repositories
                self?.tableView.reloadData()
                self?.refreshControl?.endRefreshing()
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.refreshControl?.endRefreshing()
                let alert = UIAlertController(title: "Could not refresh", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }, onCompleted: { [weak self] in
                self?.refreshControl?.endRefreshing()
            })
    }
}
