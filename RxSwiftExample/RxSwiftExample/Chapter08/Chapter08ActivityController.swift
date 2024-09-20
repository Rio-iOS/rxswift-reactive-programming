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
    
    private let repositories = BehaviorRelay<[Chapter08Repository]>(value: [])
    private let lastModified = BehaviorRelay<String?>(value: nil)
    private let disposeBag = DisposeBag()
    private let repositoriesFileURL = cachedFileURL("repositories.json")
    private let modifiedFileURL = cachedFileURL("modified.txt")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = repo
        
        let refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = UIColor(white: 0.98, alpha: 1.0)
        refreshControl.tintColor = .darkGray
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.refreshControl = refreshControl
       
        let decoder = JSONDecoder()
        if let  repositoriesData = try? Data(contentsOf: repositoriesFileURL),
           let persistedRepositories = try? decoder.decode([Chapter08Repository].self, from: repositoriesData) {
            print(repositoriesFileURL.absoluteString)
            repositories.accept(persistedRepositories)
        }
        
        if let lastModifiedString = try? String(contentsOf: modifiedFileURL, encoding: .utf8) {
            lastModified.accept(lastModifiedString)
        }
            
        self.refresh()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repositories.value.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let repository = repositories.value[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        var contentConfiguration = cell.defaultContentConfiguration()
        contentConfiguration.text = repository.owner?.name
        contentConfiguration.secondaryText = repository.name
        contentConfiguration.image = UIImage(named: "blank-avatar")
        
        cell.contentConfiguration = contentConfiguration

        guard let avatar = repository.owner?.avatar else {
            fatalError("✅ avatar url is nil")
        }
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
        DispatchQueue.global(qos: .default).async { [weak self] in
            guard let self else {
                return
            }
            self.fetchEvents(repo: self.repo)
        }
    }
    
    func fetchEvents(repo: String) {
        let response = Observable.from([repo])
            .map { urlString -> URL in
                return URL(string: "https://api.github.com/repos/\(urlString)")!
            }
            .map({ [weak self] url -> URLRequest in
                var request = URLRequest(url: url)
                if let modifiedHeader = self?.lastModified.value {
                    request.addValue(modifiedHeader, forHTTPHeaderField: "last-Modified")
                }
                return request
            })
            .flatMap { request -> Observable<(response: HTTPURLResponse, data: Data)> in
                return URLSession.shared.rx.response(request: request)
            }
            .share(replay: 1)
        
        response
            .filter { response, _ in
                return 200..<300 ~= response.statusCode
            }
            .compactMap { _, data -> [Chapter08Repository]? in
                do {
                    let repository = try JSONDecoder().decode(Chapter08Repository.self, from: data)
                    return [repository]
                } catch {
                    return nil
                }
            }
            .subscribe(with: self, onNext: { owner, newEvents in
                owner.processEvents(newEvents)
            })
            .disposed(by: disposeBag)
        
        response
            .filter { response, _ in
                return 200..<400 ~= response.statusCode
            }
            .flatMap { response, _ -> Observable<String> in
                guard let value = response.allHeaderFields["Last-Modified"] as? String else {
                    return Observable.empty()
                }
                return Observable.just(value)
            }
            .subscribe(with: self, onNext: { owner, modifiedHeader in
                owner.lastModified.accept(modifiedHeader)
                try? modifiedHeader.write(to: owner.modifiedFileURL, atomically: true, encoding: .utf8)
            })
            .disposed(by: disposeBag)
    }
    
    func processEvents(_ newRepositories: [Chapter08Repository]) {
        var updatedRepositories = newRepositories + repositories.value
        if updatedRepositories.count > 50 {
            updatedRepositories = [Chapter08Repository](updatedRepositories.prefix(upTo: 50))
        }
        repositories.accept(updatedRepositories)
       
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.refreshControl?.endRefreshing()
        }
        
        let encoder = JSONEncoder()
        if let repositoriesData = try? encoder.encode(updatedRepositories) {
            // ファイルを作成したい、あるいは既存のファイルを上書きしたいファイルのURLを指定
            try? repositoriesData.write(to: repositoriesFileURL, options: .atomicWrite)
        }
    }
    
    static func cachedFileURL(_ fileName: String) -> URL {
        return FileManager.default
            .urls(for: .cachesDirectory, in: .allDomainsMask)
            .first!
            .appendingPathComponent(fileName)
    }
}
