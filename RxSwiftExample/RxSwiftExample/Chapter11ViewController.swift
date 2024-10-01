//
//  Chapter11ViewController.swift
//  RxSwiftExample
//
//  Created by 藤門莉生 on 2024/09/26.
//

import UIKit
import RxSwift
import RxRelay
import RxCocoa

final class Chapter11ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
//        example(of: "✅ replay") {
//            let elementsPerSecond = 1
//            let maxElements = 58
//            let replayedElements = 1
//            let replayDelay: TimeInterval = 3
//            
//            let sourceObservable = Observable<Int>.create { observer in
//                var value = 1
//                let timer = DispatchSource.timer(interval: 1.0 / Double(elementsPerSecond), queue: .main) {
//                    Thread.sleep(forTimeInterval: 0.5)
//                    if value <= maxElements {
//                        observer.onNext(value)
//                        value += 1
//                    }
//                }
//                
//                return Disposables.create {
//                    timer.suspend()
//                }
//            }
//                // .replay(replayedElements)
//                .replayAll()
//            
//            let sourceTimeline = TimelineView<Int>.make()
//            let replayedTimeline = TimelineView<Int>.make()
//            
//            let stack = UIStackView.makeVertical([
//                UILabel.makeTitle("replay"),
//                UILabel.make("Emit \(elementsPerSecond) per second:"),
//                sourceTimeline,
//                UILabel.make("Replay \(replayedElements) after \(replayDelay) sec:"),
//                replayedTimeline
//            ])
//            
//            _ = sourceObservable
//                .subscribe(sourceTimeline)
//            
//            DispatchQueue.main.asyncAfter(deadline: .now() + replayDelay) {
//                _ = sourceObservable
//                    .subscribe(replayedTimeline)
//            }
//            
//            _ = sourceObservable
//                .connect()
//            
//            view.addSubview(stack)
//            
//            NSLayoutConstraint.activate([
//                stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//                stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//            ])
//        }
        
//        example(of: "✅ buffer") {
//            let bufferTimeSpan: RxTimeInterval = .seconds(4)
//            let bufferMaxCount = 2
//            
//            let sourceObservable = PublishSubject<String>()
//            
//            let sourceTimeline = TimelineView<String>.make()
//            let bufferedTimeline = TimelineView<Int>.make()
//            let stack = UIStackView.makeVertical([
//                UILabel.makeTitle("buffer"),
//                UILabel.make("Emitted elements:"),
//                sourceTimeline,
//                UILabel.make("Buffered elements ( at most \(bufferMaxCount) every \(bufferTimeSpan) seconds):"),
//                bufferedTimeline
//            ])
//            
//            _ = sourceObservable.subscribe(sourceTimeline)
//            
//            _ = sourceObservable
//                .buffer(timeSpan: bufferTimeSpan, count: bufferMaxCount, scheduler: MainScheduler.instance)
//                .map(\.count)
//                .subscribe(bufferedTimeline)
//            
//            view.addSubview(stack)
//            
//            NSLayoutConstraint.activate([
//                stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//                stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//            ])
//            
//            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
//                sourceObservable.onNext("😺")
//                sourceObservable.onNext("😺")
//                sourceObservable.onNext("😺")
//            }
//            
//            let elementPerSecond = 0.7
//            let timer = DispatchSource.timer(interval: 1.0 / Double(elementPerSecond), queue: .main) {
//                sourceObservable.onNext(" ")
//            }
//        }
        
//        example(of: "✅ window") {
//            let elementPerSecond = 3
//            let windowTimeSpan: RxTimeInterval = .seconds(4)
//            let windowMaxCount = 10
//            let sourceObservable = PublishSubject<String>()
//            
//            let sourceTimeline = TimelineView<String>.make()
//            let stack = UIStackView.makeVertical([
//                UILabel.makeTitle("window"),
//                UILabel.make("Emitted elements (\(elementPerSecond) per sec.): "),
//                sourceTimeline,
//                UILabel.make("Windowed observable (at most \(windowMaxCount) every \(windowTimeSpan) sec):")
//            ])
//            
//            let timer = DispatchSource.timer(interval: 1.0 / Double(elementPerSecond), queue: .main) {
//                sourceObservable.onNext("😺")
//            }
//            
//            _ = sourceObservable.subscribe(sourceTimeline)
//            
//            _ = sourceObservable
//                .window(timeSpan: windowTimeSpan, count: windowMaxCount, scheduler: MainScheduler.instance)
//                .flatMap({ windowedObservable -> Observable<(TimelineView<Int>, String?)> in
//                    let timeline = TimelineView<Int>.make()
//                    stack.insert(timeline, at: 4)
//                    stack.keep(atMost: 8)
//                    return windowedObservable
//                        .map { value in (timeline, value) }
//                        .concat(Observable.just((timeline, nil)))
//                })
//                .subscribe(onNext: { tuple in
//                    let (timeline, value) = tuple
//                    if let value {
//                        timeline.add(.next(value))
//                    } else {
//                        timeline.add(.completed(true))
//                    }
//                })
//            
//            view.addSubview(stack)
//            
//            NSLayoutConstraint.activate([
//                stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//                stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//            ])
//        }
        
//        example(of: "✅ delay") {
//            let elementsPerSecond = 1
//            let delay: RxTimeInterval = .milliseconds(1500)
//            
//            let sourceObservable = PublishSubject<Int>()
//            
//            let sourceTimeline = TimelineView<Int>.make()
//            let delayedTimeline = TimelineView<Int>.make()
//            
//            let stack = UIStackView.makeVertical([
//                UILabel.makeTitle("delay"),
//                UILabel.make("Emitted elements (\(elementsPerSecond) per sec.):"),
//                sourceTimeline,
//                UILabel.make("Delayed elements (with a \(delay)s delay):"),
//                delayedTimeline
//            ])
//            
//            var current = 1
//            let timer = DispatchSource.timer(interval: 1.0 / Double(elementsPerSecond), queue: .main) {
//                sourceObservable.onNext(current)
//                current += 1
//            }
//            
//            _ = sourceObservable.subscribe(sourceTimeline)
//            
//            _ = sourceObservable
//                .delaySubscription(delay, scheduler: MainScheduler.instance)
//                .subscribe(delayedTimeline)
//            
//            _ = sourceObservable
//                .delay(delay, scheduler: MainScheduler.instance)
//                .subscribe(delayedTimeline)
//        }
        
//        example(of: "✅ intervals") {
//            let elementsPerSecond = 1
//            let maxElements = 58
//            let replayedElements = 1
//            let replayDelay: TimeInterval = 3
//            
//            let sourceObservable = Observable<Int>
//                .interval(.milliseconds(Int(1000.0 / Double(elementsPerSecond))), scheduler: MainScheduler.instance)
//                .replay(replayedElements)
//            
//            let sourceTimeline = TimelineView<Int>.make()
//            let replayedTimeline = TimelineView<Int>.make()
//            
//            let stack = UIStackView.makeVertical([
//                UILabel.makeTitle("replay"),
//                UILabel.make("Emit \(elementsPerSecond) per second:"),
//                sourceTimeline,
//                UILabel.make("Replay \(replayedElements) after \(replayDelay) sec:"),
//                replayedTimeline
//            ])
//            
//            _ = sourceObservable
//                .subscribe(sourceTimeline)
//            
//            DispatchQueue.main.asyncAfter(deadline: .now() + replayDelay) {
//                _ = sourceObservable
//                    .subscribe(replayedTimeline)
//            }
//            
//            _ = sourceObservable
//                .connect()
//            
//            view.addSubview(stack)
//            
//            NSLayoutConstraint.activate([
//                stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//                stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//            ])
//        }
        
        example(of: "✅ timeout") {
            let button = UIButton(type: .system)
            button.setTitle("Press me now!", for: .normal)
            button.sizeToFit()
            
            let tapsTimeline = TimelineView<String>.make()
            
            let stack = UIStackView.makeVertical([
                button,
                UILabel.make("Taps on button above"),
                tapsTimeline
            ])
            
            let _ = button
                .rx
                .tap
                .map { _ in "・" }
                .timeout(.seconds(5), other: Observable.just("X"), scheduler: MainScheduler.instance)
                .subscribe(tapsTimeline)
            
            view.addSubview(stack)
            
            NSLayoutConstraint.activate([
                stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            ])
        }
    }
}
