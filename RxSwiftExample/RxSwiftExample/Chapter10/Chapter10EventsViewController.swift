//
//  Chapter10EventsViewController.swift
//  RxSwiftExample
//
//  Created by 藤門莉生 on 2024/09/22.
//

import UIKit
import RxSwift
import RxRelay

final class Chapter10EventsViewController: UIViewController {
    @IBOutlet private weak var daysLabel: UILabel!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var slider: UISlider!
    
    let events = BehaviorRelay<[Chapter10EOEvent]>(value: [])
    let days = BehaviorRelay<Int>(value: 360)
    let filteredEVents = BehaviorRelay<[Chapter10EOEvent]>(value: [])
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        events
            .asObservable()
            .subscribe(with: self, onNext: { owner, _ in
                owner.tableView.reloadData()
            })
            .disposed(by: disposeBag)
        
        Observable.combineLatest(days, events) { days, events -> [Chapter10EOEvent] in
            let maxInterval = TimeInterval(days * 24 * 3600)
            return events.filter { event in
                if let date = event.date {
                    return abs(date.timeIntervalSinceNow) < maxInterval
                }
                return true
            }
        }
        .bind(to: filteredEVents)
        .disposed(by: disposeBag)
        
        filteredEVents
            .asObservable()
            .subscribe(with: self, onNext: { owner, _ in
                DispatchQueue.main.async {
                    owner.tableView.reloadData()
                }
            })
            .disposed(by: disposeBag)
        
        days.asObservable()
            .subscribe(with: self, onNext: { owner, days in
                owner.daysLabel.text = "Last \(days) days"
            })
            .disposed(by: disposeBag)
    }
    @IBAction func sliderAction(_ slider: UISlider) {
        days.accept(Int(slider.value))
    }
}

extension Chapter10EventsViewController: UITableViewDelegate {
    
}

extension Chapter10EventsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // return events.value.count
        return filteredEVents.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell", for: indexPath) as! Chapter10EventCell
        let event = events.value[indexPath.row]
        cell.configure(event: event)
        return cell
    }
}
