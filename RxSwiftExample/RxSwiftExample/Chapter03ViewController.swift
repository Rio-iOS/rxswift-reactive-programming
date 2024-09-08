//
//  Chapter03ViewController.swift
//  RxSwiftExample
//
//  Created by 藤門莉生 on 2024/09/05.
//

import Foundation
import UIKit
import RxSwift
import RxRelay

class Chapter03ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
       
        view.backgroundColor = .systemBackground
        
        example(of: "⭐️ PublishSuject") {
            let subject = PublishSubject<String>()
            
            subject.on(.next("Is anyone listening?"))
            
            let subscriptionOne = subject.subscribe(onNext: { string in
                print(string)
            })
            
            subject.on(.next("1"))
            subject.onNext("2")
            
            let subscriptionTwo = subject.subscribe { event in
                print("2)", event.element ?? event)
            }
            
            subject.onNext("3")
            
            subscriptionOne.dispose()
            subject.onNext("4")
            
            subject.onCompleted()
            
            subject.onNext("5")
            
            subscriptionTwo.dispose()
            
            let disposeBag = DisposeBag()
            
            subject.subscribe {
                print("3)", $0.element ?? $0)
            }
            .disposed(by: disposeBag)
            
            subject.onNext("?")
        }
        
        enum MyError: Error {
            case anError
        }
        
        example(of: "BehaviorSubject") {
            let subject = BehaviorSubject(value: "Initial value")
            let disposeBag = DisposeBag()
           
            subject.onNext("X")
            
            subject
                .subscribe {
                    self.printEvent(label: "1)", event: $0)
                }
                .disposed(by: disposeBag)
            
            subject.onError(MyError.anError)
            
            subject
                .subscribe {
                    self.printEvent(label: "2)", event: $0)
                }
                .disposed(by: disposeBag)
        }
        
        example(of: "ReplaySubjet") {
            let subject = ReplaySubject<String>.create(bufferSize: 2)
            let disposeBag = DisposeBag()
            
            subject.onNext("1")
            subject.onNext("2")
            subject.onNext("3")
            
            subject
                .subscribe {
                    self.printEvent(label: "1)", event: $0)
                }
                .disposed(by: disposeBag)
            
            subject
                .subscribe {
                    self.printEvent(label: "2)", event: $0)
                }
                .disposed(by: disposeBag)
            
            subject.onNext("4")
            
            subject.onError(MyError.anError)
            
            subject.dispose()
            
             subject
                .subscribe {
                    self.printEvent(label: "3)", event: $0)
                }
                .disposed(by: disposeBag)
        }
        
        example(of: "PublishRelay") {
            let relay = PublishRelay<String>()
            let disposeBag = DisposeBag()
            
            relay.accept("Knock knock, anyone home?")
            
            relay
                .subscribe(
                    onNext: {
                        print($0)
                    }
                )
                .disposed(by: disposeBag)
            
            relay.accept("1")
           
            // compile error
            // relay.accept(MyError.anError)
            // relay.onCompleted()
        }
        
        example(of: "BehaviorRelay") {
            let relay = BehaviorRelay(value: "Initial Value")
            let disposeBag = DisposeBag()
            
            relay.accept("New Initial Value")
            
            relay
                .subscribe {
                    self.printEvent(label: "1)", event: $0)
                }
                .disposed(by: disposeBag)
            
            relay.accept("1")
            
            relay
                .subscribe {
                    self.printEvent(label: "2)", event: $0)
                }
                .disposed(by: disposeBag)
            
            relay.accept("2")
            
            print(relay.value)
        }
    }
}

private extension Chapter03ViewController {
    func printEvent<T: CustomStringConvertible>(label: String, event: Event<T>) {
        print(label, (event.element ?? event.error) ?? event)
    }
}
